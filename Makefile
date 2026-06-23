ASM=nasm

ASMFLAGS = -f bin
SRC = src
BUILD = build

all: $(BUILD)/final.bin

$(BUILD)/boot.bin: $(SRC)/boot.asm
	mkdir -p $(BUILD)
	$(ASM) $(ASMFLAGS) $< -o $@
	@echo "Boot.bin: $$(stat -c%s $@) bytes"

$(BUILD)/main.bin: $(SRC)/main.asm
	mkdir -p $(BUILD)
	$(ASM) $(ASMFLAGS) $< -o $@
	@echo "Main.bin: $$(stat -c%s $@) bytes"

$(BUILD)/final.bin: $(BUILD)/boot.bin $(BUILD)/main.bin
	cat $^ > $@
	@echo "Final.bin: $$(stat -c%s $@) bytes"
	@echo "Build complete!"

run: all
	qemu-system-x86_64 -fda $(BUILD)/final.bin

clean:
	rm -rf $(BUILD)

.PHONY: all run clean