ASM=nasm

SRC_DIR=src
BUILD_DIR=build

all: $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/shell_floppy.img



$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/main.bin
	cp $(BUILD_DIR)/main.bin $(BUILD_DIR)/main_floppy.img
	truncate -s 1440k $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main.bin: $(SRC_DIR)/main.asm
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)/main.bin



$(BUILD_DIR)/shell_floppy.img: $(BUILD_DIR)/shell.bin
	cp $(BUILD_DIR)/shell.bin $(BUILD_DIR)/shell_floppy.img
	truncate -s 1440k $(BUILD_DIR)/shell_floppy.img

$(BUILD_DIR)/shell.bin: $(SRC_DIR)/shell.asm
	$(ASM) $(SRC_DIR)/shell.asm -f bin -o $(BUILD_DIR)/shell.bin