.model tiny
.code 
.286
org 100h
locals @@ 

include macros.asm

; ====================== ATRIBUTES ========================

FG_BLUE         equ 00000001b
FG_GREEN        equ 00000010b
FG_RED          equ 00000100b
FG_BRIGHT       equ 00001000b

FG_WHITE        equ FG_BLUE xor FG_GREEN xor FG_RED xor FG_BRIGHT

BG_BLUE         equ 00010000b
BG_GREEN        equ 00100000b
BG_RED          equ 01000000b
BG_BLINK        equ 10000000b

BG_WHITE        equ BG_BLUE xor BG_GREEN xor BG_RED

; ======================= HELPERS =========================

VRAM_LOCATION   equ 0B800h
CENTER_X        equ 40
CENTER_Y        equ 13
SEPARATOR       equ '#'
NEW_LINE_OFFSET equ 160
BUFFER          equ 81h
BUFFER_LENGTH   equ 80h

rect_style      struc
                        global_filling    db ?
                        global_style      db ?
                        global_atribute   db ?
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

; =========================================================

__start__:	

                call main

                __exit__

.data 
FRAME_STYLE     rect_style <BG_WHITE, BG_RED, BG_WHITE>        
FILLING         rect_filling <6,5,6,5,32,5,6,5,6>
STYLES:
DREC_CLASSIC    rect_style <BG_WHITE, BG_RED, BG_WHITE>        
OLD_SCHOOL      rect_style <BG_BLUE, BG_WHITE, BG_BLUE>        
GITHUB          rect_style <      0, BG_WHITE, 0>        
FILLINGS:


; ======================= FUNCTIONS ========================

.code

; ========================= MAIN ==========================

main:

                mov cl, ds:[BUFFER_LENGTH]
                mov di, BUFFER
                call set_style

                push di 
                push cx 

                call get_size
                
                push cx
                call calculate_left_up_corner
                pop cx

                push bx 
                call draw_frame
                
                pop bx
                mov di, bx
                pop cx
                pop si
                call write_text_centered
                
                ret

; ==================== STRING FUNCTION ====================

; _________________________________________________________
; Setting frame filling  
;       
; args: 
;       es:di - input string  
;    
; delete:
;       al
; _________________________________________________________

;set_filling:
;
;                xor ax, ax
;                mov al, [si]
;                sub ax, "0"
;                mov bx, ax 
;                shl ax, 1
;                add bx, ax 
;                lea bx, [bx + offset STYLES]
;
;                mov al, [bx]
;                mov FRAME_STYLE.global_filling, al
;                
;                mov al, [bx + 1]
;                mov FRAME_STYLE.global_style, al
;                
;                mov al, [bx + 2]
;                mov FRAME_STYLE.global_atribute, al
;
;                inc si
;                mov bx, offset FILLING
;                mov cx, 9h
;@@set_param:
;                mov al, [si]
;                mov [bx], al  
;                inc si
;                inc bx
;                loop @@set_param 
;
;                ret 

; _________________________________________________________

; _________________________________________________________
; Setting frame style 
;       
; args: 
;       es:di - input string  
;       cx    - string length 
;    
; returns: 
;       es:di - ptr to skipped arg  
;       cx    - length es:di
; delete:
;       ax, bx 
; _________________________________________________________

set_style:

                call skip_spaces
                call skip_spaces
        
                mov al, es:[di]
                inc di 
                dec cx
                sub ax, "0"     

                mov bx, ax 
                shl bx, 1
                add bx, ax
                
                mov al, [bx + offset STYLES]
                mov FRAME_STYLE.global_filling, al
                inc bx

                mov al, [offset STYLES + bx]
                mov FRAME_STYLE.global_style, al
                inc bx

                mov al, [offset STYLES + bx]
                mov FRAME_STYLE.global_atribute, al
                
                call skip_spaces

                ret 

; _________________________________________________________

; _________________________________________________________
; Skip Spaces until not space symbol 
;       
; args: 
;       es:di - input string 
;       cx    - string length 
;      
; return: 
;       di - skipped until separator 
;       ci - si string length
; delete:
;       al
; _________________________________________________________

skip_spaces:

                cld
                mov al, 20h      
                
                repe scasb
                inc cx
                dec di

                ret

; _________________________________________________________

; _________________________________________________________
; Returns length of rhe ds:si string with separator 
;       symbol 
; args: 
;       es:di - input string 
;       cx    - string length 
; return: 
;       bx - string length 
;       di - skipped until separator or EOL
;       cx - length of new si string 
; delete 
;       ax
; _________________________________________________________

strlen:

                mov bx, cx
                test cx, cx 
                jz @@skip  
                
                xor ax, ax

                cld

                mov al, separator
                repne scasb
                
                jne @@skip 
                inc cx 
                dec di

@@skip:
                sub bx, cx
@@leave:
                ret
                
; _________________________________________________________

; _________________________________________________________
; Count amount of al(ASCII) symbols in string es:al 
;      
; args: 
;       al    - symbol 
;       es:di - input string 
;       cx    - string length 
;
; return:  
;       dx - symbol amount 
;
; delete       
;       cx, si
; _________________________________________________________

count_al_symbols_in_string:

                xor dx, dx 
                cld

@@continue:

                repne scasb
                je @@increment
                
                ret

@@increment: 
                inc dx
                inc si
                jmp @@continue

; _________________________________________________________

; _________________________________________________________
; Write ds:si line with ah:al indent with offset es:si 
;      
; args: 
;       cx    - printable string length 
;       es:di - offset  
;       ds:si - source 
; returns:
;       si - the next symbol after last written        
;
; delete:
;       di, cx
; _________________________________________________________

write_line:
 
                test cx, cx
                jz @@leave

                cld
                mov ah, FRAME_STYLE.global_atribute

@@scope:        lodsb
                stosw
                loop @@scope 
@@leave:

                ret
    
; _________________________________________________________
; Write string with centering  
;      
; args: 
;       cx    - string length 
;       es:di - start_line offset    
;       ds:si - source 
;
; delete:
;       di, cx, bx, si 
; _________________________________________________________

write_string_centered:

                add di, CENTER_X * 2
                sub di, cx 
                
                and di, 0FFFFh - 1 

                call write_line

                ret
; _________________________________________________________

; _________________________________________________________
; Write text with centering  
;      
; args: 
;       cx    - string length 
;       es:di - start_line offset    
;       ds:si - source 
;
; delete:
;       ax, bx, cx, dx, di, si 
; _________________________________________________________

write_text_centered:

@@scope:
                
                push cx 
                push di 
                push es 

                mov ax, ds 
                mov es, ax 
                mov di, si 

                call strlen 

                pop es
                pop di 
                pop cx

                sub cx, bx

                push cx 
                push di 
                
                mov cx, bx 
                call write_string_centered

                pop di 
                pop cx

                add di, NEW_LINE_OFFSET

                test cx, cx 
                jnz @@decrease

                ret

@@decrease:
                inc si
                dec cx 
                jmp @@scope 
                
; _________________________________________________________
    
; ==================== DRAW_FUNCTION ======================

; _________________________________________________________
; Draws horizontal line with length of cx on es:di offset  
;      
; args: 
;       ah    - atribute 
;       al    - ASCII character
;       cx    - string length 
;       es:di - start point offset    
;     
; returns:
;       di - new cursor position
;
; delete:
;       cx
; _________________________________________________________

draw_horizontal:   

                rep stosw

                ret

; _________________________________________________________
; Draws horizontal line() with length of cx on es:di offset  
;      
; args: 
;1st symbol:    ah    - atribute  
;               al    - ASCII character 
;2st symbol:    bh    - atribute  
;               bl    - ASCII character 
;3st symbol:    dh    - atribute  
;               dl    - ASCII character 
;
;               cx    - string length 
;               es:di - start point offset    
;
; delete:
;       di 
; _________________________________________________________

draw_frame_line:
        
                push ax
                push cx 
                mov cx, 1
                call draw_horizontal

                pop cx 
                mov ax, bx
                call draw_horizontal
                
                mov cx, 1
                mov ax, dx 
                call draw_horizontal

                pop ax 
                
                ret
; _________________________________________________________

; _________________________________________________________
; Draws a frame   
;      
; args: 
;               ch - height
;               cl - length
;               es:di - start point offset    
;
; delete:
;       ax, bx, cx, dx, di, si
; _________________________________________________________

draw_frame:

;;;;;;;;;;;;;;;;;;;;;;;; saving cx ;;;;;;;;;;;;;;;;;;;;;;;;

                mov si, cx 
                
;;;;;;;;;;;;;;;;;;; drawing upper part ;;;;;;;;;;;;;;;;;;;;

                mov ah, FRAME_STYLE.global_style
                mov bh, FRAME_STYLE.global_style
                mov dh, FRAME_STYLE.global_style

                mov al, FILLING.filling_ul
                mov bl, FILLING.filling_u
                mov dl, FILLING.filling_ur

                push di

                xor ch, ch 
                call draw_frame_line
                
                pop di
                add di, NEW_LINE_OFFSET

;;;;;;;;;;;;;;;;;;; drawing middle part ;;;;;;;;;;;;;;;;;;;;
        
                mov cx, si 

                mov ah, FRAME_STYLE.global_style
                mov bh, FRAME_STYLE.global_filling
                mov dh, FRAME_STYLE.global_style

                mov al, FILLING.filling_ml
                mov bl, FILLING.filling_m
                mov dl, FILLING.filling_mr

                jmp @@test
@@scope:
        
                dec ch 
                mov si, cx

                xor ch, ch 
                push di
                call draw_frame_line
                pop di
                add di, NEW_LINE_OFFSET
                
                jnz @@test 
                
@@skip:

;;;;;;;;;;;;;;;;;; drawing lower part ;;;;;;;;;;;;;;;;;;;;;

                mov ah, FRAME_STYLE.global_style
                mov bh, FRAME_STYLE.global_style
                mov dh, FRAME_STYLE.global_style

                mov al, FILLING.filling_dl
                mov bl, FILLING.filling_d
                mov dl, FILLING.filling_dr
                
                mov cx, si

                call draw_frame_line
                
                ret

@@test:
                mov cx, si 
                test ch, ch
                jnz @@scope
                jmp @@skip

; _________________________________________________________

; _________________________________________________________
; Get frame optimal size considered to string content  
;      
; args: 
;       cx    - string length
;       es:di - text 
;
; returns:
;       ch - frame height 
;       cl - frame length 
;       
; delete:
;       ?all?
; _________________________________________________________

get_size:

                push cx 
                push di

                mov al, SEPARATOR
                call count_al_symbols_in_string
                mov cx, dx 
                inc cx
                shl cx, 8

                pop di
                pop ax
                push cx
                
                mov cx, ax 
        
@@scope:

                push cx
                call strlen 
                pop cx 

                sub cx, bx

                cmp bx, dx 
                ja @@new_lenght
@@continue:

                test cx, cx 
                jnz @@decrease

                pop cx
                mov cl, dl 
                inc cl 

                ret

@@decrease:
                inc di
                dec cx 
                jmp @@scope 

@@new_lenght:
                mov dx, bx
                jmp @@continue 
                
; _________________________________________________________

; _________________________________________________________
; Translates bx into string offset  
;      
; args: 
;       di - string number 
;
; return: 
;       di - new offset 
; del 
;       bx
; _________________________________________________________

translate_string:

                mov bx, di 
                shl di, 3
                shl bx, 1
                add di, bx              
                shl di, 4
                
                ret

; _________________________________________________________

; _________________________________________________________
; Count left corner coordinate  
;      
; args: 
;       ch - frame height 
;       cl - frame length 
;
; returns:
;       es - vram sector  
;       di - left corner offset 
;       bx - start string 
;       
; _________________________________________________________

calculate_left_up_corner:

                mov bx, VRAM_LOCATION
                mov es, bx
                
                shr ch, 1
                shr cl, 1
                add cx, 0101h
                
                mov bx, CENTER_Y
                sub bl, ch
                mov di, bx

                call translate_string
                mov bx, di
                add bx, NEW_LINE_OFFSET
                push bx

                mov bx, CENTER_X
                sub bl, cl 
                shl bx, 1

                add di, bx

                pop bx

                ret

; _________________________________________________________

end __start__



