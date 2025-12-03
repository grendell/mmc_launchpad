AS = ca65
LD = ld65
OBJ = obj

PROJECT = launchpad
DEPS = launchpad.s data.inc system.inc

.PHONY: all
all: nrom.nes mmc1.nes mmc2.nes mmc3.nes mmc5.nes

$(OBJ):
ifeq ($(OS), Windows_NT)
	mkdir $(OBJ)
else
	mkdir -p $(OBJ)
endif

nrom.nes: $(OBJ) $(OBJ)/nrom.o nrom.cfg
	$(LD) -C nrom.cfg $(OBJ)/nrom.o -o nrom.nes

$(OBJ)/nrom.o: $(DEPS)
	$(AS) -DNROM launchpad.s -o $(OBJ)/nrom.o

mmc1.nes: $(OBJ) $(OBJ)/mmc1.o mmc1.cfg
	$(LD) -C mmc1.cfg $(OBJ)/mmc1.o -o mmc1.nes

$(OBJ)/mmc1.o: $(DEPS)
	$(AS) -DMMC1 launchpad.s -o $(OBJ)/mmc1.o

mmc2.nes: $(OBJ) $(OBJ)/mmc2.o mmc2.cfg
	$(LD) -C mmc2.cfg $(OBJ)/mmc2.o -o mmc2.nes

$(OBJ)/mmc2.o: $(DEPS)
	$(AS) -DMMC2 launchpad.s -o $(OBJ)/mmc2.o

mmc3.nes: $(OBJ) $(OBJ)/mmc3.o mmc3.cfg
	$(LD) -C mmc3.cfg $(OBJ)/mmc3.o -o mmc3.nes

$(OBJ)/mmc3.o: $(DEPS)
	$(AS) -DMMC3 launchpad.s -o $(OBJ)/mmc3.o

mmc5.nes: $(OBJ) $(OBJ)/mmc5.o mmc5.cfg
	$(LD) -C mmc5.cfg $(OBJ)/mmc5.o -o mmc5.nes

$(OBJ)/mmc5.o: $(DEPS)
	$(AS) -DMMC5 launchpad.s -o $(OBJ)/mmc5.o

.PHONY: clean
clean:
ifeq ($(OS), Windows_NT)
	if exist $(OBJ) rd /s /q $(OBJ)
	if exist $(PROJECT).nes del /s /q /f *.nes
else
	rm -fr $(OBJ) *.nes
endif