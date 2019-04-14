HEX4_INSTRUCTIONS
    MOVE.W  D2,D3
    CMPI.W  #$4AFC, D3  * ILLEGAL
    BEQ     ONE_WORD_UNRECOG
    CMPI.W  #$4E72, D3  *STOP
    BEQ     TWO_WORD_UNRECOG
    CMPI.W  #$4E70, D3  * RESET
    BEQ     ONE_WORD_UNRECOG
    BRA RESUME_DIS
    
HEX0_INSTRUCTIONS
    MOVE.W  D2,D3
    CMPI.W  #$007C, D3  * ORI TO SR
    BEQ     TWO_WORD_UNRECOG
    CMPI.W  #$003C, D3  * ORI TO CCR
    BEQ     TWO_WORD_UNRECOG
    CMPI.W  #$4AFC, D3  * RESET
    BEQ     ONE_WORD_UNRECOG
    CMPI.W  #$0A3C, D3  * EORI TO CCR
    BEQ     TWO_WORD_UNRECOG
    CMPI.W  #$0A7C, D3  * EORI TO SR
    BEQ     TWO_WORD_UNRECOG
    CMPI.W  #$027C, D3  * ANDI TO SR
    BEQ     TWO_WORD_UNRECOG
    CMPI.W  #$023C, D3  * ANDI TO CCR
    BEQ     TWO_WORD_UNRECOG
    LSR.W   #$3, D3
    CMPI.W  #$0908, D3  * SWAP
    BEQ     ONE_WORD_UNRECOG
    LSR.W   #$4, D3
    CMPI.W  #$0091, D3  * EXT
    BEQ     ONE_WORD_UNRECOG
*---------- Immediate operation unrecognized codes-----------------
    LSR.W   #$1, D3 * Find the Immediate opcodes
    CMPI.B  #$2, D3
    BEQ     IMM_AND_EA
    CMPI.B  #$4, D3
    BEQ     IMM_AND_EA
    CMPI.B  #$6, D3
    BEQ     IMM_AND_EA
    BRA RESUME_DIS  * Technically should never hit this 
    CMPI.B  #$A, D3
    BEQ     IMM_AND_EA
    CMPI.B  #$C, D3
    BEQ     IMM_AND_EA

* This subroutine handles the immediate, <EA> invalid opcodes.
* Have to check size and print the the data accordingly.  
IMM_AND_EA
    JSR     NOT_IN
    MOVE.W  D2,D3
    AND.W   #$00FF, D3 * Get only the size and EA bits. 
    MOVE.B  D3, D4      * Need the original for the EA later
    JSR     PRINT_ADD
    MOVE.W  (A0)+, D2
    JSR     NOT_IN
    LSR.W   #$6, D4
    CMPI.B  #$2, D4
    BNE     WORD_DATA
    JSR     PRINT_ADD
    MOVE.W  (A0)+, D2
    JSR     NOT_IN
WORD_DATA   * At a minimum, immediate opcodes use 1 word of data. Have to catch that.
    * A0 now is pointing to the next word after the immediate data. Could be an EA, might not. 
    MOVE.W  D3, D2  * Get the original EA bits
    ANDI.W  #$3F, D2 * EAs only
    JSR     FIX_OFFSET
    CLR.L   D2
    BRA     RESUME_DIS
NOT_IN       
        LEA INVALID_INSTR, A1
        JSR PRINT_ASSEM
        JSR PRINT_TAB
        MOVEA.L D2, A2
        MOVE.L  #0, D5
        MOVE.L  #28, D6
        JSR     PRINT_HEX
        JSR     PRINT_EA
        JSR     PRINT_NEWLINE
        ADDI.W  #1, F_LOOP
        CMPI.W  #31, F_LOOP
        BEQ     PROMP_BACK
        BRA     NOT_IN_CONT
PROMP_BACK
        JSR     PROMPT_ENTER
NOT_IN_CONT        
        RTS
        BRA     RESUME_DIS
        
*---------------------------------------------------------- 
*(A0) is automatically incremented to point to next word
ONE_WORD_UNRECOG * Works as intended
    JSR NOT_IN
    BRA RESUME_DIS
*---------------------------------------------------------- 
TWO_WORD_UNRECOG * Works as intended
    JSR NOT_IN
    JSR PRINT_ADD
    MOVE.W  (A0)+, D2
    JSR NOT_IN
    BRA RESUME_DIS
*---------------------------------------------------------- 
ONE_WORD_EA     
    JSR NOT_IN
    JSR FIX_OFFSET
    BRA RESUME_DIS
*----------------------------------------------------------    
TWO_WORD_EA
    JSR NOT_IN
    JSR PRINT_ADD
    MOVE.W  (A0)+, D2
    JSR NOT_IN
    JSR FIX_OFFSET
    BRA RESUME_DIS
*----------------------------------------------------------         

* Subroutine used to decipher the EA and auto increment based on the EA
FIX_OFFSET
    MOVE.W  D2, D3
    AND.W   #$3F, D3
    CMPI.B  #$38, D3 * Only absolute addresses need to be incremented over
    BLT     RESUME_DIS
    * Absolute addresses only
    CMPI.B  #$38, D3    * WORD
    BEQ     RUN_ONCE
    *MOVE.W  (A0)+, D2
    JSR     PRINT_ADD
    MOVE.W  (A0)+, D2
    JSR     NOT_IN
RUN_ONCE
    JSR     PRINT_ADD
    MOVE.W  (A0)+, D2  
    JSR     NOT_IN  
    RTS

    
*----------------------------------------------------------     
* Will print the current address being held in A0. 
PRINT_ADD
    MOVEA.L #ADDRESS,A1
    MOVEA.L A0, A2
    MOVE.L  #0, D5
    MOVE.L  #28, D6 
    JSR PRINT_ADDR
    JSR PRINT_ASSEM
    JSR PRINT_TAB
    RTS
*----------------------------------------------------------  
*------------------------- DONE--------------------------------  
UNRECOG_BRANCH
    MOVE.W  D2,D3
    JSR NOT_IN
    CMPI.B  #$FF, D3
    BEQ UNRECOG_TWICE
    CMPI.B  #$00, D3
    BEQ UNRECOG_ONCE
    BRA RESUME_DIS
UNRECOG_TWICE   * When displacement is 2 words
    MOVE.W  (A0)+, D2
    JSR NOT_IN
    MOVE.W  (A0)+, D2
    JSR NOT_IN    
    BRA RESUME_DIS
    
UNRECOG_ONCE
    JSR PRINT_ADD
    MOVE.W  (A0)+, D2
    JSR NOT_IN
    BRA RESUME_DIS
*-----------------------------------------------------------------

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
