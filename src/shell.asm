org 0x0000          ; Loaded at segment 0x1000, offset 0x0000
bits 16

%define ENDL 0x0D, 0x0A

main:
    ; Fix segment registers to point to the new execution space
    mov ax, 0x1000
    mov ds, ax
    mov es, ax

    call clear_screen
    mov si, msg_welcome
    call puts

shell_loop:
    mov si, msg_prompt
    call puts
    mov di, cmd_buffer

input_loop:
    call getc       

    ; Check if we should use the German Translation Layer
    mov byte [temp_shift], 0
    cmp byte [kb_layout], 1
    jne .process_key   

    ; === GERMAN KEYBOARD TRANSLATION LAYER ===
    push ds
    push bx
    mov bx, 0x40
    mov ds, bx
    mov bl, [0x17]  
    and bl, 0x03    
    pop bx
    pop ds          
    mov [temp_shift], bl 

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
    je .handle_ae
    cmp ah, 0x2B    ; Physical '\' -> '#' / '\''
    je .map_hash
    cmp ah, 0x35    ; Physical '/' -> '-' / '_'
    je .map_minus
    jmp .process_key

.map_z:
    mov al, 'z'
    cmp byte [temp_shift], 0
    jz .process_key
    mov al, 'Z'
    jmp .process_key
.map_y:
    mov al, 'y'
    cmp byte [temp_shift], 0
    jz .process_key
    mov al, 'Y'
    jmp .process_key
.map_sz:
    mov al, 0xE1    
    cmp byte [temp_shift], 0
    jz .process_key
    mov al, '?'
    jmp .process_key
.map_ue:
    mov al, 0x9A    
    jmp .process_key
.map_plus:
    mov al, '+'
    cmp byte [temp_shift], 0
    jz .process_key
    mov al, '*'
    jmp .process_key
.map_oe:
    mov al, 0x94    
    jmp .process_key
.handle_ae:
    mov al, 0x84    
    jmp .process_key
.map_hash:
    mov al, '#'
    cmp byte [temp_shift], 0
    jz .process_key
    mov al, '"'
    jmp .process_key
.map_minus:
    mov al, '-'
    cmp byte [temp_shift], 0
    jz .process_key
    mov al, '_'

.process_key:
    cmp al, 0x0D    ; Enter
    je execute_command
    cmp al, 0x08    ; Backspace
    je handle_backspace

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

    mov si, cmd_buffer
    mov di, cmd_config
    call strcmp_insensitive
    je do_config

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

do_config:
    mov si, msg_config_prompt
    call puts
.wait_choice:
    call getc
    cmp al, '1'
    je .set_en
    cmp al, '2'
    je .set_de
    jmp .wait_choice
.set_en:
    mov byte [kb_layout], 0
    mov si, msg_config_en
    call puts
    jmp clear_and_repeat
.set_de:
    mov byte [kb_layout], 1
    mov si, msg_config_de
    call puts
    jmp clear_and_repeat

clear_and_repeat:
    mov di, cmd_buffer
    mov cx, 16
    xor al, al
    rep stosb        
    jmp shell_loop

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
    int 0x16        
    ret

putc:
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    ret

clear_screen:
    mov ax, 0x0003  
    int 0x10
    ret

strcmp_insensitive:
    push si
    push di
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, 'A'
    jl .lower_bl
    cmp al, 'Z'
    jg .lower_bl
    add al, 32
.lower_bl:
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
    or al, al
    jmp .done
.equal:
    xor ax, ax
.done:
    pop di
    pop si
    ret

; =============================================================================
; DATA SEGMENT
; =============================================================================

msg_welcome:       db 'MyCustomOS Two-Stage Shell Loaded Successfully!', ENDL, 0
msg_prompt:        db 'OS_Console> ', 0
msg_newline:       db ENDL, 0
msg_unknown:       db 'Error: Invalid Command syntax.', ENDL, 0
msg_help_text:     db 'Available commands: CLS, HELP, REBOOT, CONFIG', ENDL, 0
msg_config_prompt: db 'Select Keyboard Layout (1 = English US, 2 = German DE): ', 0
msg_config_en:     db 'Success: Switched to English US mapping.', ENDL, 0
msg_config_de:     db 'Success: Switched to German QWERTZ mapping.', ENDL, 0

cmd_help:          db 'help', 0
cmd_cls:           db 'cls', 0
cmd_reboot:        db 'reboot', 0
cmd_config:        db 'config', 0

kb_layout:         db 0   
temp_shift:        db 0   
cmd_buffer:        times 16 db 0  
