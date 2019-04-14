DUMMY:
        RTS

*------Destination bits are sorted as << MODE | REGISTER >>---------------------
* See subroutine in Disassembler_subroutines.x68 called "DEST_TO_SOURCEEA" 
* This subroutine will convert the REGISTER | MODE format into MODE | REGISTER 
* in D4. 
DECODE_EA
        MOVE.B  D3, D4  * Use D5 to decode the EA. D4 will hold the original copy incase we need to reset   
        CMPI.B  #$3C,D4
        BEQ     IMM_BRANCH
        LSR.B   #$3, D4
        CMPI.B  #0, D4 * DATA REGISTER TEST
        BEQ     DATA_BRANCH     
        CMPI.B  #1, D4 * Address Register
        BEQ     ADDR_BRANCH
        CMPI.B  #2, D4 * Address  Indirect
        BEQ     IND_ADDR_BRANCH
        CMPI.B  #3, D4 * Address Post increment
        BEQ     ADDR_POST_BRANCH
        CMPI.B  #4, D4 * Adress pre decrement
        BEQ     ADDR_PRE_BRANCH
        BRA     WORD_OR_LONG_ADDR
        RTS
        
*--------------Immediate data EA branch-----------------
IMM_BRANCH
    JSR PRINT_IMM
    CMPI.B  #1, IS_LONG
    BEQ     LONG_DATA_BRANCH
    BRA     WORD_DATA_BRANCH
    RTS
        
WORD_DATA_BRANCH
    JSR WORD_ADDR
    RTS
        
LONG_DATA_BRANCH
    JSR LONG_ADDR
    RTS
*--------------------------------------------------------
        
ADDR_BRANCH
    MOVE.B  D3,D4
    JSR     PRINT_A
    AND.B   #$7, D4
    MOVE.B  D4, D1
    JSR     PRINT_REGIS_NUM
    RTS
        
IND_ADDR_BRANCH
    MOVE.B  D3,D4
    AND.B   #$07,D4
    LEA     LEFT_PAREN,A1
    JSR     PRINT_ASSEM
    JSR     PRINT_A
    MOVE.B  D4, D1
    JSR     PRINT_REGIS_NUM
    LEA     RIGHT_PAREN,A1
    JSR     PRINT_ASSEM
    RTS
        
ADDR_POST_BRANCH
    JSR IND_ADDR_BRANCH
    LEA PLUS,A1
    JSR PRINT_ASSEM
    RTS
        
ADDR_PRE_BRANCH
    LEA MINUS,A1
    JSR PRINT_ASSEM
    JSR IND_ADDR_BRANCH
    RTS
        

DATA_BRANCH        
    MOVE.B  D3, D4  
    JSR     PRINT_D
    AND.B   #$7, D4
    MOVE.B  D4, D1  *PRINT_REGIS_NUM uses D7 as the offset
    JSR     PRINT_REGIS_NUM
    RTS

*------------MOVE ADDRESS TO PRINT INTO A2-----------------------------------
* This is to avoid A1 being used as a Trap task function
* And to not override A0 which is our pointer to the addresses
WORD_OR_LONG_ADDR
    MOVE.B  D3, D4
    AND.B   #$07, D4
    CMPI.B  #1, D4
    BEQ     LONG_ADDR 
    BRA     WORD_ADDR
        
WORD_ADDR       * Need to check if this works
    JSR     PRINT_HEX
    MOVE.L  #0, D5
    MOVE.B  #28, D6
    MOVE.W  (A0)+, A2
PRINT_EA
    MOVEA.L #ADDRESS,A1
    JSR     PRINT_ADDR      * Subroutine to print address
    MOVE.B  #4, D1          * 4 characters to print
    MOVE.B  #1, D0          * Trap task mode
    ADDA.W  #$4, A1         * Point 4 bytes forward. Printing word not long
    TRAP    #15             * Print
    RTS

LONG_ADDR
        JSR     PRINT_HEX
        MOVE.B  #0, D5
        MOVE.B  #28, D6
        MOVE.L  (A0)+, A2
        MOVEA.L #ADDRESS,A1
        JSR     PRINT_ADDR      * Subroutine to print address        
        JSR     PRINT_ASSEM
        RTS
*-----------------------------------------------------------------------------
        
BRANCH_WORD_ADDR
        MOVEA.L A0, A2          * A2 is used to print the addresses. A0 is the starting address + 2 bytes      
        MOVEA.L #ADDRESS, A1    * Load the variable to store our address
        ADD.W   (A0)+, A2       * Increment over by a word. (A0) is the displacement. And increments over to the next instruction for us.                
        MOVE.L  #28, D6         * D6 to shift to the right by
        MOVE.L  #0, D5          * D5 to shift to the left by
        JSR     PRINT_ADDR      * Subroutine to print address
        MOVE.B  #4, D1          * 4 characters to print
        MOVE.B  #1, D0          * Trap task mode
        ADDA.W  #$4, A1         * Point 4 bytes forward. Printing word not long
        TRAP    #15             * Print
        JSR     PRINT_NEWLINE   * Print new line
        RTS
BRANCH_LONG_ADDR
        MOVEA.L A0, A2
        MOVEA.L #ADDRESS, A1
        ADD.L   (A0)+, A2
        MOVE.L  #28, D6         * D6 to shift to the right by
        MOVE.L  #0, D5          * D5 to shift to the left by
        JSR     PRINT_ADDR      * Subroutine to print address        
        MOVE.B  #8, D1
        MOVE.B  #1, D0
        TRAP    #15
        JSR     PRINT_NEWLINE
        RTS

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
