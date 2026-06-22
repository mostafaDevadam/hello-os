ASM=nasm
SRC_DIR=src
BUILD_DIR=build

# The master output is now a single combined OS floppy disk image
all: $(BUILD_DIR)/os_disk.img

$(BUILD_DIR)/os_disk.img: $(BUILD_DIR)/main.bin $(BUILD_DIR)/shell.bin
	# Combine bootloader and shell together
	cat $(BUILD_DIR)/main.bin $(BUILD_DIR)/shell.bin > $(BUILD_DIR)/os_disk.img
	# Pad the final disk image to standard 1.44MB floppy size
	truncate -s 1440k $(BUILD_DIR)/os_disk.img

$(BUILD_DIR)/main.bin: $(SRC_DIR)/main.asm
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)/main.bin

$(BUILD_DIR)/shell.bin: $(SRC_DIR)/shell.asm
	$(ASM) $(SRC_DIR)/shell.asm -f bin -o $(BUILD_DIR)/shell.bin

clean:
	rm -rf $(BUILD_DIR)/*.bin $(BUILD_DIR)/*.img