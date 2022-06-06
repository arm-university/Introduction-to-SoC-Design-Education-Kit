;------------------------------------------------------------------------------------------------------
; Design and Implementation of an AHB UART peripheral
; 1)Display text string: "TEST" on VGA. 
; 2)Receive/ print characters from/ to a computer through UART port.
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


;Write "TEST" to the text console and the UART

				LDR 				;TO DO: Load R1 with Console text base address
				LDR 				;TO DO: Load R2 with UART base address
				MOVS		        ;TO DO: Copy the value of operand 2 e.g #'T' to R0 and set condition flags
				STR		            ;TO DO: store R0 in address stored in R1
				STR		            ;TO DO: store R0 in address stored in R2
				
				
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



;wait until receive buffer is not empty

WAIT			LDR 	R1, =0x51000004
				LDR		R0, [R1]
				MOVS	R1, #01
				ANDS	R0,  R0,  R1
				CMP		R0,	#0x00
				BNE		WAIT		

;print received text to both UART and VGA

				LDR 	R1, =0x51000000
				LDR 	R2, =0x50000000
				LDR 	R0, [R1]
				STR		R0, [R1]
				STR		R0, [R2]


				B		WAIT

				ENDP

				ALIGN 		4					 ; Align to a word boundary

		END                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   