.segment "RODATA"
palettes:
; https://www.nesdev.org/wiki/PPU_palettes
  ; background palettes
  .byte $0f, $2a, $16, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f

  ; sprite palettes
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f
  .byte $0f, $0f, $0f, $0f

.ifdef MMC2
initial_oam:
  ; tile id $fd at (0, 0), behind background
  .byte 0, $fd, %00100000, 0
.endif

.ifdef NROM
.segment "CHARS"
.else
.segment "CHR06"
.endif

  .byte %00000000
  .byte %00000110
  .byte %00001100
  .byte %11011000
  .byte %01110000
  .byte %00100000
  .byte %00000000
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte %00000000
  .byte %11000110
  .byte %01101100
  .byte %00111000
  .byte %01101100
  .byte %11000110
  .byte %00000000
  .byte %00000000