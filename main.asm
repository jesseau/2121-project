.include "m2560def.inc"
.include "tools_m.asm"
.include "lcd_m.asm"

.def enterpl = r2 ; boolean flag for power level insertion mode
.def numpressed = r3 ; for entry mode, how many digits have been pressed so far
.def ttpos = r4 ;turntable position
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
.def dir= r20 ; stands for direction

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

	ldi dir, 1
	
	clr temp1
	sts tim0counter, temp1
	sts tim0counter+1, temp1
	sts magnetroncounter, temp1
	sts magnetroncounter, temp1

	ldl ttpos, 0
	ldl mode, ENTRYMODE
	ldl minutes, 0
	ldl seconds, 0
	ldl pressed, 0

;initialise lcd
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001111 ; Cursor on, bar, no blink
	make_backslash

;test backslash
	do_lcd_command 0b10000000
	do_lcd_data_im 0

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
;do the mag/turntable first
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
	add ttpos, dir
	cpl ttpos, 0 ; check for underflow
	brge turntable_check_of
	ldl ttpos, 3
turntable_check_of:
	cpl ttpos, 4
	brlt mag_and_turn_end
	ldl ttpos, 0

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



main:

;main loop => check what mode we're in, call function for that mode
;mode function returns when it is no longer the mode
mainloop:
	rcall get_input
	cpl open, 1
	brne main_normal_input
	cpi result, BUT0PRESSED
	brne main_no_input
	ldl open, 0
	jmp main_mode_check
main_no_input:
	ldi result, BUT1PRESSED
	jmp main_mode_check
main_normal_input:
	cpi result, BUT1PRESSED
	brne main_mode_check
	ldl open, 1
	
main_mode_check:
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


.include "entry.asm"
.include "running.asm"
.include "pause.asm"
.include "finish.asm"

.include "tools_f.asm"
.include "lcd_f.asm"
