.include "m2560def.inc"
.include "tools_m.asm"
.include "lcd_m.asm"

.def open = r12
.def mode = r13
.def minutes = r14
.def seconds = r15
.def temp1 = r16
.def temp2 = r17
.def temp3 = r18
.def temp4 = r19

.equ PORTLDIR = 0xf0
.equ INITCOLMASK = 0xef
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0f
.equ BUT1 = 0 ; e.g. use "andi temp, (1<<BUT1)" to check PB1 pressed
.equ BUT0 = 1

.org 0x00
	jmp RESET
	jmp DEFAULT ; for now

DEFAULT:
	reti

RESET:
	ldi temp1, high(RAMEND) ; initialise stack pointer
	out SPH, temp1
	ldi temp1, low(RAMEND)
	out SPL, temp1

	ldi temp1, PORTLDIR ; initialise keypad
	sts DDRL, temp1
	ldi temp1, ROWMASK
	sts PORTL, temp1

	ser temp1 ; initialise LEDs (debug)
	out DDRC, temp1
	out PORTC, temp1

	ser temp1 ; initialise LCD
	out DDRF, temp1
	out DDRA, temp1
	clr temp1
	out PORTF, temp1
	out PORTA, temp1

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
	;rcall running_mode
	jmp mainloop
main_next2:
	cpi temp1, 2
	brne main_next3
	;rcall pause_mode
	jmp mainloop
main_next3:
	;rcall finish_mode
	jmp mainloop

entry_mode:

end:
	rjmp end

.include "tools_f.asm"
.include "lcd_f.asm"
