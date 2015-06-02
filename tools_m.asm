.macro stout
	.if @0 < 64
		out @0, @1
	.else
		sts @0, @1
.endmacro

.macro pushall
	push r16
	push r17
	push r18
	push r19
	push r20
	push r21
	push r22
	push r23
	push r24
	push r25
	push r26
	push r27
	push r28
	push r29
	push r30
	push r31
	in r16, SREG
	push r16
.endmacro

.macro popall
	pop r16
	out SREG, r16
	pop r31
	pop r30
	pop r29
	pop r28
	pop r27
	pop r26
	pop r25
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
.endmacro

.macro divide
	push @2
	clr @2
tools_loop:
	cp @0, @1
	brlo tools_result
	sub @0, @1
	inc @2
	rjmp loop
tools_result:
	mov @1, @0
	mov @0, @2
	pop @2
.endmacro

; load immediate to low registers, i.e. r0-r15 so that they're actually usable
.macro ldl
	push temp1
	ldi temp1, @1
	mov @0, temp1
	pop temp1
.endmacro

.macro cpl
	push temp1
	mov temp1, @0
	cpi temp1, @1
	pop temp1
.endmacro

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead
.equ PORTLDIR = 0xf0
.equ INITCOLMASK = 0xef
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0f
