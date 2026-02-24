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

__resident__ macro
                mov ax, 3100h
                mov dx, offset FILE_LENGTH
                shr dx, 4
                inc dx
                int 21h
             endm

; ========================= MAIN ==========================

__start__:

                push 0 
                pop es 

                cli 
                mov ax, cs
                mov es:[bx + 38d], ax
                mov es:[bx + 36d], offset new09interrupt
                sti

                __resident__ 

; ==================== NEW_INTERRUPT ======================


new09interrupt  proc  

                push ax bx es

                push 0b800h
                pop es
                mov bx, (80d * 5 + 40d) * 2
                mov ah, 60h

                in al, 60h

                mov es:[bx], ax

                in al, 61h
                or al, 80h 
                out 61h, al 
                and al, not 80h
                out 61h, al 

                mov al, 20h
                out 20h, al
                
                pop es bx ax
                iret

                endp

FILE_LENGTH:

end             __start__     
