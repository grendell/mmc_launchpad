.segment "HEADER"
; https://www.nesdev.org/wiki/INES
  .byte $4e, $45, $53, $1a ; iNES header identifier
  .byte $02                ; 2x 16KB PRG code

; different sizes so we can always have 16 CHR-ROM banks, regardless of mapper
.if .defined(NROM)
  .byte $01                ; 1x  8KB CHR data
.elseif .defined(MMC3)
  .byte $02                ; 2x  8KB CHR data
.elseif .defined(MMC5)
  .byte $04                ; 4x  8KB CHR data
.else
  .byte $08                ; 8x  8KB CHR data
.endif

; https://www.nesdev.org/wiki/Mapper#iNES_1.0_mapper_grid
.if .defined(NROM)
  .byte $01                ; mapper 0 and vertical mirroring
  .byte $00                ; mapper 0
.elseif .defined(MMC1)
  .byte $10                ; mapper 1 and mapper-controlled mirroring
  .byte $00                ; mapper 1
.elseif .defined(MMC2)
  .byte $90                ; mapper 9 and mapper-controlled mirroring
  .byte $00                ; mapper 9
.elseif .defined(MMC3)
  .byte $40                ; mapper 4 and mapper-controlled mirroring
  .byte $00                ; mapper 4
.elseif .defined(MMC5)
  .byte $50                ; mapper 5 and mapper-controlled mirroring
  .byte $00                ; mapper 5
.endif

; memory map
;   $00 -   $ff: zero page (fast-access variables)
; $0100 - $01ff: stack (program flow)
; $0200 - $02ff: OAM shadow (next sprite update, only used on MMC2)
; $0300 - $07ff: unused

; banked CHR-ROM map
; $0000 - $0400: checkmark, strike, and blank glyphs
; $0400 - $1fff: potentially uninitialized, mapper dependent!

; banked PRG-ROM map
; $8000 - $dfff: potentially uninitialized, mapper dependent!
; $e000 - $efff: fixed position of code segment
; $f000 - $fff9: fixed position of data segment
; $fffa - $ffff: fixed position of vector segment

.segment "VECTORS"
  .addr nmi, reset, 0

.segment "ZEROPAGE"
ppu_ctrl: .res 1
scroll_x: .res 1
waiting_for_nmi: .res 1

.include "system.inc"
.include "data.inc"

.segment "CODE"
OAM_SHADOW = $0200
OAM_SIZE = 4

CHECKMARK = 0
STRIKE = 1

.proc reset
  ; https://www.nesdev.org/wiki/Init_code
  sei                    ; ignore IRQs
  cld                    ; disable decimal mode
  ldx #$40
  stx APU_FRAME_COUNTER  ; disable APU frame IRQ
  ldx #$ff
  txs                    ; Set up stack
  inx                    ; now X = 0
  stx PPU_CTRL           ; disable NMI
  stx PPU_MASK           ; disable rendering
  stx DMC_FREQ           ; disable DMC IRQs

  ; clear vblank flag
  bit PPU_STATUS

.if .defined(MMC1)
  ; https://www.nesdev.org/wiki/MMC1

  ; reset mapper state
  ;      xxxxxxx - unused
  ;     1        - reset command
  lda #%10000000
  sta $8000

  ;           10 - vertical mirroring
  ;         11   - PRG-ROM switchable at $8000, fixed at $c000
  ;        1     - 4KB CHR-ROM banks
  ;     xxx      - unused
  lda #%00011110

  ldx #5
: sta $8000
  lsr
  dex
  bne :-

  ; switch CHR-ROM $0000 to bank 6 (offset: 6 * 4KB = $6000)
  ;        00110 - bank 6
  ;     xxx      - unused
  lda #%00000110

  ldx #5
: sta $a000
  lsr
  dex
  bne :-
.elseif .defined(MMC2)
  ; https://www.nesdev.org/wiki/MMC2

  ; set up vertical mirroring
  ;            0 - vertical mirroring
  ;     xxxxxxx  - unused
  lda #%00000000
  sta $f000

  ; switch CHR-ROM $0000 to bank 6 after tile $FD is encountered
  ;        00110 - bank 6 (offset: 6 * 4KB = $6000)
  ;     xxx      - unused
  lda #%00000110
  sta $b000
.elseif .defined(MMC3)
  ; https://www.nesdev.org/wiki/MMC3

  ; set up vertical mirroring
  ;            0 - vertical mirroring
  ;     xxxxxxx  - unused
  lda #%00000000
  sta $a000

  ; switch CHR-ROM $0000 to bank 6
  ;          000 - update 2KB CHR-ROM bank at $0000
  ;       xxx    - unused
  ;      1       - PRG-ROM switchable at $8000, fixed at $c000
  ;     0        - 2x 2KB CHR-ROM banks at $0000
  lda #%01000000
  sta $8000

  ;     00000110 - bank 6 (offset: 6 * 1KB = $1800)
  lda #%00000110
  sta $8001
.elseif .defined(MMC5)
  ; https://www.nesdev.org/wiki/MMC5

  ; set up 2KB CHR-ROM banks
  ;           10 - 2KB CHR-ROM banks
  ;     xxxxxx   - unused
  lda #%00000010
  sta $5101

  ; disable internal extended RAM usage for nametable
  ;           11 - $5c00 - $5fff read only,
  ;                $2000 - $2fff not available for nametable or attributes
  ;     xxxxxx   - unused
  lda #%00000011
  sta $5104

  ; set up vertical mirroring
  ;           00 - nametable at $2000 mapped to page 0
  ;         01   - nametable at $2400 mapped to page 1
  ;       00     - nametable at $2800 mapped to page 0
  ;     01       - nametable at $2c00 mapped to page 1
  lda #%01000100
  sta $5105

  ; switch CHR-ROM $0000 to bank 6
  ;     00000110 - bank 6 (offset: 6 * 2KB = $3000)
  lda #%00000110
  sta $5121
.endif

  ; wait for first vblank
: bit PPU_STATUS
  bpl :-

  ; initialize cpu variables
  lda #0
  sta scroll_x
  sta waiting_for_nmi

  ; wait for second vblank
: bit PPU_STATUS
  bpl :-

  ; initialize ppu
  jsr init_palettes
  jsr init_nametables

.ifdef MMC2
  ; https://www.nesdev.org/wiki/MMC2#CHR_banking

  ; use a sprite to trigger the CHR-ROM bank swap
  jsr init_sprites
.endif

  ; enable NMI and select pattern tables
  ;           00 - base nametable
  ;          0   - vram update direction
  ;         0    - sprite pattern table
  ;        0     - background pattern table
  ;       0      - 8x8 sprite size
  ;      0       - default EXT pin behavior - never enable on NES!
  ;     1        - enable vblank NMI
  lda #%10000000
  sta ppu_ctrl
  sta PPU_CTRL

game_loop:
  ; wait for frame to be completed
  inc waiting_for_nmi
: lda waiting_for_nmi
  bne :-

  ; increase horizontal scroll
  inc scroll_x

  ; if we didn't scroll into the other nametable, loop now
  bne game_loop

  ; toggle between starting nametables
  lda ppu_ctrl
  eor #%00000001
  sta ppu_ctrl

  jmp game_loop
.endproc

.proc nmi
  ; retain previous value of a on the stack
  pha

  ; clear vblank flag
  bit PPU_STATUS

.ifdef MMC2
  ; update sprite OAM via DMA
  lda #>OAM_SHADOW
  sta OAM_DMA

  ; show backgrounds, including leftmost 8 pixels
  ;            0 - disable grayscale rendering
  ;           1  - show background in left-most 8 pixels on screen
  ;          1   - show sprites in left-most 8 pixels on screen
  ;         1    - draw backgrounds
  ;        1     - draw sprites
  ;       0      - disable red emphasis
  ;      0       - disable green emphasis
  ;     0        - disable blue emphasis
  lda #%00011110
.else
  ; show backgrounds, including leftmost 8 pixels
  ;            0 - disable grayscale rendering
  ;           1  - show background in left-most 8 pixels on screen
  ;          0   - hide sprites in left-most 8 pixels on screen
  ;         1    - draw backgrounds
  ;        0     - don't draw sprites
  ;       0      - disable red emphasis
  ;      0       - disable green emphasis
  ;     0        - disable blue emphasis
  lda #%00001010
.endif

  sta PPU_MASK

  ; update background scroll position
  lda scroll_x
  sta PPU_SCROLL
  lda #0
  sta PPU_SCROLL

  lda ppu_ctrl
  sta PPU_CTRL

  ; allow game loop to continue after interrupt
  lda #0
  sta waiting_for_nmi

  ; restore previous value of a before interrupt
  pla
  rti
.endproc

.proc init_palettes
  ; set ppu address to palette entries ($3f00)
  lda #$3f
  sta PPU_ADDR
  lda #0
  sta PPU_ADDR

  ; loop through each palette entry, 32 total
  ldx #0
: lda palettes, x
  sta PPU_DATA
  inx
  cpx #32
  bne :-

  rts
.endproc

.proc init_nametables
  ; set ppu address to first nametable ($2000)
  lda #$20
  sta PPU_ADDR
  lda #0
  sta PPU_ADDR

  ldx #32
  ldy #30

  ; fill first nametable with checkmarks
  lda #CHECKMARK
: sta PPU_DATA

  dex
  bne :-

  ldx #32
  dey
  bne :-

  ldx #64

  ; fill first attribute table with zeroes
  lda #0
: sta PPU_DATA

  dex
  bne :-

  ldx #32
  ldy #30

  ; fill second nametable and attributes with strikes
  lda #STRIKE
: sta PPU_DATA

  dex
  bne :-

  ldx #32
  dey
  bne :-

  ldx #64

  ; fill second attribute table with zeroes
  lda #0
: sta PPU_DATA

  dex
  bne :-

  rts
.endproc

.ifdef MMC2
.proc init_sprites
  ; set initial contents of the OAM shadow
  ; this copy will be sent to the PPU during NMI
  ldx #0
: lda initial_oam, x
  sta OAM_SHADOW, x

  inx
  cpx #OAM_SIZE
  bne :-

  ; move the rest of the buffer off-screen
  lda #$ff
: sta OAM_SHADOW, x
  inx
  bne :-

  rts
.endproc
.endif