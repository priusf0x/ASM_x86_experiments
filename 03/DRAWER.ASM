.model tiny
.code 
org 100h

include macros.asm

; ====================== ATRIBUTES ========================

FG_BLUE         equ 0000000100000000b
FG_GREEN        equ 0000001000000000b
FG_RED          equ 0000010000000000b
FG_BRIGHT       equ 0000100000000000b

BG_BLUE         equ 0001000000000000b
BG_GREEN        equ 0010000000000000b
BG_RED          equ 0100000000000000b
BG_BLINK        equ 1000000000000000b

; ======================= HELPERS =========================

vram_location   equ 0B800h

; =========================================================

__start__:	

                mov ax , 02h or BG_BLUE or FG_RED
                mov si , 02h 
                mov cx , 0a02h

                call draw_horizontal
                
                mov ax , 02h or BG_BLUE or FG_RED
                mov si , 02h 
                mov cx , 0a02h
                
                call draw_vertical
                __exit__


; ======================= FUNCTIONS ========================

; ax - character(ASCII table) with atribute
; si - line number 
; cl - start position 
; ch - end position 
draw_horizontal:   

                mov bx, vram_location        
                mov es, bx              ;vram_location -> es

                mov bx, si              ;mul on 160
                shl bx, 1
                shl si, 3
                add si, bx              ; si * 10
                shl si, 4               ; si * 16

                xor bx, bx 
                add bl, cl
                add bl, cl  
                sub ch, cl  
                shr cx, 8
                add cx, 1
                add bx, si

.scope1:                               
                mov word ptr es:[bx], ax
                add bx, 2 
                loop .scope1

                ret
        
; ax - character(ASCII table) with atribute
; si - column number 
; cl - start position 
; ch - end position 
draw_vertical:  

                mov bx, vram_location        
                mov es, bx              ;vram_location -> es

                xor bx, bx
                xor dx, dx
                mov bl, cl  
                mov dl, cl
                shl dx, 1
                shl bx, 3
                add bx, dx
                shl bx, 4
                
                shl si, 1 
                add bx, si

                sub ch, cl  
                shr cx, 8
                add cx, 1

.scope2:                               
                mov word ptr es:[bx], ax
                add bx, 160 
                loop .scope2

                ret

end 		__start__