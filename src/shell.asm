org 0x0000          ; Geladen bei Segment 0x1000, Offset 0x0000
bits 16

%define ENDL 0x0D, 0x0A

main:
    ; Segmentregister auf den Ausführungsbereich einstellen
    mov ax, 0x1000
    mov ds, ax
    mov es, ax

    call clear_screen
    call print_logo      
    mov si, msg_welcome
    call puts

shell_loop:
    mov si, msg_prompt
    call puts
    mov di, cmd_buffer

input_loop:
    call getc       

    ; Prüfen, ob das deutsche Layout aktiv ist
    mov byte [temp_shift], 0
    cmp byte [kb_layout], 1
    jne .process_key   

    ; === DEUTSCHES TASTATUR-LAYOUT MAPPING ===
    push ds
    push bx
    mov bx, 0x40
    mov ds, bx
    mov bl, [0x17]  
    and bl, 0x03    
    pop bx
    pop ds          
    mov [temp_shift], bl 

    cmp ah, 0x15    ; Physikalisch 'Y' -> 'Z'
    je .map_z
    cmp ah, 0x2C    ; Physikalisch 'Z' -> 'Y'
    je .map_y
    cmp ah, 0x0C    ; Physikalisch '-' -> 'ß' / '?'
    je .map_sz
    cmp ah, 0x1A    ; Physikalisch '[' -> 'Ü'
    je .map_ue
    cmp ah, 0x1B    ; Physikalisch ']' -> '+' / '*'
    je .map_plus
    cmp ah, 0x27    ; Physikalisch ';' -> 'Ö'
    je .map_oe
    cmp ah, 0x28    ; Physikalisch "'" -> 'Ä'
    je .handle_ae
    cmp ah, 0x2B    ; Physikalisch '\' -> '#' / '\''
    je .map_hash
    cmp ah, 0x35    ; Physikalisch '/' -> '-' / '_'
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

; =============================================================================
; INTERAKTIVES REVOLVIERENDES CONFIG MENU
; =============================================================================
do_config:
    mov byte [menu_index], 0    

.render_menu:
    call clear_screen
    mov si, msg_menu_header
    call puts

    ; --- Eintrag 0: Tastaturlayout ---
    cmp byte [menu_index], 0
    je .active_0
    mov si, msg_menu_kb_en
    cmp byte [kb_layout], 0
    je .print_0
    mov si, msg_menu_kb_de
.print_0:
    call puts
    jmp .render_1
.active_0:
    mov si, msg_menu_active_kb_en
    cmp byte [kb_layout], 0
    je .print_act_0
    mov si, msg_menu_active_kb_de
.print_act_0:
    call puts

.render_1:
    ; --- Eintrag 1: Farbauswahl ---
    cmp byte [menu_index], 1
    je .active_1
    mov si, msg_menu_col_blue
    cmp byte [text_color], 0x09
    je .print_1
    mov si, msg_menu_col_green
    cmp byte [text_color], 0x0A
    je .print_1
    mov si, msg_menu_col_red
    cmp byte [text_color], 0x0C
    je .print_1
    mov si, msg_menu_col_white
.print_1:
    call puts
    jmp .render_2
.active_1:
    mov si, msg_menu_act_col_blue
    cmp byte [text_color], 0x09
    je .print_act_1
    mov si, msg_menu_act_col_green
    cmp byte [text_color], 0x0A
    je .print_act_1
    mov si, msg_menu_act_col_red
    cmp byte [text_color], 0x0C
    je .print_act_1
    mov si, msg_menu_act_col_white
.print_act_1:
    call puts

.render_2:
    ; --- Eintrag 2: Schriftgröße ---
    cmp byte [menu_index], 2
    je .active_2
    mov si, msg_menu_sz_small
    cmp byte [font_size_flag], 1
    je .print_2
    mov si, msg_menu_sz_large
    cmp byte [vga_mode], 0x01
    je .print_2
    mov si, msg_menu_sz_medium
.print_2:
    call puts
    jmp .wait_input
.active_2:
    mov si, msg_menu_act_sz_small
    cmp byte [font_size_flag], 1
    je .print_act_2
    mov si, msg_menu_act_sz_large
    cmp byte [vga_mode], 0x01
    je .print_act_2
    mov si, msg_menu_act_sz_medium
.print_act_2:
    call puts

.wait_input:
    call getc       

    cmp al, 0x1B    ; ESC gedrückt?
    je .exit_menu

    cmp al, 0x20    ; LEERTASTE gedrückt?
    je .toggle_setting

    cmp ah, 0x48    ; PFEILTASTE HOCH?
    je .move_up

    cmp ah, 0x50    ; PFEILTASTE RUNTER?
    je .move_down

    jmp .wait_input 

.move_up:
    dec byte [menu_index]
    cmp byte [menu_index], 255  
    jne .render_menu
    mov byte [menu_index], 2    
    jmp .render_menu

.move_down:
    inc byte [menu_index]
    cmp byte [menu_index], 3    
    jne .render_menu
    mov byte [menu_index], 0    
    jmp .render_menu

.toggle_setting:
    cmp byte [menu_index], 0
    je .toggle_kb
    cmp byte [menu_index], 1
    je .toggle_color
    cmp byte [menu_index], 2
    je .toggle_size
    jmp .render_menu

.toggle_kb:
    xor byte [kb_layout], 1     
    jmp .render_menu

.toggle_color:
    cmp byte [text_color], 0x09 
    je .set_g
    cmp byte [text_color], 0x0A 
    je .set_r
    cmp byte [text_color], 0x0C 
    je .set_w
    mov byte [text_color], 0x09 
    jmp .render_menu
.set_g: 
    mov byte [text_color], 0x0A 
    jmp .render_menu
.set_r: 
    mov byte [text_color], 0x0C 
    jmp .render_menu
.set_w: 
    mov byte [text_color], 0x0F 
    jmp .render_menu

.toggle_size:
    cmp byte [font_size_flag], 1
    je .to_medium
    cmp byte [vga_mode], 0x03
    je .to_large
    mov byte [vga_mode], 0x03
    mov byte [font_size_flag], 1
    jmp .render_menu
.to_medium:
    mov byte [vga_mode], 0x03
    mov byte [font_size_flag], 0
    jmp .render_menu
.to_large:
    mov byte [vga_mode], 0x01
    mov byte [font_size_flag], 0
    jmp .render_menu

.exit_menu:
    call clear_screen            
    mov si, msg_welcome
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

print_logo:
    mov si, msg_logo
    call puts
    ret

puts:
    push si
    push ax
.loop:
    lodsb
    or al, al
    jz .done
    call putc 
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
    push bx
    mov ah, 0x0E         
    mov bh, 0            
    mov bl, [text_color] 
    int 0x10
    pop bx
    ret

clear_screen:
    push ax
    push bx
    push cx
    push dx

    mov ah, 0x00
    mov al, [vga_mode]   
    int 0x10

    cmp byte [font_size_flag], 1
    jne .skip_font_load
    mov ax, 0x1112       
    mov bl, 0x00         
    int 0x10
.skip_font_load:

    mov ah, 0x06         
    mov al, 0            
    mov bh, [text_color] 
    mov cx, 0x0000       
    mov dx, 0x3250       
    int 0x10

    pop dx
    pop cx
    pop bx
    pop ax
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

msg_logo:
    db '     *     ', ENDL
    db '    ***    ', ENDL
    db '   *****   ', ENDL
    db ' ********* ', ENDL
    db '   *****   ', ENDL
    db '    ***    ', ENDL
    db '     *     ', ENDL, ENDL, 0

msg_welcome:       db 'MyCustomOS Shell Loaded!', ENDL, 0
msg_prompt:        db 'Console> ', 0
msg_newline:       db ENDL, 0
msg_unknown:       db 'Invalid syntax.', ENDL, 0
msg_help_text:     db 'Commands: CLS, HELP, REBOOT, CONFIG', ENDL, 0

msg_menu_header:        db '--- SYSTEM SETTINGS ---', ENDL, 'Use Up/Down. Space=Toggle, Esc=Exit', ENDL, ENDL, 0

msg_menu_kb_en:         db '  Layout: [ English ]', ENDL, 0
msg_menu_kb_de:         db '  Layout: [ German ]', ENDL, 0
msg_menu_active_kb_en:  db '> Layout: [ English ] <', ENDL, 0
msg_menu_active_kb_de:  db '> Layout: [ German ] <', ENDL, 0

msg_menu_col_blue:      db '  Color:  [ Blue ]', ENDL, 0
msg_menu_col_green:     db '  Color:  [ Green ]', ENDL, 0
msg_menu_col_red:       db '  Color:  [ Red ]', ENDL, 0
msg_menu_col_white:     db '  Color:  [ White ]', ENDL, 0

msg_menu_act_col_blue:  db '> Color:  [ Blue ] <', ENDL, 0
msg_menu_act_col_green: db '> Color:  [ Green ] <', ENDL, 0
msg_menu_act_col_red:   db '> Color:  [ Red ] <', ENDL, 0
msg_menu_act_col_white: db '> Color:  [ White ] <', ENDL, 0
msg_menu_sz_small:      db '  Size:   [ Small ]', ENDL, 0
msg_menu_sz_medium:     db '  Size:   [ Medium ]', ENDL, 0
msg_menu_sz_large:      db '  Size:   [ Large ]', ENDL, 0
msg_menu_act_sz_small:  db '> Size:   [ Small ] <', ENDL, 0
msg_menu_act_sz_medium: db '> Size:   [ Medium ] <', ENDL, 0
msg_menu_act_sz_large:  db '> Size:   [ Large ] <', ENDL, 0

cmd_help:          db 'help', 0
cmd_cls:           db 'cls', 0
cmd_reboot:        db 'reboot', 0
cmd_config:        db 'config', 0

; Status-Variablen im RAM
menu_index:        db 0
kb_layout:         db 0
text_color:        db 0x09
vga_mode:          db 0x01
font_size_flag:    db 0
temp_shift:        db 0
cmd_buffer:        times 16 db 0