#include <xc.inc>
	
global	DAC_Setup, DAC_Int_Hi, DAC_change_frequency
extrn	Do_Sawtooth, Do_Square, Sawtooth_Setup, Square_Setup
psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage
DAC_freq_index: ds 1
psect data
 
scaleTable:	
	db	0x1b, 0x01
	db	0xfc, 0x00
	db	0xee, 0x00
	db	0xd3, 0x00
	db	0xbc, 0x00
	db	0xb1, 0x00
	db	0x9e, 0x00
	db	0x8d, 0x00
	db	0x8d, 0x00
	db	0x7e, 0x00
	db	0x76, 0x00
	db	0x69, 0x00
	db	0x5e, 0x00
	db	0x58, 0x00
	db	0x4f, 0x00
	db	0x46, 0x00
	scaleTable_l   EQU	32	; length of data
	align	2
    
psect	dac_code, class=CODE
DAC_Int_Hi:	
	btfss	CCP4IF		; check that this is ccp timer 4 interrupt
	retfie	f		; if not then return
	bcf	CCP4IF	        ; clear the CCP4IF flag

DAC_Loop:
	;call Do_Sawtooth
	call Do_Square
	
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
	   
	call	Square_Setup
	;call Sawtooth_Setup
	return
	
DAC_change_frequency:
	; Take target from W
	movwf	DAC_freq_index

	movlw	low highword(scaleTable)	; address of data in PM
	movwf	TBLPTRU, A	    ; load upper bits to TBLPTRU
	movlw	high(scaleTable)    ; address of data in PM
	movwf	TBLPTRH, A	    ; load high byte to TBLPTRH
	movlw	low(scaleTable)	    ; address of data in PM
	movwf	TBLPTRL, A	    ; load low byte to TBLPTRL

	movf	DAC_freq_index, 0
	addwf	TBLPTRL, 1
	addwfc	TBLPTRL, 1
	
	tblrd*+
	movff	TABLAT, CCPR4L
	tblrd*+
	movff	TABLAT, CCPR4H
	return

	end