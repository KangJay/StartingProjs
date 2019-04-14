*****************************
*
* demo_test.X68
*
* Created 03/08/2017
*
* Test program for CSS 422 Disassembler Project Demo
*
*****************************

start		EQU	$00009000	* ORG and END address

* ORG the program so that it straddles the address boundary $00007FFF to $00008000

		ORG	start
        BRA     $900A
        BEQ     $900A
        BGT     $900A
        NOP
    MOVEM.W   A1-A7,-(A1)
    MOVEM.W   D0/D2-D4/D6-D7, -(A1)
    MOVEM.W   D0/D2-D4/D6-D7/A0/A2-A5/A7, -(A1)
    MOVEM.L   D1-D7,-(A1)
    MOVEM.W   A1/D7,-(A1)
    MOVEM.L   A1/D7,-(A1)
    MOVEM.W   A1-A7,(A1)
    MOVEM.L   D1/D3/D5-D7,(A1)
    MOVEM.W   A1/D7,(A1)
    MOVEM.L   A1/D7,(A1)
    MOVEM.W   (A1)+,A1-A7
    MOVEM.L   (A1)+,D1/D4/D5-D7
    MOVEM.W   (A1)+,A1/D7
    MOVEM.L   (A1)+,A1/D7
    MOVEM.W   (A1),A1-A7
    MOVEM.L   (A1),D1-D7
    MOVEM.W   (A1),A1/D7
    MOVEM.L   (A1),A1/D7
    MOVEA.W    D0,A0
    MOVEA.W    A0,A0
    MOVEA.W    (A0),A0
    MOVEA.W    (A0)+,A0
    MOVEA.W    -(A0),A0
    MOVEA.L    D0,A0
    MOVEA.L    A0,A0
    MOVEA.L    (A0),A0
    MOVEA.L    (A0)+,A0
    MOVEA.L    -(A0),A0  
    ADD.B     D1,D2
    ADD.B     D1,(A1)
    ADD.B     D1,(A1)+
    ADD.B     D1,-(A1)
    ADD.B     (A1),D1
    ADD.B     (A1)+,D1
    ADDI.L    #$12345678,D1
    ADDI.L    #$12345678,(A0)
    ADDI.L    #$12345678,(A0)+
    ADDI.L    #$12345678,-(A0)
    ADDI.L    #$12345678,$1234
    ADDI.L    #$12345678,$12345678
    MOVEM.W   A1-A7,$12
    MOVEM.L   D1-D7,$12
    MOVEM.W   A1/D7,$12
    MOVEM.L   A1/D7,$12
    MOVEM.W   A1-A7,$1234
    MOVEM.L   D1-D7,$1234
    MOVEM.W   A1/D7,$1234
    MOVEM.L   A1/D7,$1234
    MOVEM.W   A1-A7,$12345678
    MOVEM.L   D1-D7,$12345678
    MOVEM.W   A1/D7,$12345678
    MOVEM.L   A1/D7,$12345678
    MOVEM.W   $12,A1-A7
    MOVEM.L   $12,D1-D7
    MOVEM.W   $12,A1/D7
    MOVEM.L   $12,A1/D7
    MOVEM.W   $1234,A1-A7
    MOVEM.L   $1234,D1-D7
    MOVEM.W   $1234,A1/D7
    MOVEM.L   $1234,A1/D7
    MOVEM.W   $12345678,A1-A7
    MOVEM.L   $12345678,D1-D7
    MOVEM.W   $12345678,A1/D7
    MOVEM.L   $12345678,A1/D7
    ADDA.W    $12,A2
    ADDA.W    $1234,A2
    ADDA.W    $12345678,A2
    ROL.B     #$1,D2    * Supposed to not be recognized
    ROL.W     #$2,D2    * Supposed to not be recognized
    ROL.L     #$3,D2    * Supposed to not be recognized
    ROL.W     $12       * Supposed to not be recognized
    ROL.W     $1234     * Supposed to not be recognized
    ROL.W     $12345678 * Supposed to not be recognized
    BRA       LABEL
    BRA       $1234
    BGT       LABEL
    BGT         $1234
    BEQ         LABEL   
    BEQ         $1234
        ORG $6000    
LABEL
    SIMHALT             ; halt simulator


    END    START        ; last line of source

























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
