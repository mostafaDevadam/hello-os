ASM=nasm
SRC_DIR=src
BUILD_DIR=build

# Das Hauptziel
all: $(BUILD_DIR)/os_disk.img

$(BUILD_DIR)/os_disk.img: $(BUILD_DIR)/main.bin $(BUILD_DIR)/shell.bin
	@mkdir -p $(BUILD_DIR)
	# Clear out any old image
	rm -f $(BUILD_DIR)/os_disk.img
	# Create a blank 1.44MB Floppy Image filled with zeros
	dd if=/dev/zero of=$(BUILD_DIR)/os_disk.img bs=1024 count=1440
	# Write the Bootloader (main.bin) into the absolute 1st sector (offset 0)
	dd if=$(BUILD_DIR)/main.bin of=$(BUILD_DIR)/os_disk.img conv=notrunc bs=512 count=1 seek=0
	# Write the Shell (shell.bin) safely starting precisely at the 2nd sector (offset 512)
	dd if=$(BUILD_DIR)/shell.bin of=$(BUILD_DIR)/os_disk.img conv=notrunc bs=512 seek=1

$(BUILD_DIR)/main.bin: $(SRC_DIR)/main.asm
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)/main.bin

$(BUILD_DIR)/shell.bin: $(SRC_DIR)/shell.asm
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/shell.asm -f bin -o $(BUILD_DIR)/shell.bin

clean:
	rm -rf $(BUILD_DIR)