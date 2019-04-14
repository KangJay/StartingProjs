
*-----------------------------------------------------------
* Title      : Disassembler
* Written by : Low Expectations
* Date       : 17th Oct 18
* Description: Program written in Assembly Language for Motorola's 68K 
* CPU architecture. It will iterate through a starting and ending address 
* and take in a word of data at a time and utilize shifts, AND's, and branch statements
* as well as preset strings to display the information in a formatted fashion. 
*-----------------------------------------------------------
*************************
*   Global Constants
*   Starting and Ending memory address length saved at D2/D3 respectively
*   Starting and Ending memory address string saved at A2/A3 respectively
*************************

ADDR EQU $2000
*************************
*   Main
*   Handles reading starting/ending address
*   Send machine language opword to disassembler function
*************************
    INCLUDE 'opcode_strings.x68'
    INCLUDE 'subroutines.x68'
    INCLUDE 'EA_subroutine.x68'
    INCLUDE 'Invalid_Instructions.x68'
    INCLUDE 'IOMessages.x68'
    INCLUDE 'Disassembler_subroutines.x68'

START:  ORG     $1000             ; first instruction of program
        MOVE.B  #0, IS_LONG
        
RE_RUN
        MOVE.W  #0, F_LOOP
        JSR     CLEAR_SCREEN
        LEA     STARTUP_MSG, A1
        JSR     PRINT_ASSEM
        *------GET THE STARTING ADDRESS------------
        LEA     START_MSG,A1        * Prompt the user for starting address
        JSR     PRINT_ASSEM         * Print starting message
        LEA     PLACEHOLDER,A1      * So we don't override the START_MSG
        MOVE.B  #2,D0               * Read in string (Trap function 2)
        TRAP    #15                 * A2 WILL HOLD THE STRING VERSION OF OUR HEX ADDRESS
        CMPI.B  #6,D1               * Simulator only let's you go to 00FFFFFF so max length is 6
        BGT     INVALID_INPUT_MSG   * If so, branch to subroutine and restart
        JSR     GET_ADDRESS         * D1 Holds the length of the string
        MOVE.L  D3,START_ADDR       * Store the starting address        
        *------GET THE ENDING ADDRESS------------
        LEA     END_MSG,A1          * Prompt user for ending address
        MOVE.B  #14, D0             * Display message (Trap function 14)
        TRAP    #15                 * Execute Trap task
        LEA     PLACEHOLDER, A1     * So we don't override the END_MSG
        MOVE.B  #2, D0              * Read in string (Trap function 2)
        TRAP    #15                 * Execute Trap task
        CMPI.B  #6,D1               * Simulator only let's you go to 00FFFFFF so max length is 6
        BGT     INVALID_INPUT_MSG   * If so, branch and restart
        JSR     GET_ADDRESS         * Get the hex representation of hex address
        JSR     VALIDATE_ADDRESS_RANGE  * Checks that starting address is less than ending address
        MOVE.L  D3,END_ADDR         * Store the ending address
        JSR     CLEAR_SCREEN        * Clear the screen and start disassembling        
        *------BEGIN DISASSEMBLER---------------
        MOVEA.L START_ADDR, A0  * A0 = pointer to iterate through addresses
DIS_BRANCH
        MOVEA.L A0, A2          * Preload address to A2 (Used by PRINT_ADDR)
        MOVE.B  #0, D5          * Offset to shift the hex address by
        MOVEA.L #ADDRESS, A1    * Where we'll store the string
        MOVE.B  #28,D6          * Shift the bits right by 28 spots to isolate the hex
        JSR     PRINT_ADDR      * Loads the string representing the address
        JSR     PRINT_ASSEM     * Print
        JSR     PRINT_TAB       * Print a tab
        JSR     DECODE_OPCODE   * Subroutine to decode machine code at given address
        ADDI.W  #1, F_LOOP      * Decode 31 instructions on screen, pause, prompt, and display 31 more. 
        CMPI.W  #31, F_LOOP     * If it's equal, we need to clear the screen before continuing
        BEQ     PROMPT_MAIN     * In subroutines.x68
        BRA     MAIN_CONT       * Else: Continue past
PROMPT_MAIN * We need to be able to jump back (This subroutine is used in multiple places)
        JSR     PROMPT_ENTER    
MAIN_CONT
        *----------Start of DISASSEMBLING--------------------
RESUME_DIS
        CMP.L   END_ADDR, A0    * Compare current address
        BLE     DIS_BRANCH      * Less than or equal to, branch back to DIS_BRANCH
        BRA     END_PROMP       * Once start address > ending address, we're done. 
ENDING        
        JSR     PRINT_NEWLINE   
        LEA     ENDING_MSG, A1
        JSR     PRINT_ASSEM
        
        SIMHALT 
        
F_LOOP  DS.W    1 
IS_LONG DS.B    1 * if the immediate data EA should read in a word or long. If this var is 0, it's word, 1 = long    
        
DUMMY_PLACEHOLDER123    * Bug??
    RTS
    
TEMP_VAR    DC.W    1
REGIS_VAR   DC.W    1
MOVEM_LOOP  DC.B    1        
        END    START        ; last line of source





























































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
