org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A
%define ENDP 0Dh, 0Ah

start:
     jmp main


puts:
    push si
    push ax

.loop:
     lodsb
     or al, al
     jz .done

     mov ah, 0x0E
     mov bh, 0
     int 0x10

     jmp .loop




.done:
     pop ax
     pop si 
     ret




main:
     mov ax, 0
     mov ds, ax
     mov es, ax

     mov ss, ax
     mov sp, 0x7B00

     cld

     mov si, msg_hello
     call puts

     mov si, msg_hallo
     call puts

     mov si, msg_prompt
     call puts

     .wait:
          mov ah, 0
          int 16h

          cmp al, 0Dh
          je .done

          mov ah, 0Eh
          int 10h

          

          jmp .wait

     .done:
           mov si, msg_bye
           call puts

           mov si, msg_prompt_username
           call puts

           mov si, buffer
           

            



     

     
     

     .read:
          mov ah, 0
          int 16h

          cmp al, 0Dh
          je .done_input

          mov [si], al
          inc si

          mov ah, 0x0E
          mov bh, 0
          int 10h

          jmp .read

          
           
     .done_input:
          mov byte [si], 0

          mov si, msg_saved
          call puts



          ;mov si, buffer
          ;call puts




          ;mov si, buffer
          ;mov di, cmd_user
          



     mov si, msg_line
     call puts


     .read_cmd:


               mov si, msg_cmd
               call puts

               mov si, buffer_cmd_input
               


     .wait_cmd:
          mov ah, 0
          int 16h

          cmp al, 0Dh
          je .done_cmd

          mov [si], al
          inc si

          mov ah, 0x0E
          mov bh, 0
          int 10h

          

          jmp .wait_cmd

     .done_cmd:
           mov byte [si], 0

           mov si, msg_line
           call puts
          

           ; check if cmd_user = buffer_cmd_input
           mov si, buffer_cmd_input
           call puts

           mov si, buffer_cmd_input
           mov di, cmd_user


     .compare_cmd_loop:
               mov al, [si]
               mov bl, [di]
               cmp al, bl
               jne .not_equal
               cmp al, 0
               je .equal
               inc si
               inc di
               jmp .compare_cmd_loop

     .equal:
          mov si, msg_match
          call puts
          jmp .continue

     .not_equal:
          mov si, msg_no_match
          call puts

     .continue:
          mov si, msg_continue
          call puts







     ; .done_cmd_input
     ; .read_cmd2
     ; .done_cmd2
     ; .compare_cmd
     ; .cmd_ok
     ; .cmd_not_ok


     ; .ask_username
     ; .read_user
     ; .done_user
     ; .compare_user
     ; .user_ok
     ; .user_not_ok
     
     ; newline


     


     
     
     ;.cleanup:
          ;mov ah, 0x01
          ;mov ch, 0x20
          ;mov cl, 0x00
          ;int 0x10


.halt:
      hlt
      jmp .halt


msg_hello: db 'Hello world!', ENDL, 0
msg_hallo: db 'Hallo', ENDL, 0
msg_bye db ENDL, 'Bye', 0
msg_prompt db ENDL, 'Type something and press Enter:', ENDL, 0
msg_prompt_username db ENDL, 'Type username: ', ENDL, 0
msg_saved db ENDL,'Data saved in buffer', ENDL, 0
;msg_ok db ENDL, 'Command OK: ', 0
msg_err db ENDL, 'Unknown command', 0 
msg_cmd db ENDL, 'Type CMD (user):', 0
msg_line db ENDL, '-------------', ENDL, 0

;msg_cmd_ok db ENDL, 'Command OK', 0
;msg_cmd_err db ENDL, 'Unknown command', 0 

msg_match db ENDL,'Match found!', 13, 10, 0
msg_no_match db 'No match!', 13, 10, 0
msg_continue db 'you can continue!', 13, 10, 0



cmd_user db 'user', 0


cmd_input: times 16 db 0
cmd_len db 0

buffer_cmd_input: times 16 db 0

buffer: times 16 db 0




%if ($-$$) > 510
     %error "Boot sector code too large!"
%endif

times 510-($-$$) db 0
dw 0AA55h
    
