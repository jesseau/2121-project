sleep_1ms:
	pushall	
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	popall
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret

sleep_20ms:
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	ret

sleep_100ms:
	rcall sleep_20ms
	rcall sleep_20ms
	rcall sleep_20ms
	rcall sleep_20ms
	rcall sleep_20ms
	ret

sleep_500ms:
	rcall sleep_100ms
	rcall sleep_100ms
	rcall sleep_100ms
	rcall sleep_100ms
	rcall sleep_100ms
	ret

; ---------------------------------------------------------
; get_input - returns the number on the keypad, otherwise the ASCII
; value of the letter/symbol pressed. also returns pushbuttons
get_input:
	ldl cmask, INITCOLMASK
	clr col
	cpl pressed, 1
	brne keypad_colloop

keypad_debouncer:
	lds temp1, PINL
	nop
	andi temp1, ROWMASK
	cpi temp1, ROWMASK
	brne keypad_debouncer
	clr pressed
	jmp get_input

keypad_colloop:
	cpl col, 4
	breq get_input
	sts PORTL, cmask

	rcall sleep_5ms

	lds temp1, PINL
	nop
	andi temp1, ROWMASK
	breq keypad_nextcol

	ldl rmask, INITROWMASK
	clr row

keypad_rowloop:
	cpl row, 4
	breq keypad_nextcol
	mov temp2, temp1
	and temp2, rmask
	breq keypad_parse
	inc row
	lsl rmask
	jmp keypad_rowloop

keypad_nextcol:
	lsl cmask
	sbrl cmask, 1 ; pull resistor up
	inc col
	jmp keypad_colloop

keypad_parse:
	ldl pressed, 1
	cpl col, 3
	breq keypad_letters
	cpl row, 3
	breq keypad_symbols
	mov temp1, row
	lsl temp1
	add temp1, row
	add temp1, col
	subi temp1, -1
	jmp keypad_store

keypad_letters:
	ldi temp1, 'A'
	add temp1, row
	jmp keypad_store

keypad_symbols:
	cpl col, 0
	breq keypad_star
	cpl col, 1
	breq keypad_zero
	ldi temp1, '#'
	jmp keypad_store

keypad_star:
	ldi temp1, '*'
	jmp keypad_store

keypad_zero:
	clr temp1

keypad_store:
	mov result, temp1 ; global var for determining what was pressed

keypad_end:
	inc r4
	out PORTC, result
	rcall sleep_5ms
	ret
