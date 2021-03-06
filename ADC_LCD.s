#include <xc.inc>

extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_D, LCD_Write_Hex, LCD_Clear_Display, LCD_delay_ms ; external LCD subroutines
extrn	ADC_Setup, ADC_Read		   ; external ADC subroutines
global	ADC_LCD_Setup, ADC_LCD_run
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
ARG1L:    ds 1
ARG1H:    ds 1
ARG2L:    ds 1
ARG2H:    ds 1
ARG2U:    ds 1
RES0:    ds 1
RES1:    ds 1
RES2:    ds 1
RES3:    ds 1
DIG0:    ds 1
DIG1:    ds 1
DIG2:    ds 1
DIG3:    ds 1
current_dig:    ds 1
;current_dig:ds 1


    
psect	adc_calibration_lcd, class=CODE	


	; ******* Programme FLASH read Setup Code ***********************
ADC_LCD_Setup:
	bcf	CFGS
	bsf	EEPGD
	movlw	0xff
	movwf	current_dig
	return

SetupMultiply16x16:
	movff	ADRESL, ARG1L	
	movff	ADRESH, ARG1H
	movlw	0x02
	movwf	ARG2L
	movlw	0x10
	movwf	ARG2H
	return

Multiply16x16:
	MOVF ARG1L, W
	MULWF ARG2L ; ARG1L * ARG2L->
	; PRODH:PRODL
	MOVFF PRODH, RES1 ;
	MOVFF PRODL, RES0 ;
	;
	MOVF ARG1H, W
	MULWF ARG2H ; ARG1H * ARG2H->
	; PRODH:PRODL
	MOVFF PRODH, RES3 ;
	MOVFF PRODL, RES2 ;
	;
	MOVF ARG1L, W
	MULWF ARG2H ; ARG1L * ARG2H->
	; PRODH:PRODL
	MOVF PRODL, W ;
	ADDWF RES1, F ; Add cross
	MOVF PRODH, W ; products
	ADDWFC RES2, F ;
	CLRF WREG ;
	ADDWFC RES3, F ;
	;
	MOVF ARG1H, W ;
	MULWF ARG2L ; ARG1H * ARG2L->
	; PRODH:PRODL
	MOVF PRODL, W ;
	ADDWF RES1, F ; Add cross
	MOVF PRODH, W ; products
	ADDWFC RES2, F ;
	CLRF WREG ;
	ADDWFC RES3, F ; 
	return

Multiply8x24:
	MOVF ARG1L, W
	MULWF ARG2L ; ARG1L * ARG2L->
	; PRODH:PRODL
	MOVFF PRODH, RES1 ; 
	MOVFF PRODL, RES0 ;
	;
	MOVF ARG1L, W
	MULWF ARG2H ; ARG1H * ARG2H->
	; PRODH:PRODL
	MOVF PRODL, W
	ADDWF RES1, F	; PRODL + RES1--> RES1
	MOVFF PRODH, RES2 ;
	; 
	MOVF ARG1L, W
	MULWF ARG2U ; ARG1H * ARG2H->
	; PRODH:PRODL
	MOVF PRODL, W
	ADDWFC RES2, F ; PRODL + RES2 + carry bit --> RES2
	MOVLW 0x0
	ADDWFC	PRODH, F ; add the carry bit to RES3 (highest byte)
	MOVFF PRODH, RES3 ; 
	return

GetDigits:
	; Setup 16x16
	call	SetupMultiply16x16
	; Do 16x16 mult
	call	Multiply16x16
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
	call	Multiply8x24
	;  set digit
	movf	RES3, W
	movwf	DIG1, F
	
	movf	RES0, W
	movwf	ARG2L, F
	movf	RES1, W
	movwf	ARG2H, F
	movf	RES2, W
	movwf	ARG2U, F
	call	Multiply8x24
	;  set digit
	movf	RES3, W
	movwf	DIG2, F
	
	movf	RES0, W
	movwf	ARG2L, F
	movf	RES1, W
	movwf	ARG2H, F
	movf	RES2, W
	movwf	ARG2U, F
	call	Multiply8x24
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
ADC_LCD_run: 	
	//call	measure_loop
	return

run:
    	;movlw	100
	;call	LCD_delay_ms
    	;call	LCD_Clear_Display
	;movlw	100
	;call	LCD_delay_ms
	;nop
	;nop
	; Reset temp to new dig1 value
	movff	DIG1, current_dig
   
	movf	DIG0, W	
	call	LCD_Send_Byte_D
	;movlw	0x2e	; dot for floating point
	;call	LCD_Send_Byte_D
	movf	DIG1, W	
	call	LCD_Send_Byte_D
	movf	DIG2, W	
	call	LCD_Send_Byte_D
	;movf	DIG3, W	
	;call	LCD_Send_Byte_D
	movlw	0x25	; % for percentage
	call	LCD_Send_Byte_D
    	;movlw	100
	;call	LCD_delay_ms
	return

measure_loop:
	call	ADC_Read
	movlw	50
	call	LCD_delay_ms
	
	call	GetDigits
	
	movf	DIG1, W
	; Want to check if the digit is within +- 1, if so skip
	subwf	current_dig, W
	bz	measure_loop

	addlw	0x1
	bz	measure_loop
	sublw	0x2
	bz	measure_loop
	; If different by +-1 then we print new one
	call	run

	return

	end