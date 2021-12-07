#include <xc.inc>
	
global	DAC_Setup, DAC_Int_Hi, DAC_change_frequency, LCD_delay_ms
extrn	Do_Sawtooth, Do_Square, Sawtooth_Setup, Square_Setup, RET_status
psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage
DAC_freq_index: ds 1
bIs_Saw:	ds 1
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
	
	// Check if we need to do a setup
	movff	PORTD, LCD_tmp
	movlw	0x40
	
	andwf	LCD_tmp, 1, 0
	
	movf	bIs_Saw, 0
	cpfseq	LCD_tmp, 0
	call	FlipWaveformType

	movlw	0x0
	cpfseq	RET_status, 0
	retfie	f
	
	;movlw	0x40
	;andwf	PORTD, 1
	
	;movlw	0x0
	;cpfseq	PORTD, 0
	;call	Play_Saw
	
	;movlw	0x1
	;cpfseq	PORTD, 0
    
    	movlw	0x0
	cpfseq	bIs_Saw, 0
	call	Do_Sawtooth
	movlw	0x40
	cpfseq	bIs_Saw, 0
	call	Do_Square
	
	; Set CS* and WR* low
	movlw	0x0
	movwf	PORTD
	; Set CS* and WR* high
	movlw	0x1 | 0x2
	movwf	PORTD
	retfie	f		; fast return from interrupt

FlipWaveformType:
	// Flip setting
	movlw	0x40
	xorwf	bIs_Saw, 1, 0
    
	// What setup to do
	movlw	0x0
	cpfseq	bIs_Saw, 0
	call	Sawtooth_Setup
	
	movlw	0x40
	cpfseq	bIs_Saw, 0
	call	Square_Setup
	
	return
    
DAC_Setup:
	clrf	TRISD, A	; Control line set all outputs for WR*
	clrf	TRISJ, A	; Set PORTJ as all outputs
	clrf	LATD, A		; Clear PORTC outputs
	clrf	LATJ, A		; Clear PORTJ outputs
	movlw	01100000B
	movwf	TRISD, A
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
	
	movlw	0x0
	movwf	bIs_Saw, A	; Default to square
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