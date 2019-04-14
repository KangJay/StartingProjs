* Strings purely for displaying
    NOP
    NOP 
    NOP
START_MSG   DC.W    'Input starting memory address: ',0     * Get starting address message
END_MSG     DC.W    'Input ending memory address: ',0       * Get ending address message

MOVE_MSG    DC.B    'MOVE.',0

ADDRESS     DS.L    1

START_ADDR  DS.L    1   *Starting address of disassembling
END_ADDR    DS.L    1   *Ending address of disassembling





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
