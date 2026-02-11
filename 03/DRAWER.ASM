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
separator       equ '/'

rect_style      struc
                        global_filling  db ?
                        global_style    db ?
                        global_atribute db ?
                ends

rect_filling    struc
                        filling_ul db ?
                        filling_u  db ?
                        filling_ur db ?
                        filling_ml db ?
                        filling_m  db ?
                        filling_mr db ?
                        filling_dl db ?
                        filling_d  db ?
                        filling_dr db ?
                ends


pushaem   macro 
                push ax 
                push bx
                push cx
                push dx
                push di
                push si
        endm
        
popaem    macro 
                pop si
                pop di
                pop dx
                pop cx
                pop bx
                pop ax
        endm

; =========================================================

__start__:	

                mov ch, 05h
                mov cl, 0ah

                call draw_frame

                mov si, 81h
                call print_text

                __exit__

.data 
FRAME_STYLE rect_style <BG_BLUE, BG_GREEN, BG_BLUE xor FG_BLUE xor FG_GREEN xor FG_RED>        
FILLING rect_filling <43d,45d,43d,124d,32d,124d,43d,45d,43d>
.code

; ======================= FUNCTIONS ========================

; ==================== STRING FUNCTION =====================

;si - string ptr
;return 
;   ax - string length 
;   si - skipped until separator or 0Dh
strlen:

                xor ax, ax

@@scope:
                mov bl, [si]
                inc si
                cmp bl, separator
                je @@livaem
                cmp bl, 0Dh
                je @@livaem
                inc ax
                jmp @@scope 
@@livaem:
                ret

;si - string ptr
;al - symbol
;return 
;   cx - symbol_amount 
count_sumbols:

                xor cx,cx 

@@scope:
                mov bl, [si]
                inc si
                cmp bl, 0Dh
                je @@livaem
                cmp bl, al
                je @@increment
        
                jmp @@scope 
@@livaem:
                ret

@@increment:
                inc cx
                jmp @@scope


;al - height
;si - string ptr
write_string_centered:

                push ax
                push si 

                call strlen 
                mov cx, ax

                pop si 
                pop ax

                xor dx, dx
                mov dl, ah
                mov di, center_x
                mov bx, cx
                shr bx, 1
                sub di, bx
                mov al, FRAME_STYLE.global_atribute

                call write_line

                ret

;ah - height 
;si - text 
print_text:

@@scope:

                call write_string_centered
                mov bl, [si]
                cmp bl, 0Dh
                je @@livaem 
                inc si
                inc ah
                jmp @@scope

@@livaem:
                ret
    



; al    - atribute
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

                mov dl, al
                mov bx, vram_location
                mov es, bx 

                test cx,cx
                jz @@livaem
                cld 
    
@@scope:        lodsb
                stosb
                mov es:[di], dl
                inc di
                loop @@scope 
@@livaem:
                ret

; ================== FRAME_FUNCTION =======================

;ch - height 
;cl - length 
;return 
;   ah - start_height 

draw_frame:

; centering frame

                mov bx, cx

                shr bh, 1  
                shr bl, 1
                add bx, 0101h  
                    
; bh: height / 2 + 1 bl: length / 2 + 1 
                
                mov ch, center_x
                mov cl, center_x

                mov dh, center_y
                mov dl, center_y

                sub ch, bl
                add cl, bl

                sub dh, bh
                add dl, bh

;               (ch,dh)           (cl,dh)    
;       
;               (ch,dl)           (cl,dl)

; drawing frame filling

                push dx ; for returning first y 
                mov ah, FRAME_STYLE.global_filling ; atribute for filling 
                mov al, FILLING.filling_m; 
                pushaem 
                call draw_box
                popaem

; drawing borders

                mov ah, FRAME_STYLE.global_style  ;atribute for frame  

                call draw_vertical_borders
                call draw_horizontal_borders
                call draw_corners

                pop ax ; pushes first frame string
                ret
        
; ch - x min  
; cl - x max 
; dh - y min 
; dl - y max 
draw_vertical_borders:

                pushaem  
                xor bx,bx 
                mov bl, ch
                mov ch, dh 
                mov cl, dl
                mov si, bx 
                dec si
                mov al, FILLING.filling_ml
                call draw_vertical
                popaem 

                pushaem
                xor bx, bx 
                mov bl, cl
                mov ch, dh
                mov cl, dl
                mov si, bx 
                inc si
                mov al, FILLING.filling_ml
                call draw_vertical
                popaem

                ret


; ch - x min  
; cl - x max 
; dh - y min 
; dl - y max 
draw_horizontal_borders: 

                pushaem                
                xor bx, bx 
                mov bl, dh
                mov si, bx 
                dec si
                mov al, FILLING.filling_u
                call draw_horizontal
                popaem                
        
                pushaem                
                xor bx, bx 
                mov bl, dl
                mov si, bx 
                inc si
                mov al, FILLING.filling_u
                call draw_horizontal
                popaem     

                ret   

draw_corners:

                mov bx, vram_location
                mov es, bx

;               (ch,dh)           (cl,dh)       dh*160 in stack
;       
;               (ch,dl)           (cl,dl)       dl*160 in dx 

                xor bx, bx
                mov bl, dh
                xor dh, dh

                mov si, bx  
                dec si
                call translate_string
                push si  

                mov si, dx  
                inc si
                call translate_string
                mov dx, si

                dec ch
                inc cl
                shl cx, 1
                
                mov al, FILLING.filling_ul
                xor bx, bx 
                mov bl, ch
                add bx, dx 
                mov es:[bx], ax 
                
                mov al, FILLING.filling_ur
                xor bx, bx 
                mov bl, cl
                add bx, dx 
                mov es:[bx], ax 
                
                pop dx 

                mov al, FILLING.filling_dl
                xor bx, bx 
                mov bl, ch
                add bx, dx 
                mov es:[bx], ax 
                
                mov al, FILLING.filling_dr
                xor bx, bx 
                mov bl, cl
                add bx, dx 
                mov es:[bx], ax 

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

; ax - character(ASCII table) with atribute
; si - column number 
; ch - start position 
; cl - end position 
draw_vertical:  

                mov bx, vram_location        
                mov es, bx              ;vram_location -> es
; //TODO copypast 
                xor bx, bx
                xor dx, dx
                mov bl, ch  
                mov dl, ch
                shl dx, 1
                shl bx, 3
                add bx, dx
                shl bx, 4
                
                shl si, 1 
                add bx, si

                sub cl, ch  
                xor ch, ch
                add cx, 1

@@scope:                               
                mov word ptr es:[bx], ax
                add bx, 160 
                loop @@scope

                ret

end __start__