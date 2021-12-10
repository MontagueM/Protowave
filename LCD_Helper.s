#include <xc.inc>
    
global	LCD_main
extrn	LCD_Write_Message, LCD_Clear_Display, LCD_Clear_Display2, LCD_delay_ms
extrn	SetTwoLines
extrn	ADC_LCD_Setup, ADC_LCD_run, ADC_Read, check_change_for_lcd
psect	udata_acs   ; named variables in access ram
LCD_STATUS: ds 1
OldState:   ds 1
OldADC:	    ds 1
Index:	    ds 1
Tmp:	    ds 1
psect data
 
 DisplayTable:
    db	    'W','F',':'	    ;0
    db	    'S','Q','U'	    ;1
    db	    ' ', ' ',' '    ;2
    db	    'D', 'C', ':'   ;3
    db	    'S','A','W'	    ;4
    db	    'S','C',':'	    ;5
    db	    'M','I','N'	    ;6
    db      'M','A','J'	    ;7
    align   2

psect	lcd_help_code, class=CODE
WriteDisplay:
	mullw	0x3
	movff	PRODL, Index
	
    	; read the corresponding value
	movlw	low highword(DisplayTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(DisplayTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(DisplayTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	
	movf	Index, W
	addwf	TBLPTRL, F
	movlw	0x0
	addwfc	TBLPTRH, F
	addwfc	TBLPTRU, F
	
	movlw	3
	call	LCD_Write_Message
	return

LCD_main:
	// Check status has changed
	movff	PORTD, LCD_STATUS
	movlw	0x60
	andwf	LCD_STATUS, F, A
	movf	LCD_STATUS, W
	// If status has changed, write new string to LCD
	cpfseq	OldState, A
	call	ChangeLCD
	
	movff	LCD_STATUS, OldState
	
	call	check_change_for_lcd
	movwf	Tmp, A
	movlw	0x1
	cpfseq	Tmp
	call	ChangeLCD
LCD_ret:
	return
	

LCD_suc:
	//call	
	return
	
WriteWave:
	movlw	0x0
	call	WriteDisplay
	return

WriteSquare:
	movlw	0x1
	call	WriteDisplay
	movlw	0x2
	call	WriteDisplay
	movlw	0x3
	call    WriteDisplay
	call	ADC_LCD_Setup
	call	ADC_LCD_run
	return
	
WriteSaw:
	movlw	0x4
	call	WriteDisplay
	return
		
WriteScale:
	movlw	0x5
	call	WriteDisplay
	return
	
WriteMin:
	movlw	0x6
	call	WriteDisplay
	return
	
WriteMaj:
	movlw	0x7
	call	WriteDisplay
	return

ChangeLCD:
    	call	LCD_Clear_Display
    	call	WriteWave

	btfsc	PORTD, 6, A
   	call	WriteSaw
	btfss	PORTD, 6, A
	call	WriteSquare

	call	SetTwoLines
	call	WriteScale

	btfsc	PORTD, 5, A
	call	WriteMaj
	btfss	PORTD, 5, A
	call	WriteMin
	
	return
	end





