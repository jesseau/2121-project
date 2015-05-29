.include "tools.asm"
.include "lcd.asm"

.set r13 = mode
.set r14 = minutes
.set r15 = seconds
.set r16 = temp1
.set r17 = temp2
.set r18 = temp3
.set r19 = temp4

.org 0x00
jmp RESET




RESET:



	jmp main

TIM0OVF:

TIM1OVF:

TIM2OVF:


main:
;setting the initial mode to entry
ldi temp1, 0
mov mode, temp1 
;doing some stuff before the main loop

;main loop => check what mode we're in, call function for that mode
;mode function returns when it is no longer the mode
mainloop:
	mov temp1, mode
	cpi temp1, 0	
	brne main_next1
	rcall entry_mode
	jmp mainloop
main_next1:
	cpi temp1, 1
	brne main_next2
	rcall running_mode
	jmp mainloop
main_next2:
	cpi temp1, 2
	brne main_next3
	rcall pause_mode
	jmp mainloop
main_next3:
	rcall finish_mode
	jmp mainloop

