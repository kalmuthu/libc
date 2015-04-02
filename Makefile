include .knightos/variables.make

AS=scas

OBJECTS=$(patsubst src/%.c,$(OUT)%.o,$(wildcard src/*.c))
OBJECTS+=$(patsubst src/gpl/%.c,$(OUT)gpl/%.o,$(wildcard src/gpl/*.c))
OBJECTS+=$(patsubst src/%.asm,$(OUT)%.o,$(wildcard src/*.asm))
OBJECTS+=$(patsubst src/gpl/%.asm,$(OUT)gpl/%.o,$(wildcard src/gpl/*.asm))
HEADERS=$(patsubst include/%.h,$(INC)%.h,$(wildcard include/*.h))
HEADERS=$(patsubst include/sys/%.h,$(INC)sys/%.h,$(wildcard include/sys/*.h))

ALL_TARGETS:=$(SLIB)c $(HEADERS)

$(SLIB)c: dependencies $(OBJECTS)
	mkdir -p $(SLIB)
	scas -c $(OBJECTS) -o $(SLIB)c

$(INC)%.h: include/%.h
	mkdir -p $(INC)
	mkdir -p $(INC)sys/
	cp $< $@

#include .knightos/sdk.make
.PHONY: all run clean help info package

$(OUT)%.o: src/%.asm
	mkdir -p $(OUT)gpl/
	$(AS) -c -I"$(INCLUDE)" -o $@ $<

$(OUT)gpl/%.o: src/gpl/%.asm
	mkdir -p $(OUT)gpl/
	$(AS) -c -I"$(INCLUDE)" -o $@ $<

$(OUT)gpl/%.o: $(OUT)gpl/%.asm
	mkdir -p $(OUT)gpl/
	$(AS) -c -I"$(INCLUDE)" -o $@ $<

$(OUT)%.o: $(OUT)gpl/%.asm
	mkdir -p $(OUT)gpl/
	$(AS) -c -I"$(INCLUDE)" -o $@ $<

$(OUT)%.o: $(OUT)%.asm
	mkdir -p $(OUT)gpl/
	$(AS) -c -I"$(INCLUDE)" -o $@ $<

$(OUT)%.asm: src/%.c $(HEADERS)
	mkdir -p $(OUT)gpl/
	$(CC) -I.knightos/include/ -I./ -I./include/ -S --std-c99 $< -o $@

all: $(ALL_TARGETS)
	@rm -rf $(SDK)root
	@mkdir -p $(SDK)root
	@cp -r $(SDK)pkgroot/* $(SDK)root 2> /dev/null || true
	@rm -rf $(SDK)root/include
	@cp -r $(ROOT)* $(SDK)root/
	@cp $(SDK)kernel.rom $(SDK)debug.rom
	@mkdir -p $(SDK)root/etc
	@echo "$(INIT)" > $(SDK)root/etc/inittab
	@$(GENKFS) $(SDK)debug.rom $(SDK)root/ > /dev/null

run: all
	$(EMU) $(SDK)debug.rom

debug: all
	$(DEBUGGER) $(SDK)debug.rom

clean:
	@rm -rf $(OUT)
	@rm -rf $(SDK)root
	@rm -rf $(SDK)debug.rom
	@rm -rf libc-$(VERSION).pkg

package: all
	kpack libc-$(VERSION).pkg $(ROOT)

install: package
	kpack -e -s libc-$(VERSION).pkg $(PREFIX)
	
help:
	@echo "KnightOS Makefile for libc"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Common targets:"
	@echo "	all: 		Builds the entire project"
	@echo "	run: 		Builds and runs the project in the emulator"

include $(SDK)packages.make
