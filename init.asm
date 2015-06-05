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
	sbi PORTB, 1
	sbi PORTB, 0

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
