#!/bin/bash
echo "=== File Sizes ==="
ls -lh build/*.bin
echo ""
echo "=== Detailed Sizes ==="
BOOT_SIZE=$(stat -c%s build/boot.bin)
MAIN_SIZE=$(stat -c%s build/main.bin)
FINAL_SIZE=$(stat -c%s build/final.bin)
echo "Boot.bin:  $BOOT_SIZE bytes"
echo "Main.bin:  $MAIN_SIZE bytes"
echo "Final.bin: $FINAL_SIZE bytes"
echo ""
SECTORS=$(( ($MAIN_SIZE + 511) / 512 ))
echo "Main.bin needs $SECTORS sector(s)"
if [ $SECTORS -gt 1 ]; then
    echo "⚠️  Make sure boot.asm has: mov al, $SECTORS"
fi