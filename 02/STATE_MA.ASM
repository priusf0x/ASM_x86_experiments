.model tiny 
.code
org 100h

; ======================= DEFINES =========================

__exit__ macro  
		mov ah, 4ch
		int 21h
	 endm

EOL 	equ "$"

; uses dx ah
PRINT macro string  
	lea dx, [string]
	mov ah, 09h 
	int 21h 		
      endm


; uses dl ah al
GETCH macro  
	mov ah, 08h
	int 21h
      endm

CYAN  equ 1bh, "[36m"
RED   equ 1bh, "[31m"
GREEN equ 1bh, "[32m"
WHITE equ 1bh, "[37m"
; ========================= MAIN ==========================
 
_start: 
		call hello_message
		call state_machine 
		__exit__ 

; ====================== FUNCTIONS ========================

hello_message:
	PRINT .hello_message
	.data 
.hello_message: 	db CYAN, "Привет, бразе, это моя базовая ",\
			"задача Дербышева.", 0ah, WHITE, EOL
	.code
	ret

ask_user:
	PRINT .ask_msg	

	.data 
	.ask_msg: 	db "Выбери одну любимое пиво:", 02h, 0ah,\
				   "0)Ливаем", 0ah,\
				   "1)Пшеничное", 0ah,\
				   "2)Берлинское", 0ah,\
				   "3)Лидское", 0ah, WHITE, EOL
	.code

	ret

state_machine:

.repeat: 
	call ask_user
	GETCH 
	jz .leave			; LEAVE IF EMPTY
	sub al, 48 			; CONVERSATION TO NUMBER
	mov bl, [.msg_count]	
	cmp al, bl			; CHECK IF CORRECT
	jbe .err_skip			; LEAVE IF INCORRECT
	PRINT .err_msg
	jmp .repeat		
.err_skip:
	test al, al			; ZERO TEST
	jz .leave			; LEAVE BY DEFAULT

	xor bx, bx
	mov bl, al
	shl bl, 1	
	mov dx, [bx + offset .states]
	mov ah, 09h
	int 21h

	jmp .repeat 

	.leave:
		PRINT .exit_msg 
		ret 

	.data
	align 2
.states:
		dw .exit_msg 	
		dw .pshenichnoe
		dw .berlinskoe
		dw .lidskoe 
.msg_count 	db 3

.text:
.err_msg 	db RED, "Неправильное значение!", 0ah, WHITE, EOL
.exit_msg	db "Все пока!", 0ah, EOL
.pshenichnoe	db "В целом сойдет", 0ah, EOL
.berlinskoe 	db RED, "Фууууууу!", 0ah, WHITE, EOL
.lidskoe 	db GREEN, "Наш слон.", 0ah, WHITE, EOL 
	.code 	

end		_start
