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

                call set_resident

                __leave__

; ================== RESIDENT_FUNCTIONS ===================

; _________________________________________________________
; Setting custom 09h interrupt  
;    
; delete:
;       ax, bx, si, es
; _________________________________________________________
                
int9offset      equ 36d
int9segment     equ 38d

set_resident    proc 

                xor bx, bx 
                mov es, bx

                mov cx, es:[int9segment]
                mov bx, es:[int9offset]

                mov word ptr cs:[offset S410ffs41], bx 
                mov word ptr cs:[offset S41s4gme4n1], cx 

                cli 
                mov ax, cs
                mov es:[int9segment], ax
                mov es:[int9offset], offset int09chaining
                sti

                ret
                endp

; _________________________________________________________

; _________________________________________________________
; Chaining 09h interrupt  
; _________________________________________________________

SYSTEM_INFO     equ 40h
SPEC_KEYS_MEM   equ 17h

int09chaining   proc  

                push bx es ax 

                mov bx, SYSTEM_INFO
                mov es, bx
;;;;;;;;;;;;;; getting next buffer element ;;;;;;;;;;;;;;;;
                ; mov bx, es:[1ah]
;;;;;;;;;;;;;;;;;;; calculating previous ;;;;;;;;;;;;;;;;;;
                ; sub bx, 1eh
                ; add bx, 30d
                ; and bx, 31d
                ; add bx, 1eh
                ;
                ; mov bh, es:[bx]

                in al, 60h
                mov bl, al

                ; mov bh, es:[SPEC_KEYS_MEM]

                in al, 61h
                or al, 80h 
                out 61h, al 
                and al, not 80h
                out 61h, al 

;;;;;;;;;;;;;;;;;;; add overhead function  ;;;;;;;;;;;;;;;;

                cmp bl, 2ah
                jne @@not_interrupt_func
                pop ax es bx 
                call show_registers
                jmp @@skip
@@not_interrupt_func:
                pop ax es bx 
@@skip:

;;;;;;;;;;;;;;; jumping to original one ;;;;;;;;;;;;;;;;;;;

                __jump__ 
S410ffs41:      dw 0                                                   
S41s4gme4n1:    dw 0

                endp
                
; _________________________________________________________

; _________________________________________________________
; Show register information
; _________________________________________________________

; CURRENT STACK STATE: 
;
;|---------------------------------------- SP
;| IP_1 ???? <------- IP of calling's       | SP
;| IP   ???? <------- IP of interrupted     | SP + 4
;| CS   ???? <------- CS of interrupted     | SP + 6
;| FLAGS???? <------- FLAGS of interrupted  | SP + 8
; ??????????????????????????????????????????
; String register order 
;   ax bx cx dx si di bp sp es ds cs ss fr ip

show_registers:

                push ds si  

                push cs 
                pop ds  

                push bx ax bp
                call get_register_string
                pop bp ax bx

                push ax bx cx dx es di
                call set_string_all_registers
                mov si, di
                pop di es dx cx bx ax

                pusha 
                push di es 
                mov ax, ds 
                mov es, ax
                call show_register_frame
                pop es di
                popa

                pop si ds

                ret 

; _________________________________________________________

; ======================== HELPERS ========================

; _________________________________________________________
; Returns a string with registers of interrupted function 
; in the defined order.
;     
; args:
;              
;
; returns:
;       ds:si - ptr to register_vector
;
; delete:    
;       ax, bx, bp
; _________________________________________________________

; CURRENT STACK STATE: 
;
;---------------------------------------- SP
; IP_2 ???? <------- IP of calling's       | SP 
; AX   ????                                | SP + 2
; BX   ????                                | SP + 4
; BP   ????                                | SP + 6
; SI   ????                                | SP + 8
; DS   ???? <------- DS of interrupted     | sp + 10
; IP_1 ???? <------- IP of calling's       | SP + 12
; IP   ???? <------- IP of interrupted     | SP + 14
; CS   ???? <------- CS of interrupted     | SP + 16
; FLAGS???? <------- FLAGS of interrupted  | SP + 18
; ??????????????????????????????????????????
; Defined order:
;   ax bx cx dx si di bp sp es ds cs ss fr ip

DS_DST          equ 10
IP_DST          equ 14
CS_DST          equ 16
FL_DST          equ 18
REL_STACK_SIZE  equ 20
 
get_register_string:

;;;;;;;;;;;;;;;;;;;;; general pps ;;;;;;;;;;;;;;;;;;;;;;;;;

;               ax
                push bx
                xor bx, bx
                mov word ptr [bx + offset @@register_vector], ax

;               bx
                pop ax
                add bx, 2
                mov word ptr [bx + offset @@register_vector], ax

;               cx
                add bx, 2
                mov word ptr [bx + offset @@register_vector], cx

;               dx
                add bx, 2
                mov word ptr [bx + offset @@register_vector], dx
                
;;;;;;;;;;;;;;;;;; index and ptr reg ;;;;;;;;;;;;;;;;;;;;;;

;               si
                add bx, 2
                mov word ptr [bx + offset @@register_vector], si

;               di
                add bx, 2
                mov word ptr [bx + offset @@register_vector], di

;               bp
                add bx, 2
                mov word ptr [bx + offset @@register_vector], bp

;               sp
                add bx, 2
                mov ax, sp 
                add ax, REL_STACK_SIZE
                mov word ptr [bx + offset @@register_vector], ax

;;;;;;;;;;;;;;;;;;;;;;; segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;

;               es
                add bx, 2
                mov word ptr [bx + offset @@register_vector], es

                mov bp, sp
;               ds
                add bx, 2
                mov ax, ss:[bp +  DS_DST]
                mov word ptr [bx + offset @@register_vector], ax

;               cs
                add bx, 2
                mov ax, ss:[bp + CS_DST]
                mov word ptr [bx + offset @@register_vector], ax

;               ss
                add bx, 2
                mov word ptr [bx + offset @@register_vector], ss

;;;;;;;;;;;;;;;;;;;;;;; crucial ;;;;;;;;;;;;;;;;;;;;;;;;;;;

;               flag register
                add bx, 2
                mov ax, ss:[bp + FL_DST]
                mov word ptr [bx + offset @@register_vector], ax

;               ip 
                add bx, 2
                mov ax, ss:[bp + IP_DST]
                mov word ptr [bx + offset @@register_vector], ax

                mov si, offset @@register_vector

                ret
                
.data
@@register_vector   dw 14 dup (0)   
.code

; _________________________________________________________

; _________________________________________________________
; Prints register in es:di mmb 
;     
; args:
;       bx - register which will be printed 
;       es:di - ptr to destination string
;
; delete:    
;       ax, cx, di, si
; _________________________________________________________

last_4b_mask    equ 000Fh

print_register:

                std
                add di, 4
                xor cx, cx

@@loop:
                mov ax, bx
                shr ax, cl
                and ax, last_4b_mask
                xchg ax, bx
                mov bl, ds:[offset @@symbol_array + bx] 
                xchg ax, bx
                stosb

                add cx, 4
                cmp cx, 16
                jb @@loop
                
                ret 

.data 
@@symbol_array  db "0123456789ABCDEF"          
.code

; _________________________________________________________
; Prints all registers
;     
; args:
;       ds:si - ptr to register_vector
;
; returns:
;       ds:di - string to print
;       
; delete:
;       ax, bx, cx, dx, si, es                                      
; _________________________________________________________

REGISTER_NUMBER equ 14
REG_LINE_LENTH  equ 8

set_string_all_registers: 

                mov dx, cs
                mov es, dx

                xor dx, dx
                mov di, offset @@register_string + 2

                cld
                
@@loop:
                lodsw
                mov bx, ax 

                call print_register       
                cld

                add di, REG_LINE_LENTH
                inc dx 
                cmp dx, REGISTER_NUMBER
                jne @@loop

                mov di, offset @@register_string

                ret 

.data 
@@register_string:
;;;;;;;;;;;;;;;; General purpose registers ;;;;;;;;;;;;;;;;
                        db "AX=0000#"
                        db "BX=0000#"
                        db "CX=0000#"
                        db "DX=0000#"
;;;;;;;;;;;;;;;; Index and pointer registers ;;;;;;;;;;;;;;
                        db "SI=0000#"
                        db "DI=0000#"
                        db "BP=0000#"
                        db "SP=0000#"
;;;;;;;;;;;;;;;;;;;;; Segment registers ;;;;;;;;;;;;;;;;;;;
                        db "ES=0000#"
                        db "DS=0000#"
                        db "CS=0000#"
                        db "SS=0000#"
;;;;;;;;;;;;;;;;;;;;; Crucial registers ;;;;;;;;;;;;;;;;;;;
                        db "FR=0000#"
                        db "IP=0000#"
STRING_LENGTH           equ $ - @@register_string
.code                                                    

; ========================= FRAME =========================

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

; ========================================================

.data 
FRAME_STYLE     rect_style <BG_WHITE, BG_RED, BG_WHITE>        
FRAME_FILLING   rect_filling <6,5,6,5,32,5,6,5,6>

; ======================= FUNCTIONS ========================

.code

; ========================= MAIN ==========================

; _________________________________________________________
; Draws frame with register values
; args: 
;       es:si - input string
; delete 
;       all  
; _________________________________________________________

show_register_frame:

                mov cx, STRING_LENGTH

                push si cx
                mov di, si

                call get_size  

                push cx
                call calculate_left_up_corner
                pop cx

                push bx cx di
                call draw_frame

                pop di cx si
                call write_text_centered
                
                ret

; _________________________________________________________

; ==================== STRING FUNCTION ====================

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

FILE_LENGTH:

end             __start__
