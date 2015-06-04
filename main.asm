.include "m2560def.inc"
.include "tools_m.asm"
.include "lcd_m.asm"

.def printed = r4
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
.def result = r19
.def direction = r20

.def dataL = r24
.def dataH = r25

.equ BUT1 = 0 ; e.g. use "andi temp, (1<<BUT1)" to check PB1 pressed
.equ BUT0 = 1
.equ BUT1PRESSED = 0xF0
.equ BUT0PRESSED = 0x0F

.equ ENTRYMODE = 0
.equ RUNNINGMODE = 1
.equ PAUSEMODE = 2
.equ FINISHMODE = 3

.dseg
tim0counter: .byte 2
turntcounter: .byte 2 ;stands for turntable counter
turntpos: .byte 1 ;turntable position
magcounter: .byte 1
pausetype: .byte 1

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

	ldi temp1, (1<<DDE4) ; initialise motor at PE2 (OCR3B)
	out DDRE, temp1

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

	ldl mode, ENTRYMODE
	ldl minutes, 0
	ldl seconds, 0
	ldl pressed, 0

	clr r4

	jmp main

TIM0OVF:
	pushall
	rcall display_turnt
	rcall display_open
	cpl mode, RUNNINGMODE ;check if in running mode
	breq tim0continue
	jmp tim0end

tim0continue:
;do the turntable first
	lds dataL, turntcounter
	lds dataH, turntcounter+1
	adiw dataH:dataL, 1
	cpi dataL, LOW(1953)
	ldi temp1, HIGH(1953)
	cpc dataH, temp1
	breq mag_and_turn
	jmp mag_and_turn_end

mag_and_turn:
	clr dataL
	clr dataH
	lds temp1, magcounter
	cp temp1, pow
	brge motoron
;motor turns off

	jmp postmotor
motoron:
;motor turns on

postmotor:
	inc temp1
	cpi temp1, 4
	brlt turntable
	subi temp1, 4
	sts magcounter, temp1

turntable:
	

mag_and_turn_end:
	sts turntcounter, dataL
	sts turntcounter+1, dataH	

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
	jmp display_time
adjust_minutes:
	dec minutes
	ldl seconds, 59
	jmp display_time
adjust_seconds:
	dec seconds	

display_time:
	print_time
	cpl seconds, 0
	breq comp_minutes
	jmp tim0end
comp_minutes:
	cpl minutes, 0
	breq change_finish_mode
	jmp tim0end

change_finish_mode:
	ldl mode, FINISHMODE
	do_lcd_command 0b10000000
	do_lcd_data_im 'D'
	do_lcd_data_im 'o'
	do_lcd_data_im 'n'
	do_lcd_data_im 'e'
	do_lcd_command 0b11000000 ; set cursor to second line
	do_lcd_data_im 'R'
	do_lcd_data_im 'e'
	do_lcd_data_im 'm'
	do_lcd_data_im 'o'
	do_lcd_data_im 'v'
	do_lcd_data_im 'e'
	do_lcd_data_im ' '
	do_lcd_data_im 'F'
	do_lcd_data_im 'o'
	do_lcd_data_im 'o'
	do_lcd_data_im 'd'

tim0end:
	sts tim0counter, dataL ;store counter from registers back into memory
	sts tim0counter+1, dataH
	popall
	reti

TIM1OVF:

TIM2OVF:


main:
;doing some stuff before the main loop

;main loop => check what mode we're in, call function for that mode
;mode function returns when it is no longer the mode
mainloop:
	rcall get_input
	cpi result, BUT1PRESSED
	brne main_continue
	ldl open, 1
	; change flag for open or closed state	

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
	ret

running_mode:
	cpl pmode, ENTRYMODE
	brne running_continue
	clr temp1
	sts tim0counter, temp1
	sts tim0counter+1, temp1	
	sts turntcounter, temp1
	sts turntcounter+1, temp1

running_continue:
	cpi result, '*'
	brne running_checkC
	inc minutes
running_checkC:
	cpi result, 'C'
	brne running_checkD
	ldi temp, 30
	add seconds, 30	
running_checkD:
	cpi result, 'D'
	brne running_seconds_of
	ldi temp, 30
	sub seconds, 30	

running_seconds_of:
	cpl seconds, 61
	brlt running_seconds_uf
	inc minutes
	ldi temp1, 60
	sub seconds, temp1
	cpl seconds, 61
	brlt running_seconds_uf
	inc minutes
	ldi temp1, 60
	sub seconds, temp1
	
running_seconds_uf:
	cpl seconds, 0
	brge running_minutes_of
	dec minutes
	ldi temp1, 60
	add seconds, temp1
	
running_minutes_of:
	cpl minutes, 100
	brlt running_minutes_uf
	ldl minutes, 99

running_minutes_uf:
	cpl minutes, 0
	brge running_mode_end
	ldl minutes, 0
	ldl seconds, 0	

running_mode_end:
	ldl pmode, RUNNINGMODE
	ret
	
pause_mode:
	lds temp1, pausetype
	cpi pausetype, 1
	brne pause_button_press
	cpl open, 0	
	brne pause_mode_end
	ldl mode, RUNNINGMODE
	jmp pause_mode_end

pause_button_press:
	cpi result, '*'
	brne pause_mode_end
	ldl mode, RUNNINGMODE	 

pause_mode_end:
	ldl pmode, PAUSEMODE
	ret

finish_mode:
	cpl printed, 1
	brne printMessage
	jmp fmode_checkbuttons
printMessage:
	ldl printed, 1

fmode_checkbuttons:
	cpi result, BUT1PRESSED
	brne fmode_nextcheck
	do_lcd_command 0b00000001
	ldl mode, ENTRYMODE
fmode_nextcheck:
	cpi result, '#'
	brne fmode_finish
	do_lcd_command 0b00000001
	ldl mode, ENTRYMODE

fmode_finish:
	ldl pmode, FINISHMODE
	ret

.include "tools_f.asm"
.include "lcd_f.asm"
