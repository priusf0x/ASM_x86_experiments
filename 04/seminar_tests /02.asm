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

                mov cx, es:[38d]
                mov bx, es:[36d]

                mov word ptr cs:[offset S410ffs41], bx 
                mov word ptr cs:[offset S41s4gme4n1], cx 

                cli 
                mov ax, cs
                mov es:[38d], ax
                mov es:[36d], offset int09overhead 
                sti

                __resident__ 
                    
; ==================== NEW_INTERRUPT ======================


int09overhead   proc  

                push bx es ax

                push 40h
                pop es
                
                mov bx, es:[1ah]

                sub bx, 1eh
                add bx, 30d
                and bx, 31d
                add bx, 1eh

                mov ax, es:[bx]
                mov ah, 4ch

                push 0b800h
                pop es
                mov bx, (80d * 5 + 40d) * 2

                mov es:[bx], ax 

                pop ax es bx 
            
                db 0eah 
S410ffs41:      dw 0
S41s4gme4n1:    dw 0

                endp

FILE_LENGTH:

end             __start__     
