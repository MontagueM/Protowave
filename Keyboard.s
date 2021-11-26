#include <xc.inc>
    
global	KB_Setup
extrn	LCD_Write_Message, LCD_Setup
    
psect	udata_acs   ; reserve data space in access ram

myTable__1:ds 1
KB_Val:ds 1
KB_Col:ds 1
KB_Row:ds 1
KB_Fin:ds 1
KB_Pressed: ds 1
KB_Fix: ds 1
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
RET_status:	ds 1
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data    
	; ******* myTable, data in programme memory, and its length *****
myTable:	
	db	'1','2','3','F','4','5','6','E','7','8','9','D','A','0','B','C'
	myTable_l   EQU	16	; length of data
	align	2
	
psect	code, abs	
rst: 	org 0x0
 	;goto	KB_Setup

	; ******* Programme FLASH read Setup Code ***********************
KB_Setup:	
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	movlw	3
	movwf	KB_Fix
	call	LCD_Setup
	goto	KB_init

	; ******* Main programme ****************************************

KB_SetNotPressed:
    	movlw	0x0
	movwf	KB_Pressed, A
	return

KB_init:
	call	KB_SetNotPressed
KB_loop:
	call    Acquire_Keypress
	;call    Check_Key_Pressed
	;movwf	RET_status
	;decfsz	RET_status
	; If key pressed and is not prev key, continue
	call    Decode_Keypress
	;call    Display_Keypress
	goto	KB_loop
	return
    
Acquire_Keypress:
	movlw	0
	movwf	KB_Row
	movlw	0
	movwf	KB_Col
	
    
	banksel PADCFG1
	bsf	REPU
	clrf	LATE, A
	banksel	0  ; we need this to put default bank back to A
	
	movlw	0x0F
	movwf	TRISE
	
	; delay?
	movlw	1
	call	LCD_delay_ms
	
	; Drive output bits low all at once
	movlw	0x00
	movwf	PORTE, A
	
	; Read 4 PORTE input pins
	movff 	PORTE, KB_Col

	; Invert the pins to show only the pressed ones
	movlw	0x0F
	xorwf	KB_Col, 1
	
	; If no column pressed return
	movlw	0x00
	cpfsgt	KB_Col, A
	goto	KB_init
	
	; Configure bits 0-3 output, 4-7 input
	movlw	0xF0
	movwf	TRISE
	
	movlw	1
	call	LCD_delay_ms
	
	; Drive output bits low all at once
	movlw	0x00
	movwf	PORTE, A
	
	
	; Read4 PORTE input pins
	movff 	PORTE, KB_Row
	swapf	KB_Row, 1
	movlw	0x0F
	xorwf	KB_Row, 1


	return

Check_Key_Pressed:
	; check KB press is not zero
	;movlw	0x00
	;cpfsgt	KB_Row
	;bra	KB_init

	; are we already pressed
	movlw	0x00
	cpfseq	KB_Pressed, A
	bra	KB_loop
	
	; If not, set pressed
	movlw	0x01
	movwf	KB_Pressed
	return
    
Decode_Keypress:
    	; Decode results to determine
	; Print results to PORTD
	
	; starts at 1, need to start at 0
	bcf     STATUS, 0
	rrcf	KB_Col, 1
	bcf     STATUS, 0
	rrcf	KB_Row, 1
	
	; Fix if value is 4, needs to be 3
	movlw	4
	cpfslt	KB_Row
	movff	KB_Fix, KB_Row
	movlw	4
	cpfslt	KB_Col
	movff	KB_Fix, KB_Col
	
	movlw	0x00
	movwf	TRISH, A
	movff	KB_Col, PORTH
	movlw	0x00
	movwf	TRISJ, A
	movff	KB_Row, PORTJ
	
	; KB_Col + 4 * KB_Row
	movf	KB_Row, 0
	addwf	KB_Row, 0
	addwf	KB_Row, 0
	addwf	KB_Row, 0
	bcf     STATUS, 0
	addwfc	KB_Col, 0
	movwf	KB_Fin, A
    return
    
Display_Keypress:
	;return
    	; read the corresponding value
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	
	movf	KB_Fin, 0
	addwfc	TBLPTRL, 0
	movwf	TBLPTRL, A
	
	movlw	1
	lfsr	2, myArray
	call	LCD_Write_Message
    return
    
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

    end