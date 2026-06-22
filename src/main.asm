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

     mov ah, 0x0e
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
     mov sp, 0x7C00

     mov si, msg_hello
     call puts

     mov si, msg_hallo
     call puts

     ;mov ax, 0
     ;mov ds, ax
     ;mov es, ax

     ;mov ah, 0
     ;int 16h

     ;mov ah, 0Eh
     ;int 10h

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
           

     




    ;hlt

.halt:
      hlt
      jmp .halt


msg_hello: db 'Hello world!', ENDL, 0
msg_hallo: db 'Hallo', ENDL, 0
;msg_bye db 0Dh, 0Ah, 'Bye', 0
msg_bye db ENDL, 'Bye', 0
msg_prompt db 'Type something and press Enter:', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
    
