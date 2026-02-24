.model tiny
.code 
.286
org 100h
locals @@ 

include macros.asm

; ====================== ATTRIBUTES ========================

FG_BLUE         equ 00000001b
FG_GREEN        equ 00000010b
FG_RED          equ 00000100b
FG_BRIGHT       equ 00001000b

FG_WHITE        equ FG_BLUE or FG_GREEN or FG_RED or FG_BRIGHT

BG_BLUE         equ 00010000b
BG_GREEN        equ 00100000b
BG_RED          equ 01000000b
BG_BLINK        equ 10000000b

BG_WHITE        equ BG_BLUE or BG_GREEN or BG_RED

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
FRAME_FILLING   rect_filling <6,5,6,5,32,5,6,5,6>
STYLES:
DREC_CLASSIC    rect_style <BG_WHITE, BG_RED, BG_WHITE>        
OLD_SCHOOL      rect_style <BG_BLUE, BG_WHITE, BG_BLUE>        
GITHUB          rect_style <      0, BG_WHITE, 0>        
FILLINGS:
DREC_FILLING    rect_filling <06, 05h, 06h , 06h, 20h,\
                              06h, 06h, 05h, 06h>
CLASSIC_FILLING rect_filling <"/", "-", "\", "|", 20h,\
                              "|", "\", "-", "/">
NAXUI_FPMI      rect_filling <0bh, 0ch, 0bh, 0ch, 20h,\
                              0ch, 0bh, 0ch, 0bh>

; ======================= FUNCTIONS ========================

.code

; ========================= MAIN ==========================

main:

                mov cl, ds:[BUFFER_LENGTH]
                mov si, BUFFER
                call set_style
                call set_filling

                push si 
                push cx 

                mov di, si

                call get_size  

                push cx
                call calculate_left_up_corner
                pop cx

                push bx

                push cx 
                push di

                call draw_frame
                
                pop di
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

set_filling:
        
                lodsb
                dec cx
                sub ax, "0"     

                jz @@parse_fillings

                dec ax 
                mov bx, ax 
                shl bx, 3          
                add bx, ax         ; multiplication on 8

                push si 
                push cx 

                mov si, offset FILLINGS 
                add si, bx 

                mov cx, 09h

                mov di, offset FRAME_FILLING 

                rep movsb 

                pop cx 
                pop si

                ret 

@@parse_fillings:
                push cx 
                mov cx, 09h
                mov di, offset FRAME_FILLING 
                rep movsb 
                pop cx 
                sub cx, 09h

                ret

; _________________________________________________________

; _________________________________________________________
; Setting frame style 
;       
; args: 
;       ds:si - input string  
;       cx    - string length 
;    
; returns: 
;       ds:si - ptr to skipped arg  
;       cx    - length es:di
; delete:
;       ax, bx, si, es
; _________________________________________________________

set_style:

                mov di, si 
                call skip_spaces
                mov si, di 
        
                lodsb
                dec cx
                sub ax, "0"     

                mov bx, ax 
                shl bx, 1 
                add bx, ax
                 
                push si 
                push cx
                                             ; preparing for copiing

                mov si, offset STYLES 
                add si, bx 

                mov cx, 03h

                mov di, offset FRAME_STYLE 

                rep movsb 

                pop cx 
                pop si

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
;di       ci - si string length
; delete:
;       al
; _________________________________________________________

skip_spaces:

                cld
                mov al, 20h ; symbol to skip    
                
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

                push bp
                mov bp, sp

                mov cx, [bp + 6]
                mov di, [bp + 4]

;;;;;;;;;;;;;;;;;;;;;;;; saving cx ;;;;;;;;;;;;;;;;;;;;;;;;

                mov si, cx 
                
;;;;;;;;;;;;;;;;;;; drawing upper part ;;;;;;;;;;;;;;;;;;;;

                mov ah, FRAME_STYLE.global_style
                mov bh, FRAME_STYLE.global_style
                mov dh, FRAME_STYLE.global_style

                mov al, FRAME_FILLING.filling_ul
                mov bl, FRAME_FILLING.filling_u
                mov dl, FRAME_FILLING.filling_ur

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

                mov al, FRAME_FILLING.filling_ml
                mov bl, FRAME_FILLING.filling_m
                mov dl, FRAME_FILLING.filling_mr

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

                mov al, FRAME_FILLING.filling_dl
                mov bl, FRAME_FILLING.filling_d
                mov dl, FRAME_FILLING.filling_dr
                
                mov cx, si

                call draw_frame_line
                
                pop bp

                ret 4

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
; Translates di into row offset  
;      
; args: 
;       di - row number 
;
; return: 
;       di - new offset 
; del 
;       bx
; _________________________________________________________

translate_string:

                mov bx, di 
                shl di, 7
                shl bx, 5
                add di, bx              
                
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



