
; boot.asm - loads main.bin into 0000:1000 and jumps to it
; build layout on disk:
;  - sector 0: boot sector (this file)
;  - sectors 1.. : main.bin
;
; Assumptions:
;  - target is a floppy image with BIOS CHS working in QEMU
;  - main.bin is small enough to fit in loaded sectors

org 0x7C00
bits 16

start:
    cli

    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Print loading message
    mov si, loading_msg
    call print

    ; Reset disk system
    mov ah, 0x00
    mov dl, 0x00            ; floppy drive 0 (QEMU -fda)
    int 0x13
    jc disk_error

    ; Load main.bin sectors starting from sector 2 (CHS):
    ; - BIOS boot sector already used sector 1 (LBA 0) at 0x7C00.
    ; - We start at sector 2 in CHS to avoid overwriting the boot sector area.
    ;
    ; Read parameters (CHS):
    ;   AH=02 read sectors
    ;   AL=count
    ;   CH=cylinder
    ;   CL=sector
    ;   DH=head
    ;   DL=drive
    ;   ES:BX=destination
    ;
    ; Destination: 0x1000:0x0000 -> physical 0x10000
    mov bx, 0x0000
    mov ax, 0x1000
    mov es, ax

    mov ah, 0x02
    mov al, 100            ; <-- adjust if main.bin is larger than 10 sectors (5120 bytes)
    mov ch, 0
    mov cl, 2             ; sector 2
    mov dh, 0
    mov dl, 0x00
    int 0x13
    jc disk_error

    ; Print success
    mov si, ok_msg
    call print

    ; Jump to loaded program
    jmp 0x1000:0x0000

disk_error:
    mov si, error_msg
    call print
    jmp $

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp print
.done:
    ret

loading_msg db 'Loading...', 0
ok_msg      db 'OK!', 0
error_msg   db 'Error!', 0

times 510-($-$$) db 0
dw 0xAA55
