#include <xc.inc>
	
global	DAC_Setup, DAC_Int_Hi, DAC_change_frequency
    
psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage
Freq_counter:   ds 1
DAC_freq_index: ds 1
psect	udata_bank4
scaleArray:    ds 0x40 ; reserve 128 bytes for message data

psect data
 
scaleTable:	
	db	0x1b, 0x01
	db	0xfc, 0x00
	db	0xee, 0x00
	db	0xd3, 0x00
	db	0xbc, 0x00
	db	0xb1, 0x00
	db	0xa8, 0x00
	db	0xa8, 0x00
	db	0x1b, 0x01
	db	0xfc, 0x00
	db	0xee, 0x00
	db	0xd3, 0x00
	db	0xbc, 0x00
	db	0xb1, 0x00
	db	0xa8, 0x00
	db	0xa8, 0x00
	scaleTable_l   EQU	32	; length of data
	align	2
    
psect	dac_code, class=CODE
	
DAC_Int_Hi:	
	btfss	CCP4IF		; check that this is ccp timer 4 interrupt
	retfie	f		; if not then return
	bcf	CCP4IF	        ; clear the CCP4IF flag

DAC_Loop:
	incf	LATJ, F, A	; increment PORTJ
	incf	LATJ, F, A
	; Set CS* and WR* low
	movlw	0x0
	movwf	PORTD
	; Set CS* and WR* high
	movlw	0x1 | 0x2
	movwf	PORTD
	retfie	f		; fast return from interrupt

DAC_Setup:
	clrf	TRISD, A	; Control line set all outputs for WR*
	clrf	TRISJ, A	; Set PORTJ as all outputs
	clrf	LATD, A		; Clear PORTC outputs
	clrf	LATJ, A		; Clear PORTJ outputs

	; Set both CS* and WR* to high
	movlw	0x1 | 0x2
	movwf	PORTD
	
	movlw	00000001B
	movwf	T1CON
	
	bcf	C4TSEL1
	movlw	000000001B
	movwf	CCPTMRS1
	movlw	00001011B		
	movwf	CCP4CON         	
	movlw	0xee
	movwf	CCPR4L
	movlw	0x00
	movwf	CCPR4H
	
	bsf	CCP4IE	
	bsf	GIE
	bsf	PEIE
	
	return
	
DAC_change_frequency:
	; Take target from W
	movwf	DAC_freq_index

	lfsr	0, scaleArray	; Load FSR0 with address in RAM	
	movlw	low highword(scaleTable)	; address of data in PM
	movwf	TBLPTRU, A	    ; load upper bits to TBLPTRU
	movlw	high(scaleTable)    ; address of data in PM
	movwf	TBLPTRH, A	    ; load high byte to TBLPTRH
	movlw	low(scaleTable)	    ; address of data in PM
	movwf	TBLPTRL, A	    ; load low byte to TBLPTRL

	movf	DAC_freq_index, 0
	addwfc	TBLPTRL, 0
	addwfc	TBLPTRL, 0
	movwf	TBLPTRL, A
	
	tblrd*+
	movff	TABLAT, CCPR4L
	tblrd*+
	movff	TABLAT, CCPR4H
	return
	
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x01	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0x01	    
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