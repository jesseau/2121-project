.include "m2560def.inc"
.include "tools_m.asm"
.include "lcd_m.asm"

.def pmode = r5
.def power = r6
.def row = r7
.def col = r8
.def rmask = r9
.def cmask = r10
.def pressed = r11
.def open = r12
.def mode = r13
.def minutes = r14
.def seconds = r15
.def temp1 = r16
.def temp2 = r17
.def temp3 = r18
.def temp4 = r19

.def dataL = r24
.def dataH = r25

.equ BUT1 = 0 ; e.g. use "andi temp, (1<<BUT1)" to check PB1 pressed
.equ BUT0 = 1

.equ ENTRYMODE = 0
.equ RUNNINGMODE = 1
.equ PAUSEMODE = 2
.equ FINISHMODE = 3

.dseg
tim0counter: .byte 2
turntcounter: .byte 2 ;stands for turntable counter
turntpos: .byte 1 ;turntable position
magcounter: .byte 1

.cseg
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

	ldi temp1, 0b00000000 ; initialise timer0
	out TCCR0A, temp1
	ldi temp1, 0b00000010
	out TCCR0B, temp1
	ldi temp1, (1<<TOIE0)
	sts TIMSK0, temp1

	clr temp1
	sts tim0counter, temp1
	sts tim0counter+1, temp1
	sts magnetroncounter, temp1
	sts magnetroncounter, temp1

	ldl mode, 0
	ldl minutes, 0
	ldl seconds, 0

	jmp main

TIM0OVF:
	pushall
	cpl mode, RUNNINGMODE ;check if in running mode
	breq tim0continue
	jmp tim0end

tim0continue:
;do the turntable first
	lds dataL, turntcounter
	lds dataH, turntcounter+1
	cpi dataL, LOW(1953)
	ldi temp1, HIGH(1953)
	cpc dataH, temp1
	breq mag_and_turn
	jmp nextcomp

mag_and_turn:

netxcomp: ;next comparison	
	lds dataL, tim0counter
	lds dataH, tim0counter+1	
	adiw dataH:dataL, 1	
	cpi dataL, LOW(7812)
	ldi temp1, HIGH(7812)
	cpc dataH, temp1
	breq nextsecond ; using reverse branching to prevent rjmp screwups
	;tim0counter has not counted to 1 second yet
	jmp tim0end
		
nextsecond: ;1 second has passed, so update the clock
	clr dataL ;set counter back to 0
	clr dataH
	cpl seconds, 0
	brne adjust_seconds
	cpl minutes, 0
	brne adjust_minutes
	jmp tim0end
adjust_minutes:
	dec minutes
	ldl seconds, 59
	jmp display_time
adjust_seconds:
	dec seconds	

display_time:
	print_time
	cpl seconds, 0
	brne tim0end
	cpl minutes, 0
	brne tim0end
	ldl mode, FINISHMODE

tim0end:
	sts tim0counter, dataL ;store counter from registers back into memory
	sts tim0counter+1, dataH
	popall
	reti

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
	rcall get_keypad
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

	ldl pmode, ENTRYMODE
	reti

running_mode:
	cpl pmode, ENTRYMODE
	brne rmodeContinue
	clr temp1
	sts tim0counter, temp1
	sts tim0counter+1, temp1	
	sts turntcounter, temp1
	sts turntcounter+1, temp1

rmodeContinue:
	ldl pmode, RUNNINGMODE
	reti
	
pause_mode:
	
	ldl pmode, PAUSEMODE
	reti

finish_mode:
	ldl pmode, FINISHMODE
	reti

end:
	rjmp end

.include "tools_f.asm"
.include "lcd_f.asm"
