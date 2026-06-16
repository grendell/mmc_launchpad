# Enhancement Chips: How Nintendo Cartridges Leveled Up
* Presented at Sac Gamers Expo 2025
* Presented at SoCal Gaming Expo 2026

![Preview Screenshot](launchpad.gif)
## Building
* Simply run `make`
    * Requires make, ca65, and ld65 to be included in your PATH.
* Alternatively, run `rebuild.bat` on Windows or `rebuild.sh` on MacOS and Linux.
    * Requires ca65 and ld65 to be included in your PATH.
## File Summary
* `launchpad.s`
    * Complete source code in 6502 assembly.
* `data.inc`
    * Complete read-only data including colors, initial sprite state, and CHR-ROM tiles.
* `system.inc`
    * Canonical names for NES registers and sprite OAM data layout.
* `*.cfg`
    * Linker configurations for a basic NES [NROM](https://www.nesdev.org/wiki/NROM), [MMC1](https://www.nesdev.org/wiki/MMC1), [MMC2](https://www.nesdev.org/wiki/MMC2), [MMC3](https://www.nesdev.org/wiki/MMC3), and [MMC5](https://www.nesdev.org/wiki/MMC5) rom file.
* `*.nes`
    * Prebuilt rom files.
