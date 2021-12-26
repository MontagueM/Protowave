#include <xc.inc>

extrn		LCD_Send_Byte_D
extrn		ADC_Read
global		ADC_LCD_Setup, ADC_LCD_Run, Check_Change_For_LCD
psect		udata_acs		    
counter:	ds 1
delay_count:	ds 1
ARG1L:		ds 1
ARG1H:		ds 1
ARG2L:		ds 1
ARG2H:		ds 1
ARG2U:		ds 1
RES0:		ds 1
RES1:		ds 1
RES2:		ds 1
RES3:		ds 1
DIG0:		ds 1
DIG1:		ds 1
DIG2:		ds 1
DIG3:		ds 1
current_dig:    ds 1
old_ADRESH:	ds 1
tmp_ADRESH:	ds 1


    
psect	adc_calibration_lcd, class=CODE	


	; ******* Programme FLASH read Setup Code ***********************
ADC_LCD_Setup:
	bcf	CFGS
	bsf	EEPGD
	movlw	0xff
	movwf	current_dig
	return

Setup_Multiply_16x16:
	movff	ADRESL, ARG1L	
	movff	ADRESH, ARG1H
	//put the ADRESH back to left justified
	swapf	ARG1L, F, A
	movlw	0xF
	andwf	ARG1H, W, A
	swapf	WREG, W, A
	addwf	ARG1L, F, A
	
	movlw	0xF0
	andwf	ARG1H, F, A
	swapf	ARG1H, F, A
	
	movlw	0x02
	movwf	ARG2L
	movlw	0x10
	movwf	ARG2H
	return

Multiply_16x16:
	movf	ARG1L, W
	mulwf	ARG2L		; ARG1L * ARG2L -> PRODH:PRODL

	movff	PRODH, RES1 
	movff	PRODL, RES0 

	movf	ARG1H, W
	mulwf	ARG2H		; ARG1H * ARG2H -> PRODH:PRODL

	movff	PRODH, RES3 
	movff	PRODL, RES2 

	movf	ARG1L, W
	mulwf	ARG2H		; ARG1L * ARG2H -> PRODH:PRODL

	movf	PRODL, W
	addwf	RES1, F		; Add cross products
	movf	PRODH, W
	addwfc	RES2, F 
	clrf	WREG 
	addwfc	RES3, F 

	movf	ARG1H, W 
	mulwf	ARG2L		; ARG1H * ARG2L -> PRODH:PRODL

	movf	PRODL, W 
	addwf	RES1, F		; Add cross
	movf	PRODH, W	; products
	addwfc	RES2, F 
	clrf	WREG
	addwfc	RES3, F
	return

Multiply_8x24:
	movf	ARG1L, W
	mulwf	ARG2L		; ARG1L * ARG2L -> PRODH:PRODL

	movff	PRODH, RES1
	movff	PRODL, RES0

	movf	ARG1L, W
	mulwf	ARG2H		; ARG1H * ARG2H-> PRODH:PRODL

	movf	PRODL, W
	addwf	RES1, F		; PRODL + RES1--> RES1
	movff	PRODH, RES2	

	movf	ARG1L, W
	mulwf	ARG2U		; ARG1H * ARG2H -> PRODH:PRODL

	movf	PRODL, W
	addwfc	RES2, F		; PRODL + RES2 + carry bit --> RES2
	movlw	0x0
	addwfc	PRODH, F	; add the carry bit to RES3 (highest byte)
	movff	PRODH, RES3
	return

Get_Digits:
	; Setup 16x16
	call	Setup_Multiply_16x16
	; Do 16x16 mult
	call	Multiply_16x16
	; Set first digit
	movf	RES3, W
	movwf	DIG0, F

	; Setup 8x24
	movlw	0x0A
	movwf	ARG1L, F
	
	movf	RES0, W
	movwf	ARG2L, F
	movf	RES1, W
	movwf	ARG2H, F
	movf	RES2, W
	movwf	ARG2U, F
	; Do 8x24 mult and set each digit three times
	call	Multiply_8x24
	;  set digit
	movf	RES3, W
	movwf	DIG1, F
	
	movf	RES0, W
	movwf	ARG2L, F
	movf	RES1, W
	movwf	ARG2H, F
	movf	RES2, W
	movwf	ARG2U, F
	call	Multiply_8x24
	;  set digit
	movf	RES3, W
	movwf	DIG2, F
	
	movf	RES0, W
	movwf	ARG2L, F
	movf	RES1, W
	movwf	ARG2H, F
	movf	RES2, W
	movwf	ARG2U, F
	call	Multiply_8x24
	;  set digit
	movf	RES3, W
	movwf	DIG3, F
	
	; Convert to ASCII
	movlw	48
	addwf	DIG0, F
	addwf	DIG1, F
	addwf	DIG2, F
	addwf	DIG3, F
	return

	; ******* Main programme ****************************************
ADC_LCD_Run: 	
	call	Get_Digits
	call	Write_DC
	
	return
	
Check_Change_For_LCD:
	call	ADC_Read
	movff	ADRESH, tmp_ADRESH
	movlw	11111100B
	andwf	tmp_ADRESH, F, A
	movf	tmp_ADRESH, W
	subwf	old_ADRESH, W
	bz	Check_Return_For_LCD	
	
	movff	tmp_ADRESH, old_ADRESH
	retlw	0
	
Check_Return_For_LCD:
	retlw	1

Write_DC:
	movf	DIG0, W	
	call	LCD_Send_Byte_D
	movf	DIG1, W	
	call	LCD_Send_Byte_D
	movf	DIG2, W	
	call	LCD_Send_Byte_D
	movlw	0x25		    ; % for percentage
	call	LCD_Send_Byte_D
	
	return
	