org 0x7C00
bits 16

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Reset disk drive
    mov ah, 0
    mov dl, 0x00        
    int 0x13

    ; Load Shell from Sector 2 into memory 0x1000:0x0000
    mov ax, 0x1000      
    mov es, ax
    xor bx, bx          

    mov ah, 0x02        ; Read sectors
    mov al, 4           ; Read 4 sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Sector 2
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Floppy drive 0
    int 0x13

    ; Jump directly to the loaded shell program
    jmp 0x1000:0000

times 510-($-$$) db 0
dw 0AA55h