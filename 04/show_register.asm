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
                shr dx, 4
                inc dx
                int 21h
             endm

__jump__    macro 
                db 0eah 
            endm

; ========================= MAIN ==========================

__start__:

                call set_resident

                int 09h

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

int09chaining   proc  

                push bx es ax 

                mov bx, 40h
                mov es, bx
;;;;;;;;;;;;;; getting next buffer element ;;;;;;;;;;;;;;;;
                mov bx, es:[1ah]
;;;;;;;;;;;;;;;;;;; calculating previous ;;;;;;;;;;;;;;;;;;
                sub bx, 1eh
                add bx, 30d
                and bx, 31d
                add bx, 1eh

                mov ax, es:[bx]
                mov ah, 4ch
;;;;;;;;;;;;;;;;;;; add overhead function  ;;;;;;;;;;;;;;;;

                pop ax es bx 

                push ds
                call show_registers
                pop ds

;;;;;;;;;;;;;;; jumping to original one ;;;;;;;;;;;;;;;;;;;

                __jump__ 
S410ffs41:      dw 0                                                   
S41s4gme4n1:    dw 0

                endp
                
; _________________________________________________________

; _________________________________________________________
; Show register information
;
; expects: 
;       pushed ds of interrupted programm
; delete:
;       ds       
; _________________________________________________________

; CURRENT STACK STATE: 
;
;|---------------------------------------- SP
;| IP_1 ???? <------- IP of calling's       | SP
;| DS   ???? <------- DS of interrupted     | sp + 2
;| IP   ???? <------- IP of interrupted     | SP + 4
;| CS   ???? <------- CS of interrupted     | SP + 6
;| FLAGS???? <------- FLAGS of interrupted  | SP + 8
; ??????????????????????????????????????????
; String register order 
;   ax bx cx dx si di bp sp es ds cs ss fr ip

show_registers:

                push bp bx ax
                call get_register_string
                pop ax bx bp
                ; call set_string_all_registers
                ; call draw_box 

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
;       ds
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
; IP_1 ???? <------- IP of calling's       | SP + 8
; DS   ???? <------- DS of interrupted     | sp + 10
; IP   ???? <------- IP of interrupted     | SP + 12
; CS   ???? <------- CS of interrupted     | SP + 14
; FLAGS???? <------- FLAGS of interrupted  | SP + 16
; ??????????????????????????????????????????
; Defined order:
;   ax bx cx dx si di bp sp es ds cs ss fr ip

DS_DST          equ 10
IP_DST          equ 12
CS_DST          equ 14
FL_DST          equ 16

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
                add ax, 18
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

                ret
                
.data
@@register_vector   dw 14 dup (0)   
.code

; _________________________________________________________

; _________________________________________________________
; Prints register in es:di mmb 
;     
; args:
;       ax - register which will be printed 
;       es:di - ptr to distanation string
;
; delete:    
;       ax, cx
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
;
; delete:
;       ax, cx
; _________________________________________________________

set_string_all_registers: 

            
                call print_register         

                


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
.code                                                    

FILE_LENGTH:

end             __start__
