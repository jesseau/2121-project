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

get_keypad:
	ldi cmask, INITCOLMASK
	clr col
	cpi pressed, 1
	brne keypad_colloop
debouncer:
	clr temp1
	out PORTC, temp1
	lds temp1, PINL
	nop
	andi temp1, ROWMASK
	brne debouncer
	clr pressed
	jmp get_keypad

keypad_colloop:
	cpi col, 4
	breq end_keypad
	sts PORTL, cmask

	rcall sleep_20ms
	ldi rmask, INITROWMASK
	clr row

keypad_rowloop:
	cpl row, 4
	breq _keypad_nextcol
	jmp keypad_rowloop_cont
_keypad_nextcol:
	jmp keypad_nextcol
keypad_rowloop_cont:
	mov temp2, temp1
	and temp2, rmask
	breq keypad_store
	inc row
	lsl rmask
	jmp keypad_rowloop

keypad_nextcol:
	lsl cmask
	inc col
	jmp keypad_colloop

keypad_store:
	; so we have the required row = ? and col = ? data...
	nop

end_keypad:
	ret
