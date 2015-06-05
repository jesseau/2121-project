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
.def dir = r20 ; stands for direction
.def fadedir = r21 ; fade direction for backlight (advanced feature)
.def beepcount = r22
.def iskeypad = r23

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

.equ INCREASING = 1
.equ DECREASING = 0

.dseg
tim0counter: .byte 2
tim3counter: .byte 2
tim4counter: .byte 1
turntcounter: .byte 2 ;stands for turntable counter
turntpos: .byte 1 ;turntable position
magcounter: .byte 1
pausetype: .byte 1
displaycounter: .byte 2
turntable_counter: .byte 1

.cseg
.org 0x00
	jmp RESET
.org OVF1addr
	jmp TIM1OVF
.org OVF0addr
	jmp TIM0OVF
.org OVF3addr
	jmp TIM3OVF
.org OVF4addr
	jmp TIM4OVF

DEFAULT:
	reti

RESET:	
	cli
	ldi temp1, high(RAMEND) ; initialise stack pointer
	out SPH, temp1
	ldi temp1, low(RAMEND)
	out SPL, temp1

	ldi temp1, PORTLDIR ; initialise keypad
	sts DDRL, temp1
	ldi temp1, ROWMASK
	sts PORTL, temp1

	ldi temp1, 1<<3
	stout DDRB, temp1
	cbi PORTB, 3

	ser temp1 ; initialise LEDs (debug)
	out DDRC, temp1
	out PORTC, temp1

	ser temp1 ; initialise LCD
	out DDRF, temp1
	out DDRA, temp1
	clr temp1
	out PORTF, temp1
	out PORTA, temp1

	ldi temp1, (1<<DDE4)|(1<<DDE5) ; initialise motor and BL
	out DDRE, temp1

	ldi temp1, 0 ; initialise timer0
	out TCCR0A, temp1
	ldi temp1, (1<<CS01)
	out TCCR0B, temp1
	ldi temp1, (1<<TOIE0)
	sts TIMSK0, temp1
	
	ldi temp1, 254
	sts OCR3BL, temp1
	clr temp1
	sts OCR3CH, temp1

	ldi temp1, (1<<WGM30)|(1<<COM3C1)
	sts TCCR3A, temp1
	ldi temp1, (1<<CS32) ; 256 prescaler
	sts TCCR3B, temp1
	ldi temp1, (1<<OCIE3C) ; enable cp interrupt
	sts TIMSK3, temp1

	ldi dir, 1
	
	ldi temp1, (1<<PH5) ; initialise sound - OCR4C
	sts DDRH, temp1

	clr temp1
	sts OCR4CL, temp1
	sts OCR4CH, temp1

	ldi temp1, (1<<WGM40)|(1<<COM4C1)
	sts TCCR4A, temp1
	ldi temp1, (1<<CS42) ; 256 prescaler
	sts TCCR4B, temp1

	clr temp1
	sts tim0counter, temp1
	sts tim0counter+1, temp1
	sts tim3counter, temp1
	sts tim3counter+1, temp1
	sts tim4counter, temp1
	sts magcounter, temp1
	sts displaycounter, temp1
	sts displaycounter+1, temp1

	clr iskeypad
	ldl fadedir, INCREASING
	ldl ttpos, 0
	ldl open, 0
	ldl mode, ENTRYMODE
	ldl minutes, 0
	ldl seconds, 0
	ldl pressed, 0
	ldl pmode, FINISHMODE

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
	do_lcd_command 0b00001100 ; Cursor on, bar, no blink
	make_backslash

;test backslash
	;do_lcd_command 0b10000000
	;do_lcd_data_im 0
	;ldi temp1, 0b10101010
	;out PORTC, temp1
	sei
	jmp main

TIM0OVF:
	pushall
	lds dataL, displaycounter
	lds dataH, displaycounter+1
	adiw dataH:dataL, 1
	cpi dataL, LOW(1953)
	ldi temp1, HIGH(1953)
	cpc dataH, temp1
	brne timer_displaycont
	clr dataL
	clr dataH
	rcall display_turnt
	rcall display_open
	rcall display_power
timer_displaycont:
	sts displaycounter, dataL
	sts displaycounter+1, dataH

	cpl mode, RUNNINGMODE ;check if in running mode
	breq tim0continue
	cbi PORTE, 4 ; disable motor
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
	cp temp1, power
	brlt motoron

;motor turns off
	cbi PORTE, 4
	jmp postmotor
motoron:
;motor turns on
	sbi PORTE, 4

postmotor:
	;do_lcd_command 0b11000000
	;do_lcd_data_im 'P'
	inc temp1
	cpi temp1, 4
	brlt update_mag
	clr temp1
update_mag:
	sts magcounter, temp1

turntable:
	lds temp3, turntable_counter
	inc temp3
	cpi temp3, 10
	brlt turntable_end
	clr temp3
	add ttpos, dir
	cpl ttpos, 0 ; check for underflow
	brge turntable_check_of
	ldl ttpos, 3
turntable_check_of:
	cpl ttpos, 4
	brlt turntable_end
	ldl ttpos, 0

turntable_end:
	sts turntable_counter, temp3
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
	start_beeper
	do_lcd_command 0b10000000
	do_lcd_data_im 'D'
	do_lcd_data_im 'o'
	do_lcd_data_im 'n'
	do_lcd_data_im 'e'
	do_lcd_data_im ' '
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
	reti

TIM3OVF:
	pushall
tim3_loop:
	lds temp1, OCR3CL
	cpl fadedir, INCREASING
	breq fade_increasing
	cpl fadedir, DECREASING
	breq fade_decreasing
fade_decreasing:
	cpi temp1, 0
	breq TIM3CONT
	subi temp1, 2
	sts OCR3CL, temp1
	jmp TIM3CONT
fade_increasing:
	cpi temp1, 254
	breq TIM3CONT
	subi temp1, -2
	sts OCR3CL, temp1

TIM3CONT:
	cpl mode, RUNNINGMODE
	breq running_ignore

	lds dataL, tim3counter
	lds dataH, tim3counter+1
	adiw dataH:dataL, 1
	cpi dataL, low(2460) ; use 2460 for 10 seconds later
	ldi temp1, high(2460)
	cpc dataH, temp1
	brne TIM3END

	ldl fadedir, DECREASING

running_ignore:
	clr temp1
	mov dataL, temp1
	mov dataH, temp1

TIM3END:
	sts tim3counter, dataL
	sts tim3counter+1, dataH
	popall
	reti

TIM4OVF:
	pushall
	lds temp1, tim4counter
	cpi temp1, 30 ; 250ms counter for keypad press
	breq stop_keypad_beep
	cpi temp1, 122 ; 1 second counter for beeper
	brne TIM4CONT ; it's not a second yet, so count up and do nothing
	cpi beepcount, 4 ; if we're here at the 4th iteration, then stop the beeping, i.e. only 3 iterations are completed
	brlt ignore_beeper
turn_beeper_off:
	clr beepcount
	stop_beeper
	jmp TIM4CONT
stop_keypad_beep:
	cpi iskeypad, 1
	brne TIM4CONT
	clr iskeypad
;	cpi temp1, 31 ; if we have a counter higher than 30, then that shouldn't break the existing finished beep
;	brge TIM4CONT
	stop_beeper
	jmp TIM4END
ignore_beeper:
	inc beepcount
	clr temp1 ; reset the 1 second counter
	sts tim4counter, temp1
	lds temp2, OCR4CL
	cpi temp2, 0
	breq beeper_off
	cpi temp2, 255
	breq beeper_on
beeper_on:
	clr temp2
	sts OCR4CL, temp2
	jmp TIM4END
beeper_off:
	ser temp2
	sts OCR4CL, temp2
	jmp TIM4END
TIM4CONT:
	inc temp1
	sts tim4counter, temp1
TIM4END:
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
	;out portc, result
	cpi result, BUT1PRESSED
	brne main_mode_check
	ldl open, 1
	
main_mode_check:
	;out portc, result
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
