DUMMY_PLACEHOLDER_SUBROUTINE:
    RTS
    
*----------------------------------------------------------------
FORMAT_TEST
        MOVE.W  D2,D3
        AND.W   #$003F, D3
        JSR     CHECK_EA
        RTS
*------------------------------------------------------
* Should be MODE | REGISTER
* Checks if it's indirect An with displacement or 
* An with displacement and index which are invalid EAs
*------------------------------------------------------
CHECK_EA
        CMPI.B  #$3D, D3
        BEQ     NOT_EA
        CMPI.B  #$3E, D3
        BEQ     NOT_EA
        AND.W   #$0038, D3
        LSR.W   #3, D3
        CMPI.B  #5, D3
        BEQ     NOT_EA
        CMPI.B  #6, D3
        BEQ     NOT_EA
        RTS

NOT_EA  
        LEA INVALID_INSTR, A1
        JSR PRINT_ASSEM
        JSR PRINT_TAB
        *ADDA.W  #$2, A0
        MOVEA.L D2, A2
        MOVE.L  #0, D5
        MOVE.L  #28, D6
        JSR     PRINT_HEX
        JSR     PRINT_EA
        JSR     PRINT_NEWLINE
        ADDA.L  #$2, A0
        BRA     RESUME_DIS

*--------Will print the address----------------
* Will get the main address from A0, pointer used to hold the current address
* Will do arithmetic shifts + addition to isolate single hex needed to convert to ASCII
* Will hold the ASCII converted string at ADDRESS (Look at the bottom)
*------------------------------------------------      
PRINT_ADDR:  
        
        MOVE.L  A2, D7      * Get the original address
        LSL.L   D5, D7      * Shift it left to get rid of unneeded hex to the left of the one we want
        LSR.L   D6, D7      * Shift it right by 28 places (32 - 28 = 4 --> Single hex character)
        JSR     GET_ADD     * Jump to subroutine to determine if it's a number or letter
        ADDI.B  #4, D5      * Add 4 (1 hex character offset) to our offset to shift left
        CMPI.B  #28,D5      * Last shift is 28 places so we need to compare BLE
        BLE     PRINT_ADDR  * If the last shift wasn't 28 places, repeat PRINT_ADDR
        *MOVE.B  D7, (A1)+
        MOVEA.L #ADDRESS, A1    * Store the String representation of our address   
        
        RTS         * Return back to main method. 
        
*---------------Sub-routine to help the PRINT_ADDR subroutine-----------------
* Just does a comparison with #10 (decimal) as a separator. 
* Since 0-9, A-F doesn't have a character inbetween, I just chose 10 and used the BGE DCC comparison. 
GET_ADD
        CMPI.B   #10, D7    * Compare with decimal #10
        BGE     GET_LETTER  * Greater than or equal to = A-->F
        BMI     GET_NUM     * Less than = 0-->9
        
GET_LETTER
        ADDI.B  #$37,D7     * HEX to ASCII offset for letters is #$37
        MOVE.B  D7,(A1)+    * Move a byte into the location pointed to by A1 and increment by a byte. 
        RTS                 * Return back to PRINT_ADDR
        
GET_NUM
        ADDI.B  #$30, D7    * HEX to ASCII offset for numbers is #$30
        MOVE.B  D7,(A1)+    * Move a byte into the location pointed to by A1 and increment by a byte
        RTS                 * Return back to PRINT_ADDR

*--------Converts ASCII character values to their HEX representative counter parts
* Takes in each character via pointer incrementation and compares it to #$40. 
* Letters are 41 and greater (A-F) and numbers are #$31 to #$39 so #$40 separates both. 
* The offset for LETTERS and NUMBERS from ASCII to HEX are different so we have to check
* accordingly. 
* Using CMPI.B to the byte, we can tell if it's meant to be A-F or 1-9 in hex. 
* Will take the necessary branch.
*---------------------------------------------------------------------------------------
GET_ADDRESS:             * Main subroutine called to get the hex character
    CLR.L   D3          * Clears anything that might be in D3. (Not significant. I just used D3 to store the converted HEX)
LOOP                    * Loop subroutine to get as many HEX characters that are in length
    MOVE.B  (A1)+, D2   * Load the ASCII character to D2 and auto increment the pointer to point to next ASCII character
    CMPI.B  #$40, D2    * Does the #$40 comparison to check if it's a letter or number. 
    BLT     IS_NUMBER   * Branches to IS_NUMBER subroutine if the comparison is less than (Negative)
    BGT     IS_LETTER   * Branches to IS_LETTER subroutine if the comparison is more than (Positive)
    BEQ     INVALID_INPUT_MSG
BRANCHBACK              * Meant to branch back to either the loop or back to our place in main. 
    SUBI.W  #1, D1      * Subtract 1 from the for-loop variable. 
    BNE     LOOP        * If our for-loop variable is non-zero, we will loop once more. 
    RTS                 * Return back to main if the BNE statement fails. 
        
IS_LETTER               * Subroutine to subtract the offset to convert to HEX. 
    * Check if letter is A-F
    CMPI.B  #$46,D2     * Checking for F and below
    BGT     INVALID_INPUT_MSG   * If greater than hex 46, must be invalid character
    SUBI.B  #$37,D2     * ASCII (Letter) - #$37 = HEX 
    LSL.L   #4, D3      * Shift a hex digit to the left by 1 (1 hex = 4 bits). 
    ADD.B   D2, D3      * Add the newly converted HEX to a byte. Will not overwrite since we're doing an operation on the BYTE. 
    BRA     BRANCHBACK  * Branch back to our GET_ADDRESS subroutine. 
    
IS_NUMBER               * Subroutine to subtract the offset to convert to HEX  
    * Check if number is 0-9
    CMPI.B  #$39,D2     * Checking for 9 and below
    BGT     INVALID_INPUT_MSG   * If greater than hex 46, must be invalid character 
    CMPI.B  #$30,D2     * Checking for 0 and above
    BLT     INVALID_INPUT_MSG   * If less than hex 30, must be invalid character
    SUBI.B  #$30,D2     * ASCII (Number) - #$30 = HEX
    LSL.L   #4, D3      * Shift a hex digit to the left by 1 (1 hex = 4 bits)
    ADD.B   D2, D3      * Add the newly converted HEX to a byte. Will not overwrite since we're doing an operation on the BYTE. 
    BRA     BRANCHBACK  * Branch back to our GET_ADDRESS subroutine.
*------------------------------------------------------------------------------------------------

VALIDATE_ADDRESS_RANGE
    MOVE.L  START_ADDR,D4       * After both addresses both pass initial validation
    CMP.L   D3,D4               * Starting address can't be greater than ending
    BGT     INVALID_INPUT_MSG   * Case where user does this case
    RTS                         * Return back to main

INVALID_INPUT_MSG               * Subroutine to simply print that input was invalid
    LEA INVALID_INPUT, A1       * Load our preset message
    JSR PRINT_ASSEM             * Jump to a subroutine that just executes task 14
    BRA END_PROMP               * Branch to subroutine to await user input
    
CLEAR_SCREEN
    MOVE.W  #$FF00, D1  * Required pre-req
    MOVE.B  #11,D0      * Trap task #1
    TRAP    #15         * Execute
    CLR.L   D1          * D1 is used heavily for other purposes. 
    RTS                 * Return back to main

PROMPT_ENTER    
    LEA PROMPT_MSG, A1  * Load 'prompt' message. 
    JSR PRINT_ASSEM     * Jump to a subroutine that just executes task 14
    MOVE.W  #0, F_LOOP  * Screen should be cleared. Reset F_LOOP
    MOVE.B  #4, D0      * Task 4
    TRAP    #15         * Execute
    RTS                 * Return back to main

DIS_ANOTHER
    LEA RERUN_PROMPT,A1 * Preload message
    JSR PRINT_ASSEM     * Execute task 14
    MOVE.B  #5, D0      * Task 5: Read in a character
    TRAP    #15         * D1 holds a character. 
    CMPI.W  #$59, D1    * #$59 for 'Y' and #$79 for 'y'
    BEQ     RE_RUN
    CMPI.W  #$79, D1 
    BEQ     RE_RUN            
    CMPI.W  #$4E, D1    * #$4E for 'N' and #$6E for 'n'
    BEQ     ENDING
    CMPI.W  #$6E, D1
    BEQ     ENDING  
    JSR     CLEAR_SCREEN    * Any input that's not Y/y or N/n = invalid input
    LEA     WRONG_YN, A1    * Load preset message
    JSR     PRINT_ASSEM     * Print
    BRA     DIS_ANOTHER     * Branch back to the beginning of subroutine
    
*-----Subroutine to allow a "pause" when done disassembling------     
END_PROMP   
    LEA PAUSE_MSG,A1        * Load preset message
    JSR PRINT_ASSEM         * Print out
    MOVE.B  #5, D0          * Read in a character
    TRAP    #15             * Execute: Basically what allows the "pause" 
    JSR     CLEAR_SCREEN    * Subroutine to clear the screen
    BRA     DIS_ANOTHER     * Branch to subroutine to ask user if they want to disassemble another

*-------------------------------------------------------------------- 
* Will print the '.B', '.W', '.L' to print the 
* operands afterwards
*--------------------------------------------------------------------     
PRINT_BYTE
    LEA  opcode_BYTE,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
PRINT_WORD
    LEA  opcode_WORD,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
PRINT_LONG
    MOVE.B  #1, IS_LONG
    LEA  opcode_LONG,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
* Data register number should be put into D1 before hand.  
PRINT_REGIS_NUM
    MOVE.B  #3,D0
    TRAP    #15
    RTS
*----Will just output whatever we load into A1 beforehand-----------
PRINT_ASSEM
    MOVE.B  #14,D0  
    TRAP    #15
    RTS
*-------------------------------------------------------------------- 
PRINT_TAB
    LEA     TAB,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
*--------------------------------------------------------------------

*----Prints a new line--------------------------------------------- 
PRINT_NEWLINE
    LEA     NEWLINE,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
*--------------------------------------------------------------------
    
PRINT_D
    LEA DATA_CHAR, A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
PRINT_A
    LEA ADDR_CHAR, A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
PRINT_COMMA
    LEA COMMA, A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
PRINT_IMM
    LEA     IMM,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
PRINT_HEX
    LEA HEX_SIGN, A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
PRINT_DASH
    LEA DASH,A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
PRINT_SLASH
    LEA SLASH,A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
UNRECOGNIZED_OPCODE
    LEA     UNREC_OPCODE,A1
    MOVE.B  #14,D0
    TRAP    #15
    JSR     PRINT_NEWLINE
    RTS


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
