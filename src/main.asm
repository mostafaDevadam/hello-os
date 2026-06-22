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

          mov si, msg_cmd
          call puts

          mov si, buffer
          mov di, cmd_user



          


          
     .compare:

             
             
             mov al, [si]
             mov bl, [di]

             cmp al, bl
             jne .not_ok

             cmp al, 0
             je .ok

             inc si
             inc di
             jmp .compare

     .ok:
         mov si, msg_ok
         call puts
         jmp .cleanup


     .not_ok:
            mov si, msg_err
            call puts
            jmp .halt 

     
     
     .cleanup:
          mov ah, 0x01
          mov ch, 0x20
          mov cl, 0x00
          int 0x10


.halt:
      hlt
      jmp .halt


msg_hello: db 'Hello world!', ENDL, 0
msg_hallo: db 'Hallo', ENDL, 0
;msg_bye db 0Dh, 0Ah, 'Bye', 0
msg_bye db ENDL, 'Bye', 0
msg_prompt db ENDL, 'Type something and press Enter:', ENDL, 0
msg_prompt_username db ENDL, 'Type username: ', ENDL, 0
msg_saved db ENDL,'Data saved in buffer', ENDL, 0
msg_ok db ENDL, 'Command OK: ', 0
msg_err db ENDL, 'Unknown command', 0 
msg_cmd db ENDL, 'Type CMD (user):', 0

cmd_user db 'user', 0

buffer: times 16 db 0

times 510-($-$$) db 0
dw 0AA55h
    
