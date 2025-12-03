echo on

if exist obj rd /s /q obj
if exist *.nes del /s /q /f *.nes
mkdir obj
ca65 -DNROM launchpad.s -o obj\nrom.o
ld65 -C nrom.cfg obj\nrom.o -o nrom.nes
ca65 -DMMC1 launchpad.s -o obj\mmc1.o
ld65 -C mmc1.cfg obj\mmc1.o -o mmc1.nes
ca65 -DMMC2 launchpad.s -o obj\mmc2.o
ld65 -C mmc2.cfg obj\mmc2.o -o mmc2.nes
ca65 -DMMC3 launchpad.s -o obj\mmc3.o
ld65 -C mmc3.cfg obj\mmc3.o -o mmc3.nes
ca65 -DMMC5 launchpad.s -o obj\mmc5.o
ld65 -C mmc5.cfg obj\mmc5.o -o mmc5.nes