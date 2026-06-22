org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:
    jmp main

; =============================================================================
; SERVICE FUNCTIONS
; =============================================================================

puts:
    push si
    push ax
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    mov bh, 0
    int 0x10
    jmp .loop
.done:
    pop ax
    pop si 
    ret

getc:
    mov ah, 0x00
    int 0x16        ; AH = Scan-Code, AL = ASCII
    ret

putc:
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    ret

clear_screen:
    mov ax, 0x0003  ; Reset video mode to standard 80x25 text mode
    int 0x10
    ret

strcmp_insensitive:
    push si
    push di
.loop:
    mov al, [si]
    mov bl, [di]
    
    ; Lowercase AL
    cmp al, 'A'
    jl .lower_bl
    cmp al, 'Z'
    jg .lower_bl
    add al, 32
.lower_bl:
    ; Lowercase BL
    cmp bl, 'A'
    jl .compare
    cmp bl, 'Z'
    jg .compare
    add bl, 32
.compare:
    cmp al, bl
    jne .not_equal
    cmp al, 0        
    je .equal
    inc si
    inc di
    jmp .loop
.not_equal:
    mov al, 1
    or al, al        ; Clear ZF
    jmp .done
.equal:
    xor ax, ax       ; Set ZF
.done:
    pop di
    pop si
    ret

; =============================================================================
; MAIN SHELL LOGIC
; =============================================================================

main:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    call clear_screen
    mov si, msg_welcome
    call puts

shell_loop:
    mov si, msg_prompt
    call puts
    mov di, cmd_buffer

input_loop:
    call getc       

    ; === OPTIMIZED GERMAN KEYBOARD TRANSLATION LAYER ===
    push ds
    push bx
    mov bx, 0x40
    mov ds, bx
    mov bl, [0x17]  ; Get Shift status
    and bl, 0x03    
    pop bx
    pop ds          ; BL = 0 if Shift is OFF, >0 if Shift is ON

    cmp ah, 0x15    ; Physical 'Y' -> 'Z'
    je .map_z
    cmp ah, 0x2C    ; Physical 'Z' -> 'Y'
    je .map_y
    cmp ah, 0x0C    ; Physical '-' -> 'ß' / '?'
    je .map_sz
    cmp ah, 0x1A    ; Physical '[' -> 'Ü'
    je .map_ue
    cmp ah, 0x1B    ; Physical ']' -> '+' / '*'
    je .map_plus
    cmp ah, 0x27    ; Physical ';' -> 'Ö'
    je .map_oe
    cmp ah, 0x28    ; Physical "'" -> 'Ä'
    je .map_ae
    cmp ah, 0x2B    ; Physical '\' -> '#' / '\''
    je .map_hash
    cmp ah, 0x35    ; Physical '/' -> '-' / '_'
    je .map_minus
    jmp .process_key

.map_z:
    mov al, 'z'
    and bl, bl
    jz .process_key
    mov al, 'Z'
    jmp .process_key
.map_y:
    mov al, 'y'
    and bl, bl
    jz .process_key
    mov al, 'Y'
    jmp .process_key
.map_sz:
    mov al, 0xE1    ; 'ß'
    and bl, bl
    jz .process_key
    mov al, '?'
    jmp .process_key
.map_ue:
    mov al, 0x9A    ; 'ü'
    jmp .process_key
.map_plus:
    mov al, '+'
    and bl, bl
    jz .process_key
    mov al, '*'
    jmp .process_key
.map_oe:
    mov al, 0x94    ; 'ö'
    jmp .process_key
.map_ae:
    mov al, 0x84    ; 'ä'
    jmp .process_key
.map_hash:
    mov al, '#'
    and bl, bl
    jz .process_key
    mov al, '"'
    jmp .process_key
.map_minus:
    mov al, '-'
    and bl, bl
    jz .process_key
    mov al, '_'

.process_key:
    cmp al, 0x0D    ; Enter
    je execute_command
    cmp al, 0x08    ; Backspace
    je handle_backspace

    ; Buffer limit check
    mov cx, di
    sub cx, cmd_buffer
    cmp cx, 15
    jge input_loop   

    call putc
    stosb           
    jmp input_loop

handle_backspace:
    cmp di, cmd_buffer
    je input_loop
    dec di          
    mov al, 0x08    
    call putc
    mov al, ' '     
    call putc
    mov al, 0x08    
    call putc
    jmp input_loop

execute_command:
    xor al, al
    stosb

    mov si, msg_newline
    call puts

    mov si, cmd_buffer
    mov al, [si]
    or al, al
    jz clear_and_repeat 

    mov di, cmd_help
    call strcmp_insensitive
    je do_help

    mov si, cmd_buffer
    mov di, cmd_cls
    call strcmp_insensitive
    je do_cls

    mov si, cmd_buffer
    mov di, cmd_reboot
    call strcmp_insensitive
    je do_reboot

    mov si, msg_unknown
    call puts
    jmp clear_and_repeat

do_help:
    mov si, msg_help_text
    call puts
    jmp clear_and_repeat

do_cls:
    call clear_screen
    jmp clear_and_repeat

do_reboot:
    jmp 0xFFFF:0000  

clear_and_repeat:
    mov di, cmd_buffer
    mov cx, 16
    xor al, al
    rep stosb        
    jmp shell_loop

; =============================================================================
; DATA SEGMENT
; =============================================================================

msg_welcome:   db 'SimpleOS v2.1 (DE Patched)', ENDL, 0
msg_prompt:    db '> ', 0
msg_newline:   db ENDL, 0
msg_unknown:   db 'Unknown command.', ENDL, 0
msg_help_text: db 'CLS, HELP, REBOOT', ENDL, 0

cmd_help:      db 'help', 0
cmd_cls:       db 'cls', 0
cmd_reboot:    db 'reboot', 0

cmd_buffer:    times 16 db 0  

; Executable Master Boot Record (MBR) padding
times 510-($-$$) db 0
dw 0AA55h
