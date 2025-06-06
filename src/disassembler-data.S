    ;; **********************************************************************
    ;; **  Disassembler data                         by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    #ifdef IncludeDisassemble

    ;; **********************************************************************
    ;; **  Constant data                                                   **
    ;; **********************************************************************

    .section .rodata

    ;; Disassembler string table: (DisString)
    ;; This contains many string which are not null terminated and have no
    ;; length value. Instead they are tightly packed with the start of each
    ;; string indicated by the first character having bit 7 set.
DisString:
    .db  0x80           ; String 0x01 =
    .db  0x80+'n'       ; String 0x02 = n
    .db  0x80+'(', "n)" ; String 0x03 = (n)
    .db  0x80+'n', "n"  ; String 0x04 = nn
    .db  0x80+'(', "nn)" ; String 0x05 = (nn)
    .db  0x80+'r'       ; String 0x06 = r
    .db  0x80+'r', "2"  ; String 0x07 = r2
    .db  0x80+'d', "d"  ; String 0x08 = dd
    .db  0x80+'q', "q"  ; String 0x09 = qq
    .db  0x80+'c'       ; String 0x0A = c
    .db  0x80+'c', "c"  ; String 0x0B = cc
    .db  0x80+'t'       ; String 0x0C = t
    .db  0x80+'b'       ; String 0x0D = b
    .db  0x80+'B', "CDEHL-A" ; String 0x0E = BCDEHL-A
    .db  0x80+'B', "CDE**SP" ; String 0x0F = BCDE**SP
    .db  0x80+'B', "CDE**AF" ; String 0x10 = BCDE**AF
    .db  0x80+'N', "ZZ.NCC." ; String 0x11 = NZZ.NCC.
    .db  0x80+'N', "ZZ.NCC.POPEP.M." ; String 0x12 = NZZ.NCC.POPEP.M.
    .db  0x80+'0', "008101820283038" ; String 0x13 = 0008101820283038
    .db  0x80+'0', "1234567" ; String 0x14 = 01234567
    .db  0x80+'(', "HL)" ; String 0x15 = (HL)
    .db  0x80+'(', "IX+" ; String 0x16 = (IX+
    .db  0x80+'(', "IY+" ; String 0x17 = (IY+
    .db  0x80+'H', "L"  ; String 0x18 = HL
    .db  0x80+'I', "X"  ; String 0x19 = IX
    .db  0x80+'I', "Y"  ; String 0x1A = IY
    .db  0x80+'J', "R"  ; String 0x1B = JR
    .db  0x80+'D', "JNZ" ; String 0x1C = DJNZ
    .db  0x80+'R', "ST" ; String 0x1D = RST
    .db  0x80+'J', "P"  ; String 0x1E = JP
    .db  0x80+'C', "ALL" ; String 0x1F = CALL
    .db  0x80+'R', "ET" ; String 0x20 = RET
    .db  0x80+'R', "ETI" ; String 0x21 = RETI
    .db  0x80+'R', "ETN" ; String 0x22 = RETN
    .db  0x80+'A'       ; String 0x23 = A
    .db  0x80+'(', "SP)" ; String 0x24 = (SP)
    .db  0x80+'A', "F"  ; String 0x25 = AF
    .db  0x80+'D', "E"  ; String 0x26 = DE
    .db  0x80+'0'       ; String 0x27 = 0
    .db  0x80+'1'       ; String 0x28 = 1
    .db  0x80+'2'       ; String 0x29 = 2
    .db  0x80+'(', "BC)" ; String 0x2A = (BC)
    .db  0x80+'(', "DE)" ; String 0x2B = (DE)
    .db  0x80+'S', "P"  ; String 0x2C = SP
    .db  0x80+'I'       ; String 0x2D = I
    .db  0x80+'R'       ; String 0x2E = R
    .db  0x80+'(', "C)" ; String 0x2F = (C)
    .db  0x80+'A', "F'" ; String 0x30 = AF'
    .db  0x80+'A', "DC" ; String 0x31 = ADC
    .db  0x80+'A', "DD" ; String 0x32 = ADD
    .db  0x80+'A', "ND" ; String 0x33 = AND
    .db  0x80+'B', "IT" ; String 0x34 = BIT
    .db  0x80+'C', "CF" ; String 0x35 = CCF
    .db  0x80+'C', "P"  ; String 0x36 = CP
    .db  0x80+'C', "PD" ; String 0x37 = CPD
    .db  0x80+'C', "PDR" ; String 0x38 = CPDR
    .db  0x80+'C', "PI" ; String 0x39 = CPI
    .db  0x80+'C', "PIR" ; String 0x3A = CPIR
    .db  0x80+'C', "PL" ; String 0x3B = CPL
    .db  0x80+'D', "AA" ; String 0x3C = DAA
    .db  0x80+'D', "EC" ; String 0x3D = DEC
    .db  0x80+'D', "I"  ; String 0x3E = DI
    .db  0x80+'E', "I"  ; String 0x3F = EI
    .db  0x80+'E', "X"  ; String 0x40 = EX
    .db  0x80+'E', "XX" ; String 0x41 = EXX
    .db  0x80+'H', "ALT" ; String 0x42 = HALT
    .db  0x80+'I', "M"  ; String 0x43 = IM
    .db  0x80+'I', "N"  ; String 0x44 = IN
    .db  0x80+'I', "NC" ; String 0x45 = INC
    .db  0x80+'I', "ND" ; String 0x46 = IND
    .db  0x80+'I', "NDR" ; String 0x47 = INDR
    .db  0x80+'I', "NI" ; String 0x48 = INI
    .db  0x80+'I', "NIR" ; String 0x49 = INIR
    .db  0x80+'L', "D"  ; String 0x4A = LD
    .db  0x80+'L', "DD" ; String 0x4B = LDD
    .db  0x80+'L', "DDR" ; String 0x4C = LDDR
    .db  0x80+'L', "DI" ; String 0x4D = LDI
    .db  0x80+'L', "DIR" ; String 0x4E = LDIR
    .db  0x80+'N', "EG" ; String 0x4F = NEG
    .db  0x80+'N', "OP" ; String 0x50 = NOP
    .db  0x80+'O', "R"  ; String 0x51 = OR
    .db  0x80+'O', "TDR" ; String 0x52 = OTDR
    .db  0x80+'O', "TIR" ; String 0x53 = OTIR
    .db  0x80+'O', "UT" ; String 0x54 = OUT
    .db  0x80+'O', "UTD" ; String 0x55 = OUTD
    .db  0x80+'O', "UTI" ; String 0x56 = OUTI
    .db  0x80+'P', "OP" ; String 0x57 = POP
    .db  0x80+'P', "USH" ; String 0x58 = PUSH
    .db  0x80+'R', "ES" ; String 0x59 = RES
    .db  0x80+'R', "L"  ; String 0x5A = RL
    .db  0x80+'R', "LA" ; String 0x5B = RLA
    .db  0x80+'R', "LC" ; String 0x5C = RLC
    .db  0x80+'R', "LCA" ; String 0x5D = RLCA
    .db  0x80+'R', "LD" ; String 0x5E = RLD
    .db  0x80+'R', "R"  ; String 0x5F = RR
    .db  0x80+'R', "RA" ; String 0x60 = RRA
    .db  0x80+'R', "RC" ; String 0x61 = RRC
    .db  0x80+'R', "RCA" ; String 0x62 = RRCA
    .db  0x80+'R', "RD" ; String 0x63 = RRD
    .db  0x80+'S', "BC" ; String 0x64 = SBC
    .db  0x80+'S', "CF" ; String 0x65 = SCF
    .db  0x80+'S', "ET" ; String 0x66 = SET
    .db  0x80+'S', "LA" ; String 0x67 = SLA
    .db  0x80+'S', "LL" ; String 0x68 = SLL
    .db  0x80+'S', "RA" ; String 0x69 = SRA
    .db  0x80+'S', "RL" ; String 0x6A = SRL
    .db  0x80+'S', "UB" ; String 0x6B = SUB
    .db  0x80+'X', "OR" ; String 0x6C = XOR
    .db  0x80+'?', "???" ; String 0x6D = ????
    .db  0x80

    ;; Instruction table: (DisInst)
    ;; The instruction table definition of the processor's instruction set.
    ;; Each instruction is described by 5 bytes:
    ;;    Byte 0:  Opcode value
    ;;    Byte 1:  Opcode mask
    ;;    Byte 2:  Operation string number
    ;;    Byte 3:  Operand #1 string number, plus bits 6-7 define precode
    ;;    Byte 4:  Operand #2 string number
    ;; The precode values code in bits 6-7 are:
    ;;    00xx xxxx = No precode
    ;;    10xx xxxx = Precode 0xCB
    ;;    11xx xxxx = Precode 0xED
    ;; Precodes are used by the processor's extended instructions
DisInst:
    .db  0x88, 0xf8, 0x31, 0x23, 0x07 ; Opcode: 0x88 - ADC  A   ,r2
    .db  0xce, 0xff, 0x31, 0x23, 0x02 ; Opcode: 0xCE - ADC  A   ,n
    .db  0x4a, 0xcf, 0x31, 0xd8, 0x08 ; Opcode: 0x4A - ADC  HL  ,dd
    .db  0x80, 0xf8, 0x32, 0x23, 0x07 ; Opcode: 0x80 - ADD  A   ,r2
    .db  0xc6, 0xff, 0x32, 0x23, 0x02 ; Opcode: 0xC6 - ADD  A   ,n
    .db  0x09, 0xcf, 0x32, 0x18, 0x08 ; Opcode: 0x09 - ADD  HL  ,dd
    .db  0xa0, 0xf8, 0x33, 0x07, 0x01 ; Opcode: 0xA0 - AND  r2  ,
    .db  0xe6, 0xff, 0x33, 0x02, 0x01 ; Opcode: 0xE6 - AND  n   ,
    .db  0x40, 0xc0, 0x34, 0x8d, 0x07 ; Opcode: 0x40 - BIT  b   ,r2
    .db  0xc4, 0xc7, 0x1f, 0x0b, 0x04 ; Opcode: 0xC4 - CALL cc  ,nn
    .db  0xcd, 0xff, 0x1f, 0x04, 0x01 ; Opcode: 0xCD - CALL nn  ,
    .db  0x3f, 0xff, 0x35, 0x01, 0x01 ; Opcode: 0x3F - CCF      ,
    .db  0xb8, 0xf8, 0x36, 0x07, 0x01 ; Opcode: 0xB8 - CP   r2  ,
    .db  0xfe, 0xff, 0x36, 0x02, 0x01 ; Opcode: 0xFE - CP   n   ,
    .db  0xa9, 0xff, 0x37, 0xc1, 0x01 ; Opcode: 0xA9 - CPD      ,
    .db  0xb9, 0xff, 0x38, 0xc1, 0x01 ; Opcode: 0xB9 - CPDR     ,
    .db  0xa1, 0xff, 0x39, 0xc1, 0x01 ; Opcode: 0xA1 - CPI      ,
    .db  0xb1, 0xff, 0x3a, 0xc1, 0x01 ; Opcode: 0xB1 - CPIR     ,
    .db  0x2f, 0xff, 0x3b, 0x01, 0x01 ; Opcode: 0x2F - CPL      ,
    .db  0x27, 0xff, 0x3c, 0x01, 0x01 ; Opcode: 0x27 - DAA      ,
    .db  0x0b, 0xcf, 0x3d, 0x08, 0x01 ; Opcode: 0x0B - DEC  dd  ,
    .db  0x05, 0xc7, 0x3d, 0x06, 0x01 ; Opcode: 0x05 - DEC  r   ,
    .db  0xf3, 0xff, 0x3e, 0x01, 0x01 ; Opcode: 0xF3 - DI       ,
    .db  0x10, 0xff, 0x1c, 0x02, 0x01 ; Opcode: 0x10 - DJNZ n   ,
    .db  0xfb, 0xff, 0x3f, 0x01, 0x01 ; Opcode: 0xFB - EI       ,
    .db  0xe3, 0xff, 0x40, 0x24, 0x18 ; Opcode: 0xE3 - EX   (SP),HL
    .db  0x08, 0xff, 0x40, 0x25, 0x30 ; Opcode: 0x08 - EX   AF  ,AF'
    .db  0xeb, 0xff, 0x40, 0x26, 0x18 ; Opcode: 0xEB - EX   DE  ,HL
    .db  0xd9, 0xff, 0x41, 0x01, 0x01 ; Opcode: 0xD9 - EXX      ,
    .db  0x76, 0xff, 0x42, 0x01, 0x01 ; Opcode: 0x76 - HALT     ,
    .db  0x46, 0xff, 0x43, 0xe7, 0x01 ; Opcode: 0x46 - IM   0   ,
    .db  0x56, 0xff, 0x43, 0xe8, 0x01 ; Opcode: 0x56 - IM   1   ,
    .db  0x5e, 0xff, 0x43, 0xe9, 0x01 ; Opcode: 0x5E - IM   2   ,
    .db  0x40, 0xc7, 0x44, 0xc6, 0x2f ; Opcode: 0x40 - IN   r   ,(C)
    .db  0xdb, 0xff, 0x44, 0x23, 0x03 ; Opcode: 0xDB - IN   A   ,(n)
    .db  0x03, 0xcf, 0x45, 0x08, 0x01 ; Opcode: 0x03 - INC  dd  ,
    .db  0x04, 0xc7, 0x45, 0x06, 0x01 ; Opcode: 0x04 - INC  r   ,
    .db  0xaa, 0xff, 0x46, 0xc1, 0x01 ; Opcode: 0xAA - IND      ,
    .db  0xba, 0xff, 0x47, 0xc1, 0x01 ; Opcode: 0xBA - INDR     ,
    .db  0xa2, 0xff, 0x48, 0xc1, 0x01 ; Opcode: 0xA2 - INI      ,
    .db  0xb2, 0xff, 0x49, 0xc1, 0x01 ; Opcode: 0xB2 - INIR     ,
    .db  0xe9, 0xff, 0x1e, 0x15, 0x01 ; Opcode: 0xE9 - JP   (HL),
    .db  0xc2, 0xc7, 0x1e, 0x0b, 0x04 ; Opcode: 0xC2 - JP   cc  ,nn
    .db  0xc3, 0xff, 0x1e, 0x04, 0x01 ; Opcode: 0xC3 - JP   nn  ,
    .db  0x20, 0xe7, 0x1b, 0x0a, 0x02 ; Opcode: 0x20 - JR   c   ,n
    .db  0x18, 0xff, 0x1b, 0x02, 0x01 ; Opcode: 0x18 - JR   n   ,
    .db  0x40, 0xc0, 0x4a, 0x06, 0x07 ; Opcode: 0x40 - LD   r   ,r2
    .db  0x02, 0xff, 0x4a, 0x2a, 0x23 ; Opcode: 0x02 - LD   (BC),A
    .db  0x12, 0xff, 0x4a, 0x2b, 0x23 ; Opcode: 0x12 - LD   (DE),A
    .db  0x32, 0xff, 0x4a, 0x05, 0x23 ; Opcode: 0x32 - LD   (nn),A
    .db  0x22, 0xff, 0x4a, 0x05, 0x18 ; Opcode: 0x22 - LD   (nn),HL
    .db  0x43, 0xcf, 0x4a, 0xc5, 0x08 ; Opcode: 0x43 - LD   (nn),dd
    .db  0x0a, 0xff, 0x4a, 0x23, 0x2a ; Opcode: 0x0A - LD   A   ,(BC)
    .db  0x1a, 0xff, 0x4a, 0x23, 0x2b ; Opcode: 0x1A - LD   A   ,(DE)
    .db  0x3a, 0xff, 0x4a, 0x23, 0x05 ; Opcode: 0x3A - LD   A   ,(nn)
    .db  0x2a, 0xff, 0x4a, 0x18, 0x05 ; Opcode: 0x2A - LD   HL  ,(nn)
    .db  0xf9, 0xff, 0x4a, 0x2c, 0x18 ; Opcode: 0xF9 - LD   SP  ,HL
    .db  0x01, 0xcf, 0x4a, 0x08, 0x04 ; Opcode: 0x01 - LD   dd  ,nn
    .db  0x4b, 0xcf, 0x4a, 0xc8, 0x05 ; Opcode: 0x4B - LD   dd  ,(nn)
    .db  0x57, 0xff, 0x4a, 0xe3, 0x2d ; Opcode: 0x57 - LD   A   ,I
    .db  0x5f, 0xff, 0x4a, 0xe3, 0x2e ; Opcode: 0x5F - LD   A   ,R
    .db  0x47, 0xff, 0x4a, 0xed, 0x23 ; Opcode: 0x47 - LD   I   ,A
    .db  0x4f, 0xff, 0x4a, 0xee, 0x23 ; Opcode: 0x4F - LD   R   ,A
    .db  0x06, 0xc7, 0x4a, 0x06, 0x02 ; Opcode: 0x06 - LD   r   ,n
    .db  0xa8, 0xff, 0x4b, 0xc1, 0x01 ; Opcode: 0xA8 - LDD      ,
    .db  0xb8, 0xff, 0x4c, 0xc1, 0x01 ; Opcode: 0xB8 - LDDR     ,
    .db  0xa0, 0xff, 0x4d, 0xc1, 0x01 ; Opcode: 0xA0 - LDI      ,
    .db  0xb0, 0xff, 0x4e, 0xc1, 0x01 ; Opcode: 0xB0 - LDIR     ,
    .db  0x44, 0xff, 0x4f, 0xc1, 0x01 ; Opcode: 0x44 - NEG      ,
    .db  0x00, 0xff, 0x50, 0x01, 0x01 ; Opcode: 0x00 - NOP      ,
    .db  0xb0, 0xf8, 0x51, 0x07, 0x01 ; Opcode: 0xB0 - OR   r2  ,
    .db  0xf6, 0xff, 0x51, 0x02, 0x01 ; Opcode: 0xF6 - OR   n   ,
    .db  0xbb, 0xff, 0x52, 0xc1, 0x01 ; Opcode: 0xBB - OTDR     ,
    .db  0xb3, 0xff, 0x53, 0xc1, 0x01 ; Opcode: 0xB3 - OTIR     ,
    .db  0x41, 0xc7, 0x54, 0xef, 0x06 ; Opcode: 0x41 - OUT  (C) ,r
    .db  0xd3, 0xff, 0x54, 0x03, 0x23 ; Opcode: 0xD3 - OUT  (n) ,A
    .db  0xab, 0xff, 0x55, 0xc1, 0x01 ; Opcode: 0xAB - OUTD     ,
    .db  0xa3, 0xff, 0x56, 0xc1, 0x01 ; Opcode: 0xA3 - OUTI     ,
    .db  0xc1, 0xcf, 0x57, 0x09, 0x01 ; Opcode: 0xC1 - POP  qq  ,
    .db  0xc5, 0xcf, 0x58, 0x09, 0x01 ; Opcode: 0xC5 - PUSH qq  ,
    .db  0x80, 0xc0, 0x59, 0x8d, 0x07 ; Opcode: 0x80 - RES  b   ,r2
    .db  0xc9, 0xff, 0x20, 0x01, 0x01 ; Opcode: 0xC9 - RET      ,
    .db  0xc0, 0xc7, 0x20, 0x0b, 0x01 ; Opcode: 0xC0 - RET  cc  ,
    .db  0x4d, 0xff, 0x21, 0xc1, 0x01 ; Opcode: 0x4D - RETI     ,
    .db  0x45, 0xff, 0x22, 0xc1, 0x01 ; Opcode: 0x45 - RETN     ,
    .db  0x10, 0xf8, 0x5a, 0x87, 0x01 ; Opcode: 0x10 - RL   r2  ,
    .db  0x17, 0xff, 0x5b, 0x01, 0x01 ; Opcode: 0x17 - RLA      ,
    .db  0x00, 0xf8, 0x5c, 0x87, 0x01 ; Opcode: 0x00 - RLC  r2  ,
    .db  0x07, 0xff, 0x5d, 0x01, 0x01 ; Opcode: 0x07 - RLCA     ,
    .db  0x6f, 0xff, 0x5e, 0xc1, 0x01 ; Opcode: 0x6F - RLD      ,
    .db  0x18, 0xf8, 0x5f, 0x87, 0x01 ; Opcode: 0x18 - RR   r2  ,
    .db  0x1f, 0xff, 0x60, 0x01, 0x01 ; Opcode: 0x1F - RRA      ,
    .db  0x08, 0xf8, 0x61, 0x87, 0x01 ; Opcode: 0x08 - RRC  r2  ,
    .db  0x0f, 0xff, 0x62, 0x01, 0x01 ; Opcode: 0x0F - RRCA     ,
    .db  0x67, 0xff, 0x63, 0xc1, 0x01 ; Opcode: 0x67 - RRD      ,
    .db  0xc7, 0xc7, 0x1d, 0x0c, 0x01 ; Opcode: 0xC7 - RST  t   ,
    .db  0x98, 0xf8, 0x64, 0x23, 0x07 ; Opcode: 0x98 - SBC  A   ,r2
    .db  0xde, 0xff, 0x64, 0x23, 0x02 ; Opcode: 0xDE - SBC  A   ,n
    .db  0x42, 0xcf, 0x64, 0xd8, 0x08 ; Opcode: 0x42 - SBC  HL  ,dd
    .db  0x37, 0xff, 0x65, 0x01, 0x01 ; Opcode: 0x37 - SCF      ,
    .db  0xc0, 0xc0, 0x66, 0x8d, 0x07 ; Opcode: 0xC0 - SET  b   ,r2
    .db  0x20, 0xf8, 0x67, 0x87, 0x01 ; Opcode: 0x20 - SLA  r2  ,
    .db  0x30, 0xf8, 0x68, 0x87, 0x01 ; Opcode: 0x30 - SLL  r2  ,
    .db  0x28, 0xf8, 0x69, 0x87, 0x01 ; Opcode: 0x28 - SRA  r2  ,
    .db  0x38, 0xf8, 0x6a, 0x87, 0x01 ; Opcode: 0x38 - SRL  r2  ,
    .db  0x90, 0xf8, 0x6b, 0x07, 0x01 ; Opcode: 0x90 - SUB  r2  ,
    .db  0xd6, 0xff, 0x6b, 0x02, 0x01 ; Opcode: 0xD6 - SUB  n   ,
    .db  0xa8, 0xf8, 0x6c, 0x07, 0x01 ; Opcode: 0xA8 - XOR  r2  ,
    .db  0xee, 0xff, 0x6c, 0x02, 0x01 ; Opcode: 0xEE - XOR  n   ,
    .db  0x00, 0x00, 0x6d, 0x01, 0x01 ; Opcode: 0x00 - ????     ,
    .db  0x00, 0x00, 0x6d, 0xc1, 0x01 ; Opcode: 0x00 - ????     ,

    ;; **********************************************************************
    ;; **  End of Disassembler data module                                 **
    ;; **********************************************************************

    #endif // IncludeDisassemble
