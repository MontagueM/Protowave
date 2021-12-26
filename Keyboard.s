#include <xc.inc>
    
global	KB_Setup, KB_Main, return_status, kb_final
extrn	LCD_Delay_MS
extrn	DAC_Change_Frequency
psect	udata_acs   ; reserve data space in access ram

kb_val:ds 1
kb_col:ds 1
kb_row:ds 1
kb_final:ds 1
kb_final_prev: ds 1
kb_pressed: ds 1
kb_fix: ds 1
return_status:	ds 1

psect	data    
	; ******* myTable, data in programme memory, and its length *****
my_table:	
	db	'A','B','C','D','E','F','G','A','A','B','C','D','E','F','G','A'
	align	2
	
psect	kb_code, class=CODE

	; ******* Programme FLASH read Setup Code ***********************
KB_Setup:	
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	movlw	3
	movwf	kb_fix
	return

	; ******* Main programme ****************************************


KB_Main:
	call    Acquire_Keypress
	call    Check_Key_Pressed
	movwf	return_status, A
	movlw	0x0
	cpfseq	return_status, 0
	return
	; If key pressed and is not prev key, continue
	call    Decode_Keypress
	call    Display_Keypress
	return
    
Acquire_Keypress:
	movlw	0
	movwf	kb_row
	movlw	0
	movwf	kb_col
	
    
	banksel PADCFG1
	bsf	REPU
	clrf	LATE, A
	banksel	0  ; we need this to put default bank back to A
	
	movlw	0x0F
	movwf	TRISE
	
	; delay?
	movlw	1
	call	LCD_Delay_MS
	
	; Drive output bits low all at once
	movlw	0x00
	movwf	PORTE, A
	
	; Read 4 PORTE input pins
	movff 	PORTE, kb_col

	; Invert the pins to show only the pressed ones
	movlw	0x0F
	xorwf	kb_col, 1
	
	; If no column pressed return
	movlw	0x00
	cpfsgt	kb_col
	return
	
	; Configure bits 0-3 output, 4-7 input
	movlw	0xF0
	movwf	TRISE
	
	movlw	1
	call	LCD_Delay_MS
	
	; Drive output bits low all at once
	movlw	0x00
	movwf	PORTE, A
	
	
	; Read4 PORTE input pins
	movff 	PORTE, kb_row
	swapf	kb_row, 1
	movlw	0x0F
	xorwf	kb_row, 1


	return

Check_Key_Pressed:
	; check KB_val is not zero
	movlw	0x00
	cpfsgt	kb_col
	goto	Check_Key_Fail
	
	; check KB_Fin not same as last one
	movlw	kb_final_prev
	subwf	kb_final, W, A
	bz	Check_Key_Fail2

	movff	kb_final, kb_final_prev, A
	retlw	0 ; success
    
Check_Key_Fail:
	movlw	0xFF
	movwf	kb_final, A
	retlw	1 ; fail
	
Check_Key_Fail2:
	retlw	1 ; fail

Decode_Keypress:
	; Set pressed
	movlw	0x01
	movwf	kb_pressed
    
    	; Decode results to determine
	; Print results to PORTD
	
	; starts at 1, need to start at 0
	bcf     STATUS, 0
	rrcf	kb_col, 1
	bcf     STATUS, 0
	rrcf	kb_row, 1
	
	; Fix if value is 4, needs to be 3
	movlw	4
	cpfslt	kb_row
	movff	kb_fix, kb_row
	movlw	4
	cpfslt	kb_col
	movff	kb_fix, kb_col
	
	; KB_Col + 4 * KB_Row
	movf	kb_row, 0
	addwf	kb_row, 0
	addwf	kb_row, 0
	addwf	kb_row, 0
	bcf     STATUS, 0
	addwfc	kb_col, 0
	movwf	kb_final, A

	return
    
Display_Keypress:
	call	DAC_Change_Frequency
	return

    end