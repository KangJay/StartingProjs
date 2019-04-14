    ORG $2000
DUMMY_PLACEHOLDER:
    RTS
    
*-----Sub-routine whose purpose is to determine which opcode it is----
* And branch to various subroutines to decode the remainder of the 
* machine code.
* A0 is the pointer holding the address
* Do MOVE.L (A0)+, Dn since addresses are always at least one long word.
*----------------------------------------------------------------------
DECODE_OPCODE
    MOVE.B  #0, IS_LONG     
    
    MOVE.W (A0)+, D2    * Use D0 to preserve the original machine code. 
    MOVE.W  D2, D3      * Use another Dn to experiment.
    
    AND.W   #$F1C0, D3
    CMPI.W  #$41C0, D3
    BEQ     LEA_BRANCH
    MOVE.W  D2,D3
*--------RTS/NOP check-----------------------------------------
    CMPI.W  #$4E75, D3 * HEX representation of RTS in machine code
    BEQ     RTS_BRANCH * If it matches, jump to the RTS subroutine below
    CMPI.W  #$4E71, D3
    BEQ     NOP_BRANCH
*--------------------------------------------------------------
 
*---------OPCODES REQUIRING 2 HEX TO DECODE
    LSR.W   #$6, D3 *CHECKING FOR JSR
    CMPI.W  #$013A, D3 * Machine code for JSR after getting its set bits
    BEQ     JSR_BRANCH
    
    LSR.W   #$2, D3

    *--------Checking the branch statements-------------------------
    *LSR.L   #8, D3      * Shift right by 8 bits to get left most 2 hex characters

*-------------------------------------------------------------

    CMPI.W  #$60, D3    * Checking BRA
    BEQ     BRA_BRANCH  * Pun fully intended
    
    CMPI.W  #$6E, D3    * Checking JSR AND BGT. They both have #$6E as the leftmost hex characters
    BEQ     BGT_BRANCH
    
    CMPI.W  #$67, D3    * Checking BEQ
    BEQ     BEQ_BRANCH  * Ironic lol
    
    CMPI.W  #$6F, D3    * Checking BLE
    BEQ     BLE_BRANCH
*------------------------------------------- 
    CMPI.W  #$46, D3    * Checking NOT
    BEQ     NOT_BRANCH
       
*---------Decoding the other ones that haven't been---------------
    CMPI.W  #$42, D3
    BEQ     ONE_WORD_UNRECOG
*----------DECODING THE MOVE OPCODES------------------------------    
    CMPI.W  #$4C, D3    * If it's a MOVEM instruction
    BEQ     MOVEM_MTOR
    CMPI.W  #$48, D3
    BEQ     MOVEM_RTOM
    *-------OPCODES THAT REQUIRE 1 HEX TO DECODE (MAY NEED ADDITIONAL TESTING)
    LSR.L   #4, D3      * If it's not MOVEM, it's one of the other moves
    *----MOVEA TEST-----
    CMPI.B  #$3, D3         
    BEQ     MOVEA_BRANCH
    CMPI.B  #$2, D3
    BEQ     MOVEA_BRANCH
    *----MOVE TEST------
    CMPI.B  #$1, D3
    BEQ     MOVE_BRANCH
    *----MOVEQ TEST-----
    CMPI.B  #$7, D3
    BEQ     MOVEQ_BRANCH
    
*------------END OF THE MOVE OPCODES----------------------------
    
*-------------SUB / MULS / DIVU OPCODES ------------------------
    *-----SUB TEST-----
    CMPI.B  #9,D3
    BEQ     SUB_BRANCH
    *-----MULS TEST----
    CMPI.B  #12,D3
    BEQ     MULS_AND_BRANCH
    *-----DIVU TEST----
    CMPI.B  #8,D3
    BEQ     DIVU_OR_BRANCH

*--------------ASL / ASR / LSL / LSR -------------------------
    *If the opcode starts with 'E', it must be a shift.
    CMPI.B  #$E,D3
    BEQ     SHIFT_BRANCH    
    
*---------DECODING THE ADD/ADDA/ADDQ TEST--------------------
    
    *----ADDQ TEST-----
    CMPI.B  #$5, D3 *ADDQ only required opcode starts w/ 5, so don't need to check for dupes
    BEQ     ADDQ_BRANCH
    *----ADD/ADDA TEST-- 
    CMPI.W  #$D, D3 *ADD/ADDA both start with D, check for ADDA in the ADD branch
    BEQ     ADD_BRANCH
    
*------------------------------------------------------------    
    
    *MOVEM would've been caught earlier in this chain. #$4 would be only LEA at this point
    *CMPI.B  #$4, D3
    *BEQ     LEA_BRANCH
    CMPI.B  #$6, D3
    BEQ     UNRECOG_BRANCH
    
    CMPI.B  #$0, D3
    BEQ     HEX0_INSTRUCTIONS
    
    CMPI.B  #$4, D3
    BEQ     HEX4_INSTRUCTIONS
    
    JSR     PRINT_NEWLINE
RETURN_TO_MAIN    
    RTS   
   
MULS_AND_BRANCH
    *Check bits 7/6
    *MULS = 11
    *AND = 00/01/10
    MOVE.W  D2,D3
    LSL.W   #8,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    CMPI.B  #3,D3
    BEQ     MULS_BRANCH
    BLT     AND_BRANCH
    JSR     NOT_IN    
    BRA     RESUME_DIS
    *BGT     UNRECOGNIZED_OPCODE
    
DIVU_OR_BRANCH
    *Check bits 7/6
    *DIVU = 11
    *OR = 00/01/10
    MOVE.W  D2,D3
    LSL.W   #8,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    CMPI.B  #3,D3
    BEQ     DIVU_BRANCH
    BLT     OR_BRANCH
    JSR     NOT_IN    
    BRA     RESUME_DIS
    *BGT     UNRECOGNIZED_OPCODE
    
JSR_BRANCH
    LEA opcode_JSR, A1
    JSR PRINT_ASSEM
    JSR PRINT_TAB
    MOVE.W  D2, D3
    AND.W   #$003F, D3
    JSR DECODE_EA   
    JSR PRINT_NEWLINE
    RTS
*------------------------------------------------
BRA_BRANCH
    LEA opcode_BRA, A1
    JSR PRINT_ASSEM
*    JSR PRINT_TAB
*    JSR PRINT_HEX
    BRA DIS_TO_ADDRESS
    RTS
*------------------------------------------------    
BGT_BRANCH
    LEA opcode_BGT, A1
    JSR PRINT_ASSEM
*    JSR PRINT_TAB
*    JSR PRINT_HEX
    BRA DIS_TO_ADDRESS
    RTS       
*------------------------------------------------
BLE_BRANCH
    LEA opcode_BLE, A1
    JSR PRINT_ASSEM
*    JSR PRINT_TAB
*    JSR PRINT_HEX
    BRA DIS_TO_ADDRESS
    RTS   
*------------------------------------------------
BEQ_BRANCH
    LEA opcode_BEQ, A1
    JSR PRINT_ASSEM
    BRA DIS_TO_ADDRESS
    RTS
*------------------------------------------------
    
*--------BRANCH STATEMENT MEMORY SUBROUTINE-------
* NO JSR. ITS FORMAT IS DIFFERENT
DIS_TO_ADDRESS
    MOVE.W  D2,D3
    CMPI.B  #$00, D3 * BRANCH TO HANDLE 16 BIT (4 HEX)
    *BEQ     BRANCH_WORD_ADDR
    BEQ     BRANCH_WORD
    BEQ     BRANCH_LONG
    *---For displacement that's only 2 hex--------
    BRA     BRANCH_BYTE
BRANCH_WORD
    JSR     PRINT_WORD
    JSR     PRINT_TAB
    JSR     PRINT_HEX
    BRA     BRANCH_WORD_ADDR
    *BRA     BRANCH_CONT
BRANCH_LONG
    JSR     PRINT_LONG
    JSR     PRINT_TAB
    JSR     PRINT_HEX
    BRA     BRANCH_LONG_ADDR
    *BRA     BRANCH_CONT
BRANCH_BYTE    
    JSR     PRINT_BYTE
    JSR     PRINT_TAB
    JSR     PRINT_HEX
    AND.W   #$00FF, D3
    MOVEA.L #ADDRESS, A1
    MOVEA.L A0, A2
    EXT.W   D3
    ADDA.L  D3, A2
    MOVE.L  #28, D6         * D6 to shift to the right by
    MOVE.L  #0, D5          * D5 to shift to the left by
    JSR     PRINT_ADDR
    MOVE.B  #4, D1
    MOVE.B  #1, D0
    ADDA.W  #$4, A1
    TRAP    #15
    JSR     PRINT_NEWLINE
    RTS
*------------------------------------------------

SHIFT_BRANCH
    *Decode shifts based on Register Shift or Memory Shift
    *Register shift: Bits 6/7 = 00/01/10
    *Memory shift: Bits 6/7 = 11
    MOVE.W  D2,D3
    LSL.W   #8,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    CMPI.B  #3,D3   *Identify if it is a Memory Shift
    BEQ     MEMORY_SHIFT
    
    *BGT     UNRECOGNIZED_OPCODE
    BLT     REGISTER_SHIFT
    BRA     ONE_WORD_EA    * Catch unrecognized things.
    BRA     RESUME_DIS
MEMORY_SHIFT
    *Now identify if AS or LS
    *AS: Bits 11/10/9 = 0
    *LS: Bits 11/10/9 = 1
    MOVE.W  D2,D3
    AND.W   #$0028, D3
    BEQ     MEMORY_CONT
    JSR     FORMAT_TEST
MEMORY_CONT
    MOVE.W  D2,D3
    LSL.W   #4,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3   *Identify if it is AS
    BEQ     LS_MEM_BRANCH
    BLT     AS_MEM_BRANCH
    *BGT     UNRECOGNIZED_OPCODE   
    BRA     ONE_WORD_EA
LS_MEM_BRANCH
    *Now identify direction
    *R = 0
    *L = 1
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #15,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3   *Identify it direction is Right
    BEQ     LSL_MEM_BRANCH
    BLT     LSR_MEM_BRANCH
    *BGT     UNRECOGNIZED_OPCODE    
    BRA     ONE_WORD_EA
LSL_MEM_BRANCH
    *Print opword: LSL.W 
    LEA     opcode_LSL,A1
    JSR     PRINT_ASSEM
    JSR     PRINT_WORD
    
    *Now identify EA
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA   
    JSR     PRINT_NEWLINE
    RTS
    
LSR_MEM_BRANCH
    *Print opword: ASR.W 
    LEA     opcode_LSR,A1
    JSR     PRINT_ASSEM
    JSR     PRINT_WORD
    *Now identify EA
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA
    JSR     PRINT_NEWLINE
    RTS
    
    
AS_MEM_BRANCH
    *Now identify direction
    *R = 0
    *L = 1
*    MOVE.W  D2,D3 * ERROR CHECKING
*    AND.W   #$18, D3
*    LSR.W   #$3, D3
*    CMPI.W  #$0, D3
*    BNE     UNRECOGNIZED_OPCODE
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #15,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3   *Identify it direction is Right
    BEQ     ASL_MEM_BRANCH
    BLT     ASR_MEM_BRANCH
    *BGT     UNRECOGNIZED_OPCODE
    BRA     ONE_WORD_EA
    JSR     NOT_IN    
    BRA     RESUME_DIS
ASL_MEM_BRANCH
    *Print opword: ASL.W 
    LEA     opcode_ASL,A1
    JSR     PRINT_ASSEM
    JSR     PRINT_WORD    
    *Now identify EA
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA    
    JSR     PRINT_NEWLINE
    RTS
       
ASR_MEM_BRANCH
    *Print opword: ASR.W 
    LEA     opcode_ASR,A1
    JSR     PRINT_ASSEM
    JSR     PRINT_WORD    
    *Now identify EA
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA    
    JSR     PRINT_NEWLINE
    RTS
    
REGISTER_SHIFT
    *Now identify if AS or LS
    *AS: Bits 4/3 = 0
    *LS: Bits 4/3 = 1
    MOVE.W  D2,D3
    MOVE.B  #11,D4
    LSL.W   D4,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3   *Identify if it is AS
    BEQ     LS_REG_BRANCH
    BLT     AS_REG_BRANCH
    *BGT     UNRECOGNIZED_OPCODE
    BRA     ONE_WORD_EA
    JSR     NOT_IN    
    BRA     RESUME_DIS
LS_REG_BRANCH
    *Now identify direction
    *R = 0
    *L = 1
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #15,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3   *Identify it direction is Right
    BEQ     LSL_REG_BRANCH
    BLT     LSR_REG_BRANCH
    *BGT     UNRECOGNIZED_OPCODE
    BRA     ONE_WORD_EA
    JSR     NOT_IN    
    BRA     RESUME_DIS
LSL_REG_BRANCH
    *Print LSL
    LEA     opcode_LSL,A1
    JSR     PRINT_ASSEM
    BRA     REG_SIZE
    
LSR_REG_BRANCH
    *Print LSL
    LEA     opcode_LSR,A1
    JSR     PRINT_ASSEM
    BRA     REG_SIZE
    
AS_REG_BRANCH
    *Now identify direction
    *R = 0
    *L = 1
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #15,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3   *Identify it direction is Right
    BEQ     ASL_REG_BRANCH
    BLT     ASR_REG_BRANCH
    *BGT     UNRECOGNIZED_OPCODE
    BRA     ONE_WORD_EA
    JSR     NOT_IN    
    BRA     RESUME_DIS
ASL_REG_BRANCH
    *Print ASL
    LEA     opcode_ASL,A1
    JSR     PRINT_ASSEM
    BRA     REG_SIZE

ASR_REG_BRANCH
    *Print ASR
    LEA     opcode_ASR,A1
    JSR     PRINT_ASSEM
    BRA     REG_SIZE
    
REG_SIZE
    *Now identify size
    MOVE.W  D2,D3
    LSL.W   #8,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    CMPI.B  #$1,D3
    BEQ     REG_WORD
    BLT     REG_BYTE
    BGT     REG_LONG
    
REG_BYTE
    JSR     PRINT_BYTE
    BRA     REG_CONT

REG_WORD
    JSR     PRINT_WORD
    BRA     REG_CONT

REG_LONG
    JSR     PRINT_LONG
    BRA     REG_CONT

REG_CONT
    *Now identify Mode (Immediate[0]/Register[1])
    MOVE.W  D2,D3
    MOVE.B  #10,D4
    LSL.W   D4,D3
    MOVE.B  #15,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3
    BEQ     REG_REG
    BLT     REG_IMM
    *BGT     UNRECOGNIZED_OPCODE
    BRA     ONE_WORD_EA
    JSR     NOT_IN    
    BRA     RESUME_DIS
REG_IMM
    *LSL    #<Data>,Dy
    *Print Immediate Address
    JSR     PRINT_IMM
    MOVE.W  D2,D3
    LSL.W   #4,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3
    MOVE.B  D3,D1
    JSR     PRINT_REGIS_NUM
    JSR     PRINT_COMMA
    *Print Destination Register
    JSR     PRINT_D
    MOVE.W  D2,D3
    MOVE.B  #13,D4
    LSL.W   D4,D3
    LSR.W   D4,D3
    MOVE.B  D3,D1
    JSR     PRINT_REGIS_NUM
    
    JSR     PRINT_NEWLINE
    RTS

REG_REG
    *LSL    Dx,Dy
    *Print Dx
    JSR     PRINT_D
    MOVE.W  D2,D3
    LSL.W   #4,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3
    MOVE.B  D3,D1
    JSR     PRINT_REGIS_NUM
    JSR     PRINT_COMMA
    *Print Dy
    JSR     PRINT_D
    MOVE.W  D2,D3
    MOVE.B  #13,D4
    LSL.W   D4,D3
    LSR.W   D4,D3
    MOVE.B  D3,D1
    JSR     PRINT_REGIS_NUM
    
    JSR     PRINT_NEWLINE
    RTS


*-----------DONE NO WORK NEEDED-------------------------
RTS_BRANCH
    LEA opcode_RTS, A1
    JSR PRINT_ASSEM
    JSR PRINT_NEWLINE
    RTS
NOP_BRANCH
    LEA opcode_NOP, A1
    JSR PRINT_ASSEM
    JSR PRINT_NEWLINE
    RTS
*------------------------------------------------------- 

*-----------------------START OF NOT SECTION-------------------------------
NOT_BRANCH
    LEA  opcode_NOT, A1
    JSR  PRINT_ASSEM
    MOVE.W  D2,D3
    LSL.W   #7,D3
    LSR.W   #8,D3
    LSR.W   #5,D3
    CMPI.B  #1,D3
    BEQ     NOT_WORD
    BLT     NOT_BYTE
    BGT     NOT_LONG
    RTS

NOT_BYTE
    JSR     PRINT_BYTE
    BRA     NOT_CONT
NOT_WORD
    JSR     PRINT_WORD
    BRA     NOT_CONT
NOT_LONG   
    JSR     PRINT_LONG
    BRA     NOT_CONT
NOT_CONT
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA
    JSR     PRINT_NEWLINE
    RTS
*-----------------------START OF ADD SECTION-------------------------------
ADDQ_BRANCH
    LEA     opcode_ADDQ, A1
    JSR     FORMAT_TEST
    MOVE.W  D2,D3
    LSL.W   #8,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    JSR     PRINT_ASSEM
    CMPI.B  #$1,D3
    BEQ     ADDQ_WORD
    BLT     ADDQ_BYTE
    BGT     ADDQ_LONG
ADDQ_BYTE
    JSR     PRINT_BYTE
    BRA     ADDQ_CONT
ADDQ_WORD
    JSR     PRINT_WORD
    BRA     ADDQ_CONT
ADDQ_LONG
    JSR     PRINT_LONG
    BRA     ADDQ_CONT
ADDQ_CONT
    *EA stuff here
    MOVE.W  D2,D3
    AND.W   #$0E00,D3
    LSR.W   #$8,D3
    LSR.W   #$1,D3
    MOVE.L  D3,D1
    JSR     PRINT_IMM
    JSR     PRINT_REGIS_NUM
    JSR     PRINT_COMMA     
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA * Isolate the EA bits and call this subroutine
    JSR     PRINT_NEWLINE
    BRA     RETURN_TO_MAIN


ADD_BRANCH
    JSR     FORMAT_TEST
    MOVE.W  D2,D3
    LSL.W   #7,D3
    LSR.W   #7,D3
    LSR.W   #6,D3
    CMPI.B  #$3,D3
    BEQ     ADDA_BRANCH
    CMPI.B  #$7,D3
    BEQ     ADDA_BRANCH
    LEA     opcode_ADD, A1
    JSR     PRINT_ASSEM
    MOVE.W  D2,D3
    JSR     ADD_SIZES
    RTS

ADD_SIZES
    MOVE.W  D2,D3
    LSL.W   #8,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3
    BEQ     AND_WORD
    BLT     AND_BYTE
    BGT     AND_LONG
    
ADD_BYTE
    JSR     PRINT_BYTE
    BRA     ADD_CONT
ADD_WORD
    JSR     PRINT_WORD
    BRA     ADD_CONT
ADD_LONG
    JSR     PRINT_LONG
    BRA     ADD_CONT    
ADD_CONT
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #15,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3
    BEQ     ADD_EA
    BNE     ADD_DIR
    
ADD_EA
    MOVE.W  D2,D3
    AND.W   #$0E00,D3 *0000 1110 0000 0000
    LSR.W   #$8,D3
    LSR.W   #$1,D3
    CLR.L   D1
    MOVE.L  D3,D1  
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction
    JSR     PRINT_COMMA
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA 
    JSR     PRINT_NEWLINE
    RTS

ADD_DIR
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA
    JSR     PRINT_COMMA
    MOVE.W  D2,D3
    AND.W   #$0E00,D3
    LSR.W   #$8,D3
    LSR.W   #$1,D3
    MOVE.L  D3,D1  
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction
    JSR     PRINT_NEWLINE
    RTS
ADDA_BRANCH
    LEA     opcode_ADDA, A1
    JSR     PRINT_ASSEM
    CMPI.B  #$3,D3
    BEQ     ADDA_WORD
    BNE     ADDA_LONG
ADDA_WORD
    JSR     PRINT_WORD
    BRA     ADDA_CONT
ADDA_LONG
    JSR     PRINT_LONG
    BRA     ADDA_CONT
ADDA_CONT
    *Do EA stuff
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA
    JSR     PRINT_COMMA    
    MOVE.W  D2,D3
    AND.W   #$0E00,D3
    LSR.W   #$8,D3
    LSR.W   #$1,D3
    MOVE.L  D3,D1  
    JSR     PRINT_A
    JSR     PRINT_REGIS_NUM
    JSR     PRINT_NEWLINE  
    RTS
*-----------------------END OF ADD SECTION------------------------------- 
 
 
*-----------------------START OF MOVE SECTION------------------------------------------------------------   
MOVEA_BRANCH
    MOVE.W  D2,D3
    LSL.W   #7,D3
    LSR.W   #7,D3
    LSR.W   #6,D3
    CMPI.W  #1,D3       * All the shifts and this comparison is to check bits 8-6 to differentiate MOVEA vs MOVE
    BNE     MOVE_BRANCH * If the set bit in the MOVEA instruction isn't it, it is a MOVE instruction
    LEA     opcode_MOVEA, A1
    JSR     PRINT_ASSEM *Print MOVEA
    MOVE.W  D2, D3      *Reset bits for printing the size
    JSR     MOVE_SIZES  *Jump to the size subroutine
    RTS
    
MOVE_BRANCH
    LEA     opcode_MOVE, A1
    MOVE.W  D2, D3
    JSR     PRINT_ASSEM
    JSR     MOVE_SIZES
    RTS
    
    
MOVEQ_BRANCH
    LEA     opcode_MOVEQ, A1    *Print the MOVEQ opword
    JSR     PRINT_ASSEM
    JSR     PRINT_TAB   
    MOVE.W  D2,D3   
    CLR.L   D1              * Incase there's something already in D1 for trap task #3
    MOVE.B  D3, D1          * Data is located in the first byte
    LEA     DEC_SIGN,A1     * Print the '#' symbol for immediate values
    JSR     PRINT_ASSEM     * Print the '#' symbol ^
    MOVE.B  #3,D0           * Set trap task to 3, print a decimal signed number
    TRAP    #15             * Print out the immediate value
    LEA     COMMA, A1       * Load a comma into A1. Literally. 
    JSR     PRINT_ASSEM     * Used to print the comma only
    LSL.W   #4, D3
    LSR.W   #5, D3          * Get only the Data register number
    LSR.W   #8, D3          * ^
    MOVE.B  D3, D1          * D7 holds the array index which holds the register number. 
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction
    JSR     PRINT_NEWLINE   * Print a newline character
    RTS                     * Return back to main
*--------------------------------------------------
MOVEM_MTOR
    JSR MOVEM_SIZE
    MOVE.W  (A0)+, REGIS_VAR    * Will hold the mask bits
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR DECODE_EA
    JSR PRINT_COMMA
    JSR MOVEMPOST_INC
    JSR PRINT_NEWLINE
    RTS   
MOVEM_RTOM  
    JSR MOVEM_SIZE
    MOVE.W  (A0)+, REGIS_VAR 
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    LSR.W   #$3, D3
    CMPI.B  #$4, D3
    BEQ     MOVEM_PREDEC
    JSR     MOVEMPOST_INC
    BRA     MOVEM_CONT1
MOVEM_PREDEC
    JSR     MOVEMPRE_DEC
MOVEM_CONT1    
    JSR PRINT_COMMA
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR DECODE_EA
    JSR PRINT_NEWLINE
    RTS
    
MOVEM_SIZE
    LEA opcode_MOVEM,A1 * Print the opcode
    JSR     PRINT_ASSEM
    MOVE.W  D2,D3   *Reset to get the size
    AND.W   #$0040, D3
    LSR.W   #$6, D3
    CMPI.B  #1, D3
    BEQ MOVEM_LONG
MOVEM_WORD
    JSR PRINT_WORD
    BRA MOVEM_CONT    
MOVEM_LONG
    JSR PRINT_LONG
MOVEM_CONT
    JSR PRINT_TAB
    RTS
* Use REGIS_VAR for original. D4 for shifts. 
MOVEMPOST_INC
    *--A7-0, D7-0---
    MOVE.W  REGIS_VAR, D4
    CMPI.B  #0, D4  * No data registers are being moved    
    BEQ     MOVEM_A_ONLY
    MOVE.B  #-1, D1 * Will represent the data register number. Should be -1 to start with
    *--------------------------------
    * Have to find the first data register and test then. 
    * JSR MOVEM_PRINTDATA    
MOVEM_D_BACK    
    MOVE.W  REGIS_VAR, D4
    JSR     GET_FIRST
    CMPI.B  #8, D1
    BEQ     MOVEM_A     *Iterated through all registers
    JSR     MOVEM_PRINTDATA
    CMPI.B  #7, D1
    BEQ     MOVEM_A
    *Registers below the 7th
    MOVE.B  #0, D3
    JSR GET_CHAIN
    CMPI.B  #0, D3
    BGT     PRINT_CHAIN
    CMPI.B  #7, D1
    BEQ     MOVEM_A
    ADDI.B  #1, D1
    MOVE.W  REGIS_VAR, D4
    LSR.B   D1, D4
    CMPI.B  #0, D4
    BEQ     MOVEM_A    
    JSR     PRINT_SLASH
    BRA     MOVEM_D_BACK    
MOVEM_A     *reflect for Adress registers
    MOVE.W  REGIS_VAR, D4
    LSR.W   #$8, D4 * If there's no Address registers
    CMPI.B  #$0, D4
    BEQ     MOVEM_END   
    * Else it's a mix of Dn + An, so print a slash    
    JSR     PRINT_SLASH

MOVEM_A_ONLY
    MOVE.W  REGIS_VAR, D4
    LSR.W   #$8, D4
    MOVE.W  D4, REGIS_VAR   * Don't need the Dn bits anymore
    MOVE.B  #-1, D1 * Represents the An number
MOVEM_A_BACK
    JSR     GET_FIRST
    CMPI.B  #8, D1
    BEQ     MOVEM_END
    JSR MOVEM_PRINTADD
    CMPI.B  #7, D1
    BEQ     MOVEM_END
    * Registers below the 7th
    MOVE.B  #0, D3
    JSR     GET_CHAIN
    CMPI.B  #0, D3
    BGT     PRINT_ACHAIN
    CMPI.B  #7, D1
    BEQ     MOVEM_END
    ADDI.B  #1, D1    
    MOVE.W  REGIS_VAR, D4
    LSR.B   D1, D4
    CMPI.B  #0, D4
    BEQ     MOVEM_A    
    JSR     PRINT_SLASH
    BRA     MOVEM_A_BACK   
MOVEM_END
    RTS

PRINT_ACHAIN
    JSR PRINT_DASH
    ADD.B   D3,D1
    JSR MOVEM_PRINTADD
    MOVE.W  REGIS_VAR, D4
    LSR.B   D1, D4
    LSR.B   #1, D4
    CMPI.B  #0, D4
    BEQ     MOVEM_END
    JSR     PRINT_SLASH
    BRA     MOVEM_A_BACK
    
PRINT_CHAIN
    JSR PRINT_DASH
    ADD.B   D3, D1
    JSR MOVEM_PRINTDATA
    MOVE.W  REGIS_VAR, D4
    LSR.B   D1, D4
    LSR.B   #1, D4
    CMPI.B  #0, D4
    BEQ     MOVEM_A
    JSR     PRINT_SLASH
    BRA MOVEM_D_BACK
    
GET_CHAIN
    MOVE.W  REGIS_VAR, D4
    LSR.B   D1, D4
    LSR.B   D3, D4
    LSR.B   #1, D4
    AND.B   #$01, D4
    CMPI.B  #$1, D4
    BEQ     INC_CHAIN
    RTS
    
INC_CHAIN
    ADDI.B  #1, D3 
    BRA     GET_CHAIN

*-------Will Shift until getting the next data register---------------
* D1 should have -1 in it initially for shifting arithmetic. 
* Once it finds a register, it'll return back but set D1 accordingly. 
* Used to find the first register. 
*---------------------------------------------------------------------
GET_FIRST
    CMPI.B  #8, D1
    BEQ     GET_FIRST_QUIT
    MOVE.W  REGIS_VAR, D4
    ADDI.B  #1, D1
    LSR.B   D1, D4
    AND.B   #$1, D4     * Get only the 0th bit
    CMPI.B  #0, D4
    BEQ     GET_FIRST
GET_FIRST_QUIT
    RTS
       
CHECK_MAX_D
    CMPI.B  #$7, D1
    BEQ     MOVEM_A
    RTS   
MOVEM_PRINTDATA *The two MOVEM_PRINT subroutines assume the regis num is in D1
    JSR PRINT_D
    JSR PRINT_REGIS_NUM
    RTS
MOVEM_PRINTADD
    JSR PRINT_A
    JSR PRINT_REGIS_NUM
    RTS    
  
MOVEMPRE_DEC    
    MOVE.B  #0, D1
REV_LOOP *Going to use D0 as a holder variable. 
    MOVE.W  REGIS_VAR, D0 *  Reset
    LSR.W   D1, D0
    AND.W   #$0001, D0
    LSL.W   #1, D4
    OR.W    D0, D4
    ADDI.B  #1, D1
    CMPI.B  #15, D1
    BLE     REV_LOOP
    MOVE.W  D4, REGIS_VAR
    JSR     MOVEMPOST_INC
    RTS

*----------------------------END OF MOVE SECTION-------------------------------------
    
LEA_BRANCH
    MOVE.W  D2,D3
    AND.W   #$01C0, D3  * Checking if it really is LEA
    LSR.W   #$6, D3
    CMPI.B  #$7, D3
    BNE UNRECOGNIZED_OPCODE
    MOVE.W  D2,D3
    LEA opcode_LEA,A1
    JSR PRINT_ASSEM
    JSR PRINT_TAB       
    AND.W   #$003F, D3  * Get the EA
    JSR     DECODE_EA   * Decode and print EA
    JSR     PRINT_COMMA * Print comma
    MOVE.W  D2,D3       * Reset
    AND.W   #$0E00, D3
    LSR.W   #$8, D3
    LSR.W   #$1, D3
    OR.W    #$8, D3
    JSR     DECODE_EA
    JSR     PRINT_NEWLINE
    RTS
    
SUB_BRANCH
    JSR FORMAT_TEST
    MOVE.W  D2,D3
    AND.W   #$01C0, D3
    LSR.W   #$6, D3
    CMPI.B  #$3, D3
    BEQ     ONE_WORD_EA
    CMPI.B  #$7, D3
    BEQ     ONE_WORD_EA
    LEA opcode_SUB, A1
    JSR PRINT_ASSEM
    
    * Isolate and Print Size
    MOVE.W  D2,D3
    LSL.W   #8,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    CMPI.B  #$1,D3
    BEQ     SUB_WORD
    BLT     SUB_BYTE
    BGT     SUB_LONG
    RTS
    
SUB_BYTE
    JSR     PRINT_BYTE
    BRA     SUB_DIRECTION

SUB_WORD
    JSR     PRINT_WORD
    BRA     SUB_DIRECTION

SUB_LONG
    JSR     PRINT_LONG
    
SUB_DIRECTION
    * Isolate the direction. Based on direction, print accordingly
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #15,D4
    LSR.W   D4,D3
    CMPI.B  #0,D3
    * Destination -- Source -> Destination
    * Direction 0 = Source = EA = Print EA First
    BNE     SUBD1
    * Print out EA first then Dn    
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA
    JSR     PRINT_COMMA
    
    MOVE.W  D2,D3
    AND.W   #$0E00, D3
    LSR.W   #$8, D3
    LSR.W   #$1, D3
    JSR     DECODE_EA
*    LSL.W   #4,D3
*    MOVE.B  #13,D4
*    LSR.W   D4,D3 
*    MOVE.B  D3,D7
*    JSR     PRINT_D         * Prints 'D' literally
*    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction

    JSR     PRINT_NEWLINE
    RTS
    
SUBD1
    * Direction 1 = Source = Dn = Print Dn First
    MOVE.W  D2,D3
    LSL.W   #4,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3 
    MOVE.B  D3,D1
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction
    JSR     PRINT_COMMA    

    MOVE.W  D2,D3
    *MOVE.W  #10,D4
    *LSL.W   D4,D3
    *LSR.W   D4,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA
    
    JSR     PRINT_NEWLINE
    RTS
    
MULS_BRANCH
    * Print OpCode
    LEA     opcode_MULS, A1
    JSR     PRINT_ASSEM
    
    * Need to confirm that this is MULS and not MULU
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3
    CMPI.B  #7,D3
    BNE     UNRECOGNIZED_OPCODE
    
    * Print EA then print Dn
    MOVE.W  D2,D3
    MOVE.W  #10,D4
    LSL.W   D4,D3
    LSR.W   D4,D3
    JSR     DECODE_EA
    JSR     PRINT_COMMA    
    
    MOVE.W  D2,D3
    LSL.W   #4,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3 
    MOVE.B  D3,D7
    MOVE.B  D7, D1
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction

    JSR     PRINT_NEWLINE
    RTS    

DIVU_BRANCH
    * Print OpCode
    LEA     opcode_DIVU, A1
    JSR     PRINT_ASSEM

    * Need to confirm that this is DIVU and not DIVS
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3
    CMPI.B  #3,D3
    BNE     UNRECOGNIZED_OPCODE
    
    * Print EA then print Dn
    MOVE.W  D2,D3
    AND.W   #$003F, D3
    JSR     DECODE_EA
    JSR     PRINT_COMMA    
    MOVE.W  D2,D3
    AND.W   #$0E00, D3
    LSR.L   #8, D3
    LSR.L   #1, D3
    MOVE.L  D3, D1
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction
    JSR     PRINT_NEWLINE
    RTS
AND_BRANCH
    JSR     FORMAT_TEST
    LEA     opcode_AND,A1
    JSR     PRINT_ASSEM
    
    *Isolate Size
    MOVE.W  D2,D3
    LSL.W   #8,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3
    BEQ     AND_WORD
    BLT     AND_BYTE
    BGT     AND_LONG
    
AND_BYTE
    JSR     PRINT_BYTE
    BRA     AND_CONT
    
AND_WORD
    JSR     PRINT_WORD
    BRA     AND_CONT
    
AND_LONG
    JSR     PRINT_LONG
    
AND_CONT
    *Isolate Direction
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #15,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3
    BEQ     AND_EA
    BLT     AND_DEST
    BGT     UNRECOGNIZED_OPCODE
    
AND_EA
    *<ea> * Dn -> <ea>
    *Print Dn first then EA    
    MOVE.W  D2,D3
    LSL.W   #4,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3 
    MOVE.B  D3,D1
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction
    JSR     PRINT_COMMA

    MOVE.W  D2,D3
    MOVE.W  #10,D4
    LSL.W   D4,D3
    LSR.W   D4,D3
    JSR     DECODE_EA

    JSR     PRINT_NEWLINE
    RTS
    
AND_DEST
    *Dn * <ea> -> Dn
    *Print EA first then Dn
    MOVE.W  D2,D3
    MOVE.W  #10,D4
    LSL.W   D4,D3
    LSR.W   D4,D3
    JSR     DECODE_EA
    JSR     PRINT_COMMA    
    
    MOVE.W  D2,D3
    LSL.W   #4,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3  
    MOVE.B  D3,D1
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction  
    
    JSR     PRINT_NEWLINE
    RTS

OR_BRANCH
    LEA     opcode_OR,A1
    JSR     PRINT_ASSEM
    
    *Isolate Size
    MOVE.W  D2,D3
    LSL.W   #8,D3
    MOVE.B  #14,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3
    BEQ     OR_WORD
    BLT     OR_BYTE
    BGT     OR_LONG
    
OR_BYTE
    JSR     PRINT_BYTE
    BRA     AND_CONT
    
OR_WORD
    JSR     PRINT_WORD
    BRA     AND_CONT
    
OR_LONG
    JSR     PRINT_LONG
    
OR_CONT
    *Isolate Direction
    MOVE.W  D2,D3
    LSL.W   #7,D3
    MOVE.B  #15,D4
    LSR.W   D4,D3
    CMPI.B  #1,D3
    BEQ     OR_EA
    BLT     OR_DEST
    BGT     UNRECOGNIZED_OPCODE
    
OR_EA
    *<ea> * Dn -> <ea>
    *Print Dn first then EA    
    MOVE.W  D2,D3
    LSL.W   #4,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3 
    MOVE.B  D3,D1
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction
    JSR     PRINT_COMMA
    
    MOVE.W  D2,D3
    MOVE.W  #10,D4
    LSL.W   D4,D3
    LSR.W   D4,D3
    JSR     DECODE_EA

    JSR     PRINT_NEWLINE
    RTS
    
OR_DEST
    *Dn * <ea> -> Dn
    *Print EA first then Dn
    MOVE.W  D2,D3
    MOVE.W  #10,D4
    LSL.W   D4,D3
    LSR.W   D4,D3
    JSR     DECODE_EA
    JSR     PRINT_COMMA
    
    MOVE.W  D2,D3
    LSL.W   #4,D3
    MOVE.B  #13,D4
    LSR.W   D4,D3  
    MOVE.B  D3,D1
    JSR     PRINT_D         * Prints 'D' literally
    JSR     PRINT_REGIS_NUM * Prints the register number. Coupled with the previous instruction   
    
    JSR     PRINT_NEWLINE
    RTS
    

*----Sub-routine used to make the DESINATION BITS ( REGISTER | MODE ) into the same format---------
* As the SOURCE bits ( MODE | REGISTER ). This'll make our decode_EA subroutine located in the 
* proper file easier to do since we don't have to check for two different cases. 
* This subroutine should be JSR'd to when we're decoding the destination EA. 
* So it should be... Isolate the SOURCE bits, JSR to decode_EA, print a comma, isolate the DESTINATION
* bits, JSR to THIS subroutine, then JSR to decode_EA. 
*-----------------------------------------------------------------------------------------------------
DEST_TO_SOURCEEA
    LSL.L   #$8, D3 * The two LSL.L shifts are to split the 6 bits in half on the 15th bit divider. 
    LSL.L   #$5, D3 * So the MODE and REGISTER are technically in two different bytes in the register
    LSR.W   #$8, D3 * Shift the MODE bits all the way to the right with these two LSR.W shifts
    LSR.W   #$5, D3
    SWAP    D3      * Swap the bytes
    LSL.W   #$8, D3 * Concatenate the two bits now but they're in opposite order
    LSL.W   #$5, D3 * Same as above
    LSR.L   #$8, D3 * Shift the flipped MODE and REGISTER bits all the way to the right now
    LSR.L   #$5, D3  * D4 will now contain the DESTINATION bits in swapped order
    RTS
*-----------------------------------------------------------------------------------------------------


*--Sub-routine used to print the sizes of MOVE and MOVEA since they share the same sizing-------------
MOVE_SIZES
    LSR.L   #$8,D3  * Isolate the bits determining the size
    LSR.L   #$4,D3  * Same as above
    CMPI.B  #$2, D3 * Compare it with immediate value 2 which represents a LONG
    BEQ     MOVE_LONG   * If it's equal, print LONG
    BLT     MOVE_BYTE   * If it's less than, print BYTE
    BGT     MOVE_WORD   * If it's greater than, print WORD
MOVE_BYTE
    JSR     PRINT_BYTE
    BRA     MOVE_CONT
MOVE_LONG
    JSR     PRINT_LONG
    BRA     MOVE_CONT
MOVE_WORD
    JSR     PRINT_WORD
MOVE_CONT
    JSR     MOVE_MOVEA_EA   * Jump to subroutine to print the source and destination operands
    JSR     PRINT_NEWLINE   * Print an newline. 
    RTS  
MOVE_MOVEA_EA
    MOVE.W  D2, D3
    AND.W   #$003F, D3
    JSR     DECODE_EA
    JSR     PRINT_COMMA
    MOVE.W  D2,D3
    AND.W   #$0FC0, D3
    LSR.W   #$6, D3
    JSR     DEST_TO_SOURCEEA
    JSR     DECODE_EA
    RTS
*--------------------------------------------------------------------------------
























































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
