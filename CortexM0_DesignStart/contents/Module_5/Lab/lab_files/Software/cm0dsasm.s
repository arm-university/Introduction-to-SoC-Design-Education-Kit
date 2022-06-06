;------------------------------------------------------------------------------------------------------
; Design and Implementation of an AHB VGA Peripheral
; 1)Display text string: "TEST" on VGA. 
; 2)Change the color of the four corners of the image region.
;------------------------------------------------------------------------------------------------------

; Vector Table Mapped to Address 0 at Reset

						PRESERVE8
                		THUMB

        				AREA	RESET, DATA, READONLY	  			; First 32 WORDS is VECTOR TABLE
        				EXPORT 	__Vectors
					
__Vectors		    	DCD		0x00003FFC
        				DCD		Reset_Handler
        				DCD		0  			
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD 	0
        				DCD		0
        				DCD		0
        				DCD 	0
        				DCD		0
        				
        				; External Interrupts
						        				
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
              
                AREA |.text|, CODE, READONLY
;Reset Handler
Reset_Handler   PROC
                GLOBAL Reset_Handler
                ENTRY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;              Complete the TO DO comments below              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Write "TEST" to the text console

             
				LDR 				;TO DO: Load R1 with Console text base address
				MOVS		        ;TO DO: Copy the value of operand 2 e.g #'T' to R0 and set condition flags
				STR		            ;TO DO: store R0 in address stored in R1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   TO DO : Repeat above 3 instructions each for #'E', #'S' and #'T'  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;Write four white dots to four corners of the frame buffer

				LDR 	R1, =0x50000004
				LDR		R0, =0xFF
				STR		R0, [R1]

				LDR 	R1, =0x50000190
				LDR		R0, =0xFF
				STR		R0, [R1]
		
				LDR 	R1, =0x5000EE04
				LDR		R0, =0xFF
				STR		R0, [R1]

				LDR 	R1, =0x5000EF90
				LDR		R0, =0xFF
				STR		R0, [R1]

				ENDP

				ALIGN 		4					 ; Align to a word boundary

		END                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   