#include <xc.inc>
	
global		DAC_Setup, DAC_Interrupt_High, DAC_Change_Frequency
extrn		Do_Sawtooth, Do_Square, Sawtooth_Setup, Square_Setup, return_status, kb_final
psect		udata_acs
dac_freq_index:	ds 1
b_is_sawtooth:	ds 1
psect		data
 
scale_table_minor:	
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

scale_table_major:	
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

scale_table_song:	
	db      0xbc, 0x00
	db      0x9e, 0x00
	db      0xee, 0x00
	db      0xd3, 0x00
	db      0xbc, 0x00
	db      0xb1, 0x00
	db      0xbc, 0x00
	db      0xd3, 0x00
	db      0xbc, 0x00
	db      0xd3, 0x00
	db      0x9e, 0x00
	align	2
	
psect	dac_code, class=CODE
DAC_Interrupt_High:	
	btfss	CCP4IF			; check that this is ccp timer 4 interrupt
	retfie	f			; if not then return
	bcf	CCP4IF			; clear the CCP4IF flag
	
	// Check if we need to do a setup
	movlw	0x40
	andwf	PORTD, W, A

	movlw	0x0
	cpfseq	return_status, 0
	retfie	f
    
	// Depending on the bit set for PORTD we gen corresponding waveform
	btfsc	PORTD, 6, A
	call	Do_Sawtooth

	btfss	PORTD, 6, A
	call	Do_Square
	
	
	movlw	0x0		    ; Set CS* and WR* low
	movwf	PORTD
				    
	movlw	0x1 | 0x2	    ; Set CS* and WR* high
	movwf	PORTD
	retfie	f		    ; fast return from interrupt
    
DAC_Setup:
	clrf	TRISD, A	    ; Control line set all outputs for WR*
	clrf	TRISJ, A	    ; Set PORTJ as all outputs
	clrf	LATD, A		    ; Clear PORTC outputs
	clrf	LATJ, A		    ; Clear PORTJ outputs
	movlw	01100000B
	movwf	TRISD, A
	
	movlw	0x1 | 0x2	    ; Set both CS* and WR* to high
	movwf	PORTD
	
	movlw	00000001B
	movwf	T1CON
	
	bcf	C4TSEL1
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
	movwf	b_is_sawtooth, A    ; Default to square
	call	Square_Setup
	
	return

Read_Major_Scale:
    	movlw	low highword(scale_table_major)
	movwf	TBLPTRU, A
	movlw	high(scale_table_major)
	movwf	TBLPTRH, A
	movlw	low(scale_table_major)
	movwf	TBLPTRL, A
	return
	
Read_Minor_Scale:
    	movlw	low highword(scale_table_minor)
	movwf	TBLPTRU, A
	movlw	high(scale_table_minor)
	movwf	TBLPTRH, A
	movlw	low(scale_table_minor)
	movwf	TBLPTRL, A
	return

Read_Song_Notes:
        movlw	low highword(scale_table_song)
	movwf	TBLPTRU, A
	movlw	high(scale_table_song)
	movwf	TBLPTRH, A
	movlw	low(scale_table_song)
	movwf	TBLPTRL, A
	return
	
DAC_Change_Frequency:
	// Take target from W
	movff	kb_final, dac_freq_index
	
	// Which scale to read based on bit 5
	btfsc	PORTD, 5, A
	call	Read_Major_Scale
	
	btfss	PORTD, 5, A
	call	Read_Minor_Scale
	
	// Uncomment below to activate song mode
	;call	Read_Song_Notes

	// Multiply by two and add to TBLPTR as 2-wide array
	rlncf	dac_freq_index, W, A
	addwf	TBLPTRL, F
	movlw	0x0
	addwfc	TBLPTRH, F
	addwfc	TBLPTRU, F
	
	// Write the new frequency into CCP compare registers
	tblrd*+
	movff	TABLAT, CCPR4L
	tblrd*+
	movff	TABLAT, CCPR4H
	
	return

	end