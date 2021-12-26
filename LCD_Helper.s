#include <xc.inc>
    
global		LCD_Main
extrn		LCD_Write_Message, LCD_Clear_Display
extrn		Set_Two_Lines
extrn		ADC_LCD_Setup, ADC_LCD_Run, Check_Change_For_LCD
extrn		kb_final
psect		udata_acs
lcd_status:	ds 1
old_state:	ds 1
old_key:	ds 1
index:		ds 1
tmp:		ds 1
psect data
 
major_key_lcd_table:
    db    ' ', 'A', '3'
    db    ' ', 'B', '3'
    db    'C', '#', '4'
    db    ' ', 'D', '4'
    db    ' ', 'E', '4'
    db    'F', '#', '4'
    db    'G', '#', '4'
    db    ' ', 'A', '4'
    db    ' ', 'A', '4'
    db    ' ', 'B', '4'
    db    'C', '#', '5'
    db    ' ', 'D', '5'
    db    ' ', 'E', '5'
    db    'F', '#', '5'
    db    'G', '#', '5'
    db    ' ', 'A', '5'
    align   2
    
minor_key_lcd_table:
    db    ' ', 'A', '3'
    db    ' ', 'B', '3'
    db    ' ', 'C', '4'
    db    ' ', 'D', '4'
    db    ' ', 'E', '4'
    db    ' ', 'F', '4'
    db    ' ', 'G', '4'
    db    ' ', 'A', '4'
    db    ' ', 'A', '4'
    db    ' ', 'B', '4'
    db    ' ', 'C', '5'
    db    ' ', 'D', '5'
    db    ' ', 'E', '5'
    db    ' ', 'F', '5'
    db    ' ', 'G', '5'
    db    ' ', 'A', '5'
    align   2
    
 display_lcd_table:
    db	    'W','F',':'	    ;0
    db	    'S','Q','U'	    ;1
    db	    ' ', ' ',' '    ;2
    db	    'D', 'C', ':'   ;3
    db	    'S','A','W'	    ;4
    db	    'S','C',':'	    ;5
    db	    'M','I','N'	    ;6
    db      'M','A','J'	    ;7
    db	    'K','B',':'	    ;8
    align   2

psect	lcd_help_code, class=CODE
Write_Display:
	mullw	0x3
	movff	PRODL, index
	
    	; read the corresponding value
	movlw	low highword(display_lcd_table)	; address of data in PM
	movwf	TBLPTRU, A			; load upper bits to TBLPTRU
	movlw	high(display_lcd_table)		; address of data in PM
	movwf	TBLPTRH, A			; load high byte to TBLPTRH
	movlw	low(display_lcd_table)		; address of data in PM
	movwf	TBLPTRL, A			; load low byte to TBLPTRL
	
	movf	index, W
	addwf	TBLPTRL, F
	movlw	0x0
	addwfc	TBLPTRH, F
	addwfc	TBLPTRU, F
	
	movlw	3
	call	LCD_Write_Message
	return

LCD_Main:
	// Check status has changed
	movff	PORTD, lcd_status
	movlw	0x60
	andwf	lcd_status, F, A
	movf	lcd_status, W
	// If status has changed, write new string to LCD
	cpfseq	old_state, A
	call	Change_LCD
	
	movff	lcd_status, old_state
	
	// If ADC has changed, write new string to LCD
	call	Check_Change_For_LCD
	movwf	tmp, A
	movlw	0x1
	cpfseq	tmp
	call	Change_LCD
	
	// If keyboard key has changed, write new string to LCD
	call	Check_Key_Change
	movwf	tmp, A
	movlw	0x1
	cpfseq	tmp
	call	Change_LCD

	return

	
Check_Key_Change:
	movf	kb_final, W
	subwf	old_key, W, A
	bz	Ret_Fail
	// Set old key to new key and return success to update screen
	movff	kb_final, old_key
	retlw	0
Ret_Fail:
	retlw	1
	
Write_Wave:
	movlw	0x0
	call	Write_Display
	return

Write_Square:
	movlw	0x1
	call	Write_Display
	call	Write_Empty
	movlw	0x3
	call    Write_Display
	call	ADC_LCD_Setup
	call	ADC_LCD_Run
	return

Write_Empty:
    	movlw	0x2
	call	Write_Display
	return
	
Write_Saw:
	movlw	0x4
	call	Write_Display
	return
		
Write_Scale:
	movlw	0x5
	call	Write_Display
	return
	
Write_Min:
	movlw	0x6
	call	Write_Display
	return
	
Write_Maj:
	movlw	0x7
	call	Write_Display
	return

Set_Minor_Table:
        	; read the corresponding value
	movlw	low highword(minor_key_lcd_table)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(minor_key_lcd_table)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(minor_key_lcd_table)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	return
	
Set_Major_Table:
        	; read the corresponding value
	movlw	low highword(major_key_lcd_table)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(major_key_lcd_table)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(major_key_lcd_table)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	return
	
Write_Key:
	movlw	0x8
	call	Write_Display
	
	movlw	0xFF
	cpfslt	kb_final
	goto	Write_Empty
	
	movf	kb_final, W
	mullw	0x3
	movff	PRODL, index
	
	// Which scale to read based on bit 5
	btfsc	PORTD, 5, A
	call	Set_Major_Table
	
	btfss	PORTD, 5, A
	call	Set_Minor_Table
	
	movf	index, W
	addwf	TBLPTRL, F
	movlw	0x0
	addwfc	TBLPTRH, F
	addwfc	TBLPTRU, F
	
	movlw	3
	call	LCD_Write_Message
	return
	
	return
	
Change_LCD:
    	call	LCD_Clear_Display
    	call	Write_Wave

	btfsc	PORTD, 6, A
   	call	Write_Saw
	btfss	PORTD, 6, A
	call	Write_Square

	call	Set_Two_Lines
	call	Write_Scale

	btfsc	PORTD, 5, A
	call	Write_Maj
	btfss	PORTD, 5, A
	call	Write_Min
	
	call	Write_Empty
	call	Write_Key
	
	return
	end





