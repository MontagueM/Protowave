#include <xc.inc>
    
global	KB_Setup, KB_main, RET_status
extrn	LCD_Write_Message, LCD_Setup, LCD_delay_ms
extrn	DAC_change_frequency
psect	udata_acs   ; reserve data space in access ram

KB_Val:ds 1
KB_Col:ds 1
KB_Row:ds 1
KB_Fin:ds 1
KB_Pressed: ds 1
KB_Fix: ds 1
RET_status:	ds 1

psect	data    
	; ******* myTable, data in programme memory, and its length *****
myTable:	
	db	'A','B','C','D','E','F','G','A','A','B','C','D','E','F','G','A'
	align	2
	
psect	kb_code,class=CODE
 	;goto	KB_Setup

	; ******* Programme FLASH read Setup Code ***********************
KB_Setup:	
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	movlw	3
	movwf	KB_Fix
	return

	; ******* Main programme ****************************************


KB_main:
	call    Acquire_Keypress
	call    Check_Key_Pressed
	movwf	RET_status, A
	movlw	0x0
	cpfseq	RET_status, 0
	return
	; If key pressed and is not prev key, continue
	call    Decode_Keypress
	call    Display_Keypress
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
	cpfsgt	KB_Col
	return
	
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
	; check KB_val is not zero
	movlw	0x00
	cpfsgt	KB_Col
	;retlw	0
	retlw	1
	
	; are we already pressed
	;movlw	0x00
	;cpfseq	KB_Pressed
	;retlw	0
	retlw	0
    
Decode_Keypress:
	; Set pressed
	movlw	0x01
	movwf	KB_Pressed
    
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
	
	;movlw	0x00
	;movwf	TRISH, A
	;movff	KB_Col, PORTH
	;movlw	0x00
	;movwf	TRISJ, A
	;movff	KB_Row, PORTJ
	
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
    	movf	KB_Fin, 0
	call	DAC_change_frequency
	return
    	; read the corresponding value
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	
	movf	KB_Fin, 0
	addwf	TBLPTRL, 1
	
	movlw	1
	call	LCD_Write_Message
	
	movf	KB_Fin, 0
	call	DAC_change_frequency
    return

    end