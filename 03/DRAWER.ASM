.model tiny
.code 
org 100h
locals @@ 

include macros.asm

; ====================== ATRIBUTES ========================

FG_BLUE         equ 00000001b
FG_GREEN        equ 00000010b
FG_RED          equ 00000100b
FG_BRIGHT       equ 00001000b

BG_BLUE         equ 00010000b
BG_GREEN        equ 00100000b
BG_RED          equ 01000000b
BG_BLINK        equ 10000000b

; ======================= HELPERS =========================

vram_location   equ 0B800h
center_x        equ 40
center_y        equ 13

rect_style  struc
                filling db FG_BLUE
                frame   db FG_RED 
            ends

; =========================================================

__start__:	

                mov ch, 2
                mov cl, 10

                call draw_frame

                __exit__

.data 
FRAME_STYLES:
WHITE_ROSE rect_style <BG_BLUE, BG_RED>        
.code

; ======================= FUNCTIONS ========================

;ax - 
;ch - height 
;cl - length 
;si - style_number 
;return 
;
draw_frame:

                mov bx, cx

                shr bh, 1  
                shr bl, 1
                add bx, 0101h  
                    
; bh: height / 2 + 1 : length / 2 + 1 
                
                mov ch, center_x
                mov cl, center_x

                mov dh, center_y
                mov dl, center_y

                sub ch, bl
                add cl, bl

                sub dh, bh
                add dl, bh

                mov ax, 2020h
                call draw_box

                ret


; ax    - atribute
; ds:si - string   
; dx - line number  
; di - position in the row
; cx - string lenght
write_line:

                push si
                mov si, dx
                call translate_string
                shl di, 1
                add di, si
                pop si

                mov dx, ax
                mov bx, vram_location
                mov es, bx 

                test cx,cx
                jz @@livaem
                cld 
    
@@scope:        lodsb
                stosb
                mov es:[di], dx
                inc di
                loop @@scope 
@@livaem:
                ret


; ax - character(ASCII table) with atribute
; ch - x min  
; cl - x max 
; dh - y min 
; dl - y max 
draw_box:   

                xor si,si   
@@scope:                               
                mov si, dx
                shr si, 8
                mov di, cx
                call draw_horizontal 
                mov cx, di
                inc dh 
                cmp dh,dl
                jbe @@scope 

                ret

; translates string number in offset
; si - multiply on 160
translate_string:

                mov bx, si              ;mul on 160
                shl bx, 1
                shl si, 3
                add si, bx              ; si * 10
                shl si, 4               ; si * 16
                
                ret


; ax - character(ASCII table) with atribute
; si - line number 
; ch - start position 
; cl - end position 
draw_horizontal:   

                call translate_string
                
                mov bx, vram_location        
                mov es, bx              ;vram_location -> es

                xor bx, bx 
                add bl, ch
                add bl, ch  
                sub cl, ch  
                xor ch, ch
                add bx, si
                
                cld
                inc cx

@@scope:                               
                mov word ptr es:[bx], ax
                add bx, 2 
                loop @@scope

                ret

end __start__