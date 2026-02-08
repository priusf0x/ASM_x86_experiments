.model tiny 
.code
org 100h

include include/my_lib.asm

_exit 	macro 
		mov ah, 4ch
		int 21h
	endm

EOL 	equ "$"

; =========================================================
 
_start: 
		_exit 

; ====================== FUNCTIONS ========================

state_machine:
	.data
	align 2
	.states:
		dd $
		dd $
	align 2		
	.text:
		db "В целом сойдет",  EOL		

end		_start