*Op code messages
CR      EQU     $0D
LF      EQU     $0A
HT      EQU     $09
*-----------MOVE OPCODE GROUP-----------------
opcode_MOVE	    DC.B	'MOVE',0
opcode_MOVEM	DC.B	'MOVEM',0
opcode_MOVEA    DC.B    'MOVEA',0
opcode_MOVEQ    DC.B    'MOVEQ',0
*---------------------------------------------

*--------------SIZE GROUP---------------------
opcode_BYTE     DC.B    '.B',HT,0
opcode_WORD     DC.B    '.W',HT,0
opcode_LONG     DC.B    '.L',HT,0
*---------------------------------------------

*------------------RTS/NOP--------------------
opcode_RTS      DC.B    'RTS',0
opcode_NOP      DC.B    'NOP',0
*---------------------------------------------

*--------------BRANCH + Bcc-------------------
opcode_BRA      DC.B    'BRA',0
opcode_JSR      DC.B    'JSR',0
opcode_BGT      DC.B    'BGT',0
opcode_BEQ      DC.B    'BEQ',0
opcode_BLE      DC.B    'BLE',0
*---------------------------------------------

*--------------SHIFTS-------------------------
opcode_ASL      DC.B    'ASL',0
opcode_ASR      DC.B    'ASR',0
opcode_LSR      DC.B    'LSR',0
opcode_LSL      DC.B    'LSL',0
*---------------------------------------------

*--------------ARITHMETIC---------------------
opcode_ADD      DC.B    'ADD',0
opcode_ADDA     DC.B    'ADDA',0
opcode_ADDQ     DC.B    'ADDQ',0
opcode_SUB      DC.W    'SUB',0
SUB             DC.B    'SUB',0
opcode_MULS     DC.B    'MULS.W',HT,0
opcode_DIVU     DC.B    'DIVU.W',HT,0
*---------------------------------------------
opcode_LEA      DC.B    'LEA',0
*----------AND/OR/NOT-------------------------
opcode_AND      DC.B    'AND',0
opcode_OR       DC.B    'OR',0
opcode_NOT      DC.B    'NOT',0
*---------SELF EXPLANATORY--------------------
DEC_SIGN        DC.B    '#',0
HEX_SIGN        DC.B    '$',0
BIN_SIGN        DC.B    '#%',0
*---------------------------------------------
WORD_ZERO       DC.B    '0000',0
LONG_ZERP       DC.B    '00000000',0
*---------------------------------------------
REGIS_ARRAY     DC.B    '01234567',0
*---------------------------------------------
DATA_CHAR       DC.B    'D',0
ADDR_CHAR       DC.B    'A',0
*---------------------------------------------
COMMA           DC.B    ',',0
IMM             DC.B    '#',0
*---------------------------------------------
NEWLINE         DC.B    CR,LF,0 
TAB             DC.B    HT,0 
DASH            DC.B    '-',0
SLASH           DC.B    '/',0    
*---------------------------------------------
UNREC_OPCODE    DC.B    'There is an unrecognized opcode at this address',0
INVALID_INPUT   DC.B    'Invalid input. Please re-enter addresses',CR,LF,0
PROMPT_MSG      DC.B    'Press enter (CR) to continue disassembling:',0 
STARTUP_MSG     DC.B    'To begin disassembling, please enter the starting and ending HEX-addresses.',CR,LF
                DC.B    'Please enter letters in all CAPS!',CR,LF,0
RERUN_PROMPT    DC.B    'Disassemble another?',CR,LF               
                DC.B    'Enter Y for yes or N to quit: ',0
WRONG_YN        DC.B    'Not Y or N. Please Re-enter',CR,LF,0

LEFT_PAREN      DC.B    '(',0
RIGHT_PAREN     DC.B    ')',0
PLUS            DC.B    '+',0
MINUS           DC.B    '-',0

INVALID_INSTR   DC.B    'DATA',0
PAUSE_MSG       DC.B    'Press any key to continue: ', 0

ENDING_MSG      DC.B    'Disassembler made by Low_Expectations. Thank you.',CR,LF,0
PLACEHOLDER     DS.L    2



















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
