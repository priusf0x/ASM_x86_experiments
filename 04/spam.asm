
.model tiny
.code 
.286
org 100h
locals @@ 


; ======================== MACRO =========================

__exit__    macro 
                mov ah, 4ch
                int 21h
            endm

__leave__   macro
                mov ax, 3100h
                mov dx, offset FILE_LENGTH
                shr dx, 3
                int 21h
             endm

__jump__    macro 
                db 0eah 
            endm

; ========================= MAIN ==========================

__start__:

                sti
@@loop:

                mov ax, 01h
                mov bx, 02h
                mov cx, 03h
                mov dx, 04h

                mov si, 05h
                mov di, 06h
                mov bp, 07h

                push 08h
                pop es

                push 09h
                pop ds

                push 0ah
                pop ss

                int 09h
                jmp @@loop

                __exit__

end __start__

