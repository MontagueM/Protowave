#include <xc.inc>
	
global	DAC_Setup, DAC_Int_Hi, DAC_change_frequency
extrn	Do_Sawtooth, Do_Square, Sawtooth_Setup, Square_Setup, RET_status, KB_Fin
psect	udata_acs   ; named variables in access ram
DAC_freq_index: ds 1
bIs_Saw:	ds 1
psect data
 
scaleTableMinor:	
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
	align	2

scaleTableMajor:	
	db	0x1b, 0x01
	db	0xfc, 0x00
	db	0xe0, 0x00
	db	0xd3, 0x00
	db	0xbc, 0x00
	db	0xa8, 0x00
	db	0x96, 0x00
	db	0x8d, 0x00
	db	0x8d, 0x00
	db	0x7e, 0x00
	db	0x70, 0x00
	db	0x69, 0x00
	db	0x5e, 0x00
	db	0x53, 0x00
	db	0x4a, 0x00
	db	0x46, 0x00
	align	2
	
psect	dac_code, class=CODE
DAC_Int_Hi:	
	btfss	CCP4IF		; check that this is ccp timer 4 interrupt
	retfie	f		; if not then return
	bcf	CCP4IF	        ; clear the CCP4IF flag
	
	// Check if we need to do a setup
	movlw	0x40
	andwf	PORTD, W, A

	movlw	0x0
	cpfseq	RET_status, 0
	retfie	f
    
	// Depending on the bit set for PORTD we gen corresponding waveform
	btfsc	PORTD, 6, A
	call	Do_Sawtooth

	btfss	PORTD, 6, A
	call	Do_Square
	
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
	movlw	01100000B
	movwf	TRISD, A
	; Set both CS* and WR* to high
	movlw	0x1 | 0x2
	movwf	PORTD
	
	movlw	00000001B
	movwf	T1CON
	
	bcf	C4TSEL1
	//movlw	000000001B
	//movwf	CCPTMRS1
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
	call	Square_Setup
	return

ReadMajorScale:
    	movlw	low highword(scaleTableMajor)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(scaleTableMajor)    ; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(scaleTableMajor)	    ; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	return
	
ReadMinorScale:
    	movlw	low highword(scaleTableMinor)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(scaleTableMinor)    ; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(scaleTableMinor)	    ; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	return

DAC_change_frequency:
	// Take target from W
	movff	KB_Fin, DAC_freq_index
	
	// Which scale to read based on bit 5
	btfsc	PORTD, 5, A
	call	ReadMajorScale
	
	btfss	PORTD, 5, A
	call	ReadMinorScale
	
	// Multiply by two and add to TBLPTR
	rlncf	DAC_freq_index, W, A
	addwf	TBLPTRL, F
	movlw	0x0
	addwfc	TBLPTRH, F
	addwfc	TBLPTRU, F
	
	// Write the new frequency into CCP compare registers
	tblrd*+
	movff	TABLAT, CCPR4L
	tblrd*
	movff	TABLAT, CCPR4H
	
	return

	end