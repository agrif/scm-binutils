    ;; **********************************************************************
    ;; **  Disassembler support                      by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides instruction disassembly support. There are two
    ;; main public functions which disassemble an instruction and provide the
    ;; result as a string in the current string buffer. These are:
    ;;
    ;; Function: DisWrInstruction
    ;; This returns a string in the format: Address: Opcodes  Mnemonic
    ;; eg.   0300: CD FB 01       CALL 0x1FB
    ;; It also returns the length of the instruction in bytes and the
    ;; address of the next instruction.
    ;;
    ;; Function: DisWrMnemonic
    ;; This returns a string in the format: Mnemonic only
    ;; eg.   CALL 0x1FB
    ;; It also returns the length of the instruction in bytes.
    ;;
    ;; This module also provides the public helper function:
    ;;
    ;; Function: DisGetNextAddress
    ;; Returns address of next instruction to be executed. This is used by
    ;; the single stepping feature. It takes into account flags to determine
    ;; outcome of conditional instructions.
    ;;
    ;; Further documentation and notes are at the end of this file.
    ;;
    ;; Public functions provided
    ;;   DisWrInstruction      Returns string if full details
    ;;   DisWrMnemonic         Returns string of mnemonic only
    ;;   DisGetNextAddress     Returns address of next instruction
    ;; Private support function (not intended to be called from outside)
    ;;   DisWrOperand          Process suppied operand
    ;;   DisGetOpcode          Get instruction opcode
    ;;   DisWrChar             Write a character to the buffer with filters
    ;;   DisWrString           Write a string to the buffer with filters

    #ifdef IncludeDisassemble

    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Disassembler: Write full disassembly to string buffer
    ;;   On entry: HL = Start of instruction to be disassembled
    ;;   On exit:  Address, opcodes and mnemonic in current string buffer
    ;;             iDisIndex variable used
    ;;             A = Length of instruction in bytes
    ;;             HL = Start address of next instruction
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
DisWrInstruction:
    push bc
    push de
    ld   a, 20          ; Select string for mnemonic...
    ld   de, kStrBuffer+80 ; Length 20 at end of default string
    call StrInitialise  ; Initialise string for mnemonic
    call DisWrMnemonic  ; Disassemble to mnemonic string
    ld   c, a           ; Store length of instruction in bytes
    ;;xor  a            ; Clear A to zero
    call StrInitDefault ; Select default string for opcodes
    ld   d, h           ; Get start of instruction..
    ld   e, l
    call StrWrAddress   ; Write address, colon and space
    ld   b, c           ; Get length of instruction
.DisWrInstructionOpcode:
    ld   a, (hl)        ; Get instruction opcode
    call StrWrHexByte   ; Write as hex byte
    call StrWrSpace     ; Write space
    inc  hl             ; Point to next byte
    djnz .DisWrInstructionOpcode ; Loop until all hex bytes written
    ld   a, 19          ; Column number
    call StrWrPadding   ; Pad with spaces to specified column
    ld   b, c           ; Get length of instruction
.DisWrInstructionAscii:
    ld   a, (de)        ; Get instruction opcode
    call StrWrAsciiChar ; Write as ASCII character
    inc  de             ; Point to next byte
    djnz .DisWrInstructionAscii ; Loop until all characters written
    ld   a, 25          ; Column number
    call StrWrPadding   ; Pad with spaces to specified column
.DisWrInstructionMnemonic:
    ld   de, kStrBuffer+80
    call StrAppend      ; Append disassembly string
    ;;call StrWrNewLine ; Write new line to string buffer
    ld   a, c           ; Get length of instruction in bytes
    pop  de
    pop  bc
    ret


    ;; Disassembler: Write mnemonic only to string buffer
    ;;   On entry: HL = Start of instruction to be disassembled
    ;;   On exit:  Mnemonic is written to current string buffer
    ;;             iDisIndex variable used
    ;;             A = Length of instruction in bytes
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
DisWrMnemonic:
    push bc
    push de
    push hl
    push ix
    push iy
    ;; Prepare to disassemble
    ;; HL = Address of current instruction
    push hl             ; Copy start address of instruction
    pop  iy             ;  to IY
    ld   ix, DisInst    ; Start of instruction table
    xor  a
    ld   (iDisIndex), a ; Clear index instruction opcode
    ld   e, a           ; Clear prefix for extended instructions
    ld   d, (hl)        ; Instruction's primary opcode
    ld   b, a           ; Offset to instruction's primary opcode
    ;; Check for index register instruction (IX or IY)
    ld   a, d           ; Could have been written LD A,(IY+0)
    cp   0xdd           ; IX instruction?
    jr   z, .DisWrMnemonicIndex ; Yes, so skip
    cp   0xfd           ; IY instruction?
    jr   nz, .DisWrMnemonicNotIndex ; No, so skip
.DisWrMnemonicIndex:
    ld   (iDisIndex), a ; Store index instruction opcode
    inc  b              ; Increment offset to primary opcode
    ld   a, (IY+1)      ; Get next opcode byte
.DisWrMnemonicNotIndex:
    ;; Check for extended instruction
    cp   0xcb           ; Extended instruction?
    jr   z, .DisWrMnemonicExtend ; Yes, so skip
    cp   0xed           ; Extended instruction?
    jr   nz, .DisWrMnemonicNotExtend ; No, so skip
.DisWrMnemonicExtend:
    ld   e, a           ; Store prefix for extended instructions
    inc  b              ; Increment offset to primary opcode
    ld   a, (iDisIndex) ; Get index instruction opcode
    or   a              ; Is this an index instruction?
    ld   a, b           ; Prepare to read primary opcode
    jr   z, .DisWrMnemonicExNoIndx ; No, so skip
    inc  a              ; Yes, skip index displacement byte
.DisWrMnemonicExNoIndx:
    call DisGetOpcode   ; Get primary opcode
.DisWrMnemonicNotExtend:
    ld   d, a           ; Remember instruction's primary opcode
    ld   (iDisOpcode), a ; Store primary opcode
    ;; Locate instruction table entry for current instruction
    ;; (pointer to by HL)
    ;; BASIC: (i And iMask(n)) = (iValue(n) And iMask(n)) ?
.DisWrMnemonicTable:
    ld   a, (IX+0)      ; Get opcode value from table
    and  (IX+1)         ; AND with opcode mask from table
    ld   c, a           ; Store Value AND Mask
    ld   a, (IX+1)      ; Get opcode mask from table
    and  d              ; AND with instruction being disassembled
    cp   c              ; Is this the correct table entry?
    jr   nz, .DisWrMnemonicNotFound ; No, so this is not the correct table
    ;; BASIC: ... AND (p = iPrecode(n)) ?
    xor  a              ; Default precode for comparison = 0x00
    bit  7, (IX+3)      ; Precode (index or extended)?
    jr   z, .DisWrMnemonicGotPrCode ; No, so skip
    ld   a, 0xcb        ; Default precode for comparison = 0xCB
    bit  6, (IX+3)      ; Precode = 0xED?
    jr   z, .DisWrMnemonicGotPrCode ; No, so skip
    ld   a, 0xed        ; Yes, so precode for comparison = 0xED
.DisWrMnemonicGotPrCode:
    cp   e              ; Compare table precode with instruction
    jr   z, .DisWrMnemonicFound ; Yes, so this is the correct table
.DisWrMnemonicNotFound:
    push bc             ; Preserve BC
    ld   bc, 5          ; No, so try next table entry
    add  ix, bc         ; Point to next table entry
    pop  bc             ; Restore BC
    jr   .DisWrMnemonicTable
    ;; We now have the correct instruction table entry (pointer to by IX)
    ;; BASIC: (p = iPrecode(n)) And (i And iMask(n)) = (iValue(n) And iMask(n))
.DisWrMnemonicFound:
    ld   a, (IX+2)      ; Get operation string number
    ld   (iDisOpStr), a ; Store operation string number
    call DisWrString    ; Write operation string
    call StrWrSpace
    ;; BASIC: Operand sString(iOperand1(n)), t
    ld   a, (IX+3)      ; Get operand #1 string number
    ld   (iDisOp1Str), a ; Store opcode #1 string number
    ld   c, d           ; Get primary opcode value
    call DisWrOperand
    ;; BASIC: Operand sString(iOperand2(n)), t
    ld   a, (IX+4)      ; Get operand #2 string number
    dec  a              ; Is is 1? (null string)
    jr   z, .DisWrMnemonicNoOp2 ; Yes, so skip this operand
    ld   a, ','         ; Get comma character
    call StrWrChar      ; Write comma to string
    ld   a, (IX+4)      ; Get operand #2 string number
    ld   c, d           ; Get primary opcode value
    call DisWrOperand
.DisWrMnemonicNoOp2:
    ;; If relative jump show absolute address in brackets
    ld   a, (iDisOpStr) ; Get operation string number
    cp   kDisJR         ; JR instruction?
    jr   z, .DisWrMnemonicRel ; Yes, so skip
    cp   kDisDJNZ       ; DJNZ instruction?
    jr   nz, .DisWrMnemonicNotRel ; No so skip
.DisWrMnemonicRel:
    ld   de, szDisTo    ; String = "  (to "
    call StrAppendZ     ; Append zero terminated string
    push iy             ; Push address of instruction
    pop  hl             ; POP address of instruction
    inc  hl             ; Increment to
    inc  hl             ;  end of the JR/DJNZ instruction
    ld   a, (iDisImmed) ; Get immediate value from instruction
    ld   e, a           ; Get displacement lo (signed byte)
    ld   d, 0           ; Default to hi byte = zero
    bit  7, a           ; Displacement negative?
    jr   z, .DisWrMnemonicJRadd ; No, so skip
    dec  d              ; Yes, so set hi byte to 0xFF
.DisWrMnemonicJRadd:
    add  hl, de         ; Add signed 16-bit displacement
    ld   d, h           ; Get destination address hi byte
    ld   e, l           ; Get destination address lo byte
    call WrHexPrefix    ; Write hex prefix to string
    call StrWrHexWord   ; Write hex word to string
    ld   a, ')'         ; Get close bracket character
    call StrWrChar      ; Write close bracket to string
.DisWrMnemonicNotRel:
    ;; Finish building mnemonic string
    ld   a, b           ; Get offset into instruction
    inc  a              ; Increment to give instruction length
    pop  iy
    pop  ix
    pop  hl
    pop  de
    pop  bc
    ret


    ;; Disassembler: Get address of next instruction
    ;;   On entry: HL = Next address ignoring flow control instructions
    ;;             Next instruction
    ;;   On exit:  HL = Next address after consider flow instructions
    ;;             AF BC DE IX IY I AF' BC' DE' HL' preserved
    ;; Just prior to this function the next instruction must have been
    ;; disassembled so instruction details are available in iDisXXXX
    ;; workspace. Also breakpoint register values must be in workspace.
DisGetNextAddress:
    push af
    push bc
    push de
    ;; Determine if last instruction may have changed program flow
    ld   a, (iDisOpStr) ; Get operation string number
    cp   kDisFlowF      ; Compare with first flow control instr
    jr   c, .DisGetNextAddressDone2 ; Not a flow instruction so we're done
    cp   kDisFlowL+1    ; Compare with first flow control instr
    jr   nc, .DisGetNextAddressDone2 ; Not a flow instruction so we're done
    ;; The current instruction is a flow controlling instruction eg. CALL
    ;; Consider if the instruction is conditional or not by looking at
    ;; operand 1 string number to see if it is the operand substitution
    ;; string "c" or "cc" (for conditions NZ,Z,NC,C,PO,PE,P,M)
    ld   a, (iDisOp1Str) ; Get operand 1 string number
    ld   b, kDisMskC    ; Prepare condition 'c' mask
    cp   kDisSubC       ; Is operand 'c'? eg. 'Z' in 'JR Z,addr'
    jr   z, .DisGetNextAddressCondition ; Yes, so go handle condition
    ld   b, kDisMskCC   ; Prepare condition 'cc' mask
    cp   kDisSubCC      ; Is operand 'cc'? eg. 'PE' in 'JP PE,addr'
    jr   nz, .DisGetNextAddressNoCond ; No, so skip condition evaluation
    ;; Evaluate condition. B is the conditions bit mask
.DisGetNextAddressCondition:
    ld   a, (iDisOpcode) ; Get instruction's primary opcode
    and  b              ; Mask to give condition bits, Cy=0
    rra                 ; Shift condition bits to bits 0 to 1
    rra                 ;  to give offset in table
    rra                 ;  for each coded condition
    rra                 ;  plus flag state in Carry
    ld   b, a           ; Set up table loop counter
    ;; Condition table contains one byte for each flag condition:
    ;; 0=NZ/Z, 1=NC/C,2=PO/PE, 3=P/M and C set for Z, C, PE and M
    ;; The values in the table are bit masks for the flags register
    ;; which is ORed with Flags register to test if flag is set, and
    ;; then exclusively ORed with flags register to test if not set.
    push hl
    ld   hl, DisConTab-1 ; Point to start of condition table -1
    inc  b              ; Increment loop counter
.DisGetNextAddressIncPtr:
    inc  hl             ; Inc pointer into condition table
    djnz .DisGetNextAddressIncPtr ; Go inc again until we are there
    ld   a, (iAF)       ; Get flags register value
    jr   c, .DisGetNextAddressConTest ; Looking for flag low?
    xor  (hl)           ; Yes, so invert required flag bit
.DisGetNextAddressConTest:
    and  (hl)           ; Mask required flag bit (clears Cy)
    pop  hl
    jr   z, .DisGetNextAddressDone ; We're done if condition not met
    ;; Determine address after executing the flow controlling instruction
    ;; when the condition is met (if there is a condition)
.DisGetNextAddressNoCond:
    ld   a, (iDisOpStr) ; Get operation string number
    cp   kDisCALL       ; Instruction = "CALL"
    jr   z, .DisGetNextAddressCALL
    cp   kDisDJNZ       ; Instruction = "DJNZ"
    jr   z, .DisGetNextAddressDJNZ
    cp   kDisJP         ; Instruction = "JP"
    jr   z, .DisGetNextAddressJP
    cp   kDisJR         ; Instruction = "JR"
    jr   z, .DisGetNextAddressJR
    cp   kDisRST        ; Instruction = "RST"
    jr   z, .DisGetNextAddressRST
    ;; Instruction: RET or RET cc or RETI or RETN
.DisGetNextAddressRET:
    ld   hl, (iSP)      ; Get stack pointer at breakpoint
    jr   .DisGetNextAddressJP2 ; Go to addess pointed to by HL
    ;; Instruction: DJNZ n
.DisGetNextAddressDJNZ:
    ld   a, (iBC+1)     ; Get register B value
    dec  a              ; Will B reach zero?
    jr   z, .DisGetNextAddressDone ; Yes, so we're done
    ;;jr   .DisGetNextAddressJR ; No, so go treat as JR instruction
    ;; Instruction: JR n or JR c,n
.DisGetNextAddressJR:
    ld   a, (iDisImmed) ; Get immediate value from instruction
    ld   e, a           ; Get displacement lo (signed byte)
    ld   d, 0           ; Default to hi byte = zero
    bit  7, a           ; Displacement negative?
    jr   z, .DisGetNextAddressJRadd ; No, so skip
    dec  d              ; Yes, so set hi byte to 0xFF
.DisGetNextAddressJRadd:
    add  hl, de         ; Add signed 16-bit displacement
.DisGetNextAddressDone2:
    jr   .DisGetNextAddressDone
    ;; Instruction: JP nn or JP cc,nn or JP HL or JP IX or JP IY
.DisGetNextAddressJP:
    ld   a, (iDisOp1Str) ; Get operand 1 string number
    cp   kDisSubCC      ; Is operand 'cc'? eg. 'PE' in 'JP PE,addr'
    jr   z, .DisGetNextAddressGOTOnn ; Yes, so goto address nn
    cp   kDisSubNN      ; Instruction = JP nn ?
    jr   z, .DisGetNextAddressGOTOnn ; Yes, so goto address nn
    ;; Instruction: JP HL or JP IX or JP IY
    ld   hl, iHL        ; Point to register storage for HL
    ld   a, (iDisIndex) ; Index register instruction?
    or   a              ; No, so go JP
    jr   z, .DisGetNextAddressJP2
    inc  hl             ; Point to register storage for IX
    inc  hl
    cp   0xdd           ; Instruction = JP IX
    jr   z, .DisGetNextAddressJP2
    inc  hl             ; Point to register storage for IX
    inc  hl
    ;; Go to the address pointed to by HL
.DisGetNextAddressJP2:
    ld   a, (hl)        ; Get lo byte of new address
    inc  hl             ; Point to hi byte
    ld   h, (hl)        ; Get hi byte of new address
    ld   l, a           ; Get lo byte of newreturn address
    jr   .DisGetNextAddressDone
    ;; Instruction: RST n
.DisGetNextAddressRST:
    ld   a, (iDisOpcode) ; Get primary opcode
    and  kDisMskRST     ; Mask off unwanted bits
    ld   l, a           ; Store as lo byte of new address
    ld   h, 0           ; Clear hi byte of new address
    jr   .DisGetNextAddressDone
    ;; Instruction: CALL nn or CALL cc,nn
    ;; JR  .DisGetNextAddressJP            ; Treat as JP instruction
.DisGetNextAddressCALL:
    ;; Instruction: CALL nn or CALL cc,nn or JP nn pr JP cc,nn
.DisGetNextAddressGOTOnn:
    ld   hl, (iDisImmed) ; Get immediate value from instruction
    ;;jr   .DisGetNextAddressDone
.DisGetNextAddressDone:
    pop  de
    pop  bc
    pop  af
    ret


    ;; **********************************************************************
    ;; **  Private functions                                               **
    ;; **********************************************************************


    ;; Disassembler: Write operand to buffer
    ;;   On entry: A = Operand string number
    ;;             B = Offset to opcode from start of instruction
    ;;             C = Primary op-code
    ;;             IY = Start address of instruction
    ;;   On exit:  A = Unspecified
    ;;             B = Updated offset to opcode from start of instruction
    ;;             C = Not specified
    ;;             DE HL IX IY I AF' BC' DE' HL' preserved
DisWrOperand:
    and  kDisOpMask     ; Mask off flag bits
    cp   kDisSubsL+1    ; Substitution operand string?
    jp   nc, DisWrString ; No, so just write string
.DisWrOperandDisSubStr:
    push de
    push hl
    ;; Calculate operand table location for this operand and get details
    ld   hl, DisOperandTable-2
    add  a, a           ; Two bytes per entry
    add  a, l           ; Add to start of table
    ld   l, a           ; Store updated lo byte
    jr   nc, .DisWrOperandNoOverFlo ; Skip if no overflow
    inc  h              ; Overflow so increment hi byte
.DisWrOperandNoOverFlo:
    ld   e, (hl)        ; Get substitution string number
    inc  hl             ; Point to BIILMM bits
    ld   d, (hl)        ; Get BIILMM function bits
    push de             ; So we can use E for scratch reg
    ;; Process this operand as detailed in DE, left bracket?
    bit  kDisBrack, d   ; Bracket flagged?
    jr   z, .DisWrOperandNoBracL ; No, so skip
    ld   a, '('         ; Get left bracket character
    call StrWrChar      ; Print left bracket
.DisWrOperandNoBracL:
    ;; Process this operand as detailed in DE, immediate value?
    bit  kDisImmed, d   ; Immediate value flagged?
    jr   z, .DisWrOperandNoImmedia ; No, so skip
    call WrHexPrefix    ; Print "0x" (or whatever we use)
    inc  b              ; Increment offset to lo byte
    ld   a, b           ; Offset to instruction byte
    call DisGetOpcode   ; Get lo byte of immediate value
    ld   (iDisImmed), a ; Store lo byte of immediate value
    ld   e, a           ; Store lo byte of immediate value
    bit  kDisWord, d    ; Immediate value is a word?
    jr   z, .DisWrOperandImmedLo ; No, so skip
    inc  b              ; Increment offset to hi byte
    ld   a, b           ; Offset to instruction byte
    call DisGetOpcode   ; Get hi byte of immediate value
    ld   (iDisImmed+1), a ; Store hi byte of immediate value
    call StrWrHexByte   ; Print hi byte of immediate value
.DisWrOperandImmedLo:
    ld   a, e           ; Restore lo byte of immediate value
    call StrWrHexByte   ; Print lo byte of immediate value
.DisWrOperandNoImmedia:
    ;; Process this operand as detailed in DE, right bracket?
    bit  kDisBrack, d   ; Bracket flagged?
    jr   z, .DisWrOperandNoBracR ; No, so skip
    ld   a, ')'         ; Get right bracket character
    call StrWrChar      ; Print right bracket
.DisWrOperandNoBracR:
    ;; Process this operand as detailed in DE, substitution string?
    pop  de             ; Restore details
    ld   a, e           ; Get substitution string number
    or   a              ; String specified?
    jr   z, .DisWrOperandSubEnd ; No, so skip
    ld   a, d           ; Get BIILMM function bits
    and  kDisMask       ; Separate mask type bits
    ld   hl, DisMaskTable ; Point to table of mask bits
    add  a, l           ; Add to start of table
    ld   l, a           ; Store updated lo byte
    jr   nc, .DisWrOperandNoOFlow ; Skip if no overflow
    inc  h              ; Overflow so increment hi byte
.DisWrOperandNoOFlow:
    ld   a, (hl)        ; Get bit mask
    and  c              ; Mask primary opcode
    ld   c, a           ; Store masked primary opcode
    ld   a, (hl)        ; Get bit mask
    ;; Now shift primary opcode (masked) to right the number of
    ;; times it takes to shift mask byte right before bit 1 is set
.DisWrOperandSubsShift:
    srl  a              ; Shift mask right
    jr   c, .DisWrOperandDoneShift ; Bit 1 was set so we're done
    srl  c              ; Shift primary opcode (masked) right
    jr   .DisWrOperandSubsShift ; Go repeat..
.DisWrOperandDoneShift:
    bit  kDisLength, d  ; Length bit flagged?
    jr   z, .DisWrOperandSingle ; No, so skip
    sla  c              ; Double value for two bytes
    ;; C is now the offset into the substitute string
.DisWrOperandSingle:
    ld   a, e           ; Substitute string number
    ld   hl, DisString  ; Start of string list
    call FindStringInList ; Get start of string (=HL)
    ld   a, c           ; Offset into string
    add  a, l           ; Add to start of string
    ld   l, a           ; Store updated lo byte
    jr   nc, .DisWrOperandNoOver ; Skip if no overflow
    inc  h              ; Overflow so increment hi byte
.DisWrOperandNoOver:
    ld   a, (hl)        ; Get substitute character
    cp   '*'            ; Code for 2 byte HL/IX/IY string
    jr   nz, .DisWrOperandNotStar ; No, so skip
    ld   a, 24          ; String = "HL"
    call DisWrString    ; Print string with substitutions
    jr   .DisWrOperandSubEnd
.DisWrOperandNotStar:
    call DisWrChar      ; Print character with filters
    bit  kDisLength, d  ; Length bit flagged?
    jr   z, .DisWrOperandSubEnd ; No, so skip
    inc  hl             ; Point to second substitute character
    ld   a, (hl)        ; Get substitute character
    cp   '.'            ; Do not print '.' character
    call nz, DisWrChar  ; Print character with filters
.DisWrOperandSubEnd:
    pop  hl
    pop  de
    ret


    ;; Disassembler: Get instruction opcode
    ;;   On entry: A = Offset from start of instruction
    ;;             IY = Start of instruction
    ;;   On exit:  A = Opcode
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
DisGetOpcode:
    push bc
    push iy
    ld   c, a           ; Offset from start of instruction
    ld   b, 0           ; Clear hi byte ready for addition
    add  iy, bc         ; Calculate location of opcode
    ld   a, (IY+0)      ; Get opcode from memory
    pop  iy
    pop  bc
    ret


    ;; Disassembler: Write character to string buffer
    ;;   On entry: A = Character to write
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; This version of write character removes bit 7 (the new string flag)
    ;; and replaces "-" with "(HL)"
DisWrChar:
    push af
    and  0x7f           ; Mask off bit 7 (string start bit)
    cp   '-'            ; Code for "(HL)" ?
    jr   z, .DisWrCharSubHL ; Yes, so go write "(HL)" instead
    call StrWrChar      ; Print character
    jr   .DisWrCharDone
.DisWrCharSubHL:
    ld   a, 21          ; String number for "(HL)"
    call DisWrString    ; Write "(HL)" instead of "-"
.DisWrCharDone:
    pop  af
    ret                 ; JP instead to save byte


    ;; Write disassembler string
    ;;   On entry: A = Disassembler data string number
    ;;             B = Offset to current opcode from start of instruction
    ;;             IY = Start address for current instruction
    ;;             (iDisIndex) = Index instruction opcode or zero
    ;;   On exit:  AF C DE HL IX IY I AF' BC' DE' HL' preserved
    ;;             B is incremented if (IX/IY+d) is substituted
    ;; This version of write string removes bit 7 (the new string flag)
    ;; If iDisTmp1 (the current index instruction opcode) is 0xDD or 0xFD,
    ;; is not zero then strings are replaced:
    ;;   HL is replaced with IX or IY
    ;;   (HL) is replaced with (IX + d) or (IY + d) except for JP instruction
    ;;   where is is just replaced by (IX) or (IY)
DisWrString:
    push af
    push hl
    ld   l, a           ; Store string number
    cp   kDisBracHL     ; String = (HL) ?
    jr   z, .DisWrStringSubs ; Yes, so go do substitution
    cp   kDisHL         ; String = HL ?
    jr   nz, .DisWrStringGotString ; No, so just write the string
    ;; Substitute IX/IY in HL string or (IX/IY+d) in (HL) string
.DisWrStringSubs:
    ld   a, (iDisIndex) ; Get index instruction opcode
    or   a              ; Index instruction?
    jr   z, .DisWrStringGotString ; No, so skip substitutions
    inc  l              ; Increment to IX string number
    cp   0xdd           ; IX instruction?
    jr   z, .DisWrStringGotString ; Yes, so go write it
    inc  l              ; Increment to IY string
.DisWrStringGotString:
    ld   a, l           ; Get string number
    ld   hl, DisString  ; Start of string list
    call FindStringInList ; Find start of string A
    ;; HL now points to disassembler string
.DisWrStringChar:
    ld   a, (hl)        ; Get character from string
    and  0x7f           ; Mask off string start bit
    cp   '+'            ; Is it a '+' sign (displacement) ?
    jr   z, .DisWrStringPlus ; No, so skip to next character
    call StrWrChar      ; Write character
    jr   .DisWrStringNext ; No, so skip to next character
    ;; Encountered a plus sign so expecting to show a displacement
.DisWrStringPlus:
    ld   a, (iDisOpStr) ; Get instruction string
    cp   kDisJP         ; JP instruction?
    jr   nz, .DisWrStringDisplace ; No, so go show displacement
    ld   a, ')'         ; Yes, so just terminate with ')'
    call StrWrChar      ; Write close bracket character
    jr   .DisWrStringEnd
    ;; Show displacement in (IX+...) and (IY+...) instructions
.DisWrStringDisplace:
    ld   a, '+'
    call StrWrChar      ; Write plus character
    call WrHexPrefix
    ld   a, (IY+2)      ; Get index instruction displacement
    call StrWrHexByte   ; Write displacement in hex
    ld   a, ')'
    call StrWrChar      ; Write close bracket character
    inc  b              ; Increment opcode offset
    ;; Consider next character in disassembler string
.DisWrStringNext:
    inc  hl             ; Point to next character
    bit  7, (hl)        ; Start of new string?
    jr   z, .DisWrStringChar ; No, so go get next character
.DisWrStringEnd:
    pop  hl
    pop  af
    ret


    ;; **********************************************************************
    ;; **  Constant data                                                   **
    ;; **********************************************************************

    .section .rodata

    ;; Strings
szDisTo:
    .db  "  (to ", kNull


    ;; Operand table:
    ;;   Index into table is the operand string number 1 to 13)
    ;;   Contents: Substitution string number, function bits BIILMM
    ;;
    ;; Op  String  Offset  Bracket  Immediate  Substitue     subsLen  subsMask  ->  BIILMM
    ;;  1  =""     +0      No       No   (00)  No                n/a  n/a           000000
    ;;  2  ="n"    +1      No       Byte (10)  No                n/a  n/a           010000
    ;;  3  ="(n)"  +1      Yes      Byte (10)  No                n/a  n/a           110000
    ;;  4  ="nn"   +2      No       Word (11)  No                n/a  n/a           011000
    ;;  5  ="(nn)" +2      Yes      Word (11)  No                n/a  n/a           111000
    ;;  6  ="r"    +0      No       No   (00)  "BCDEHL-A"          1  0x38 (11)     000011
    ;;  7  ="r2"   +0      No       No   (00)  "BCDEHL-A"          1  0x07 (00)     000000
    ;;  8  ="dd"   +0      No       No   (00)  "BCDEHLSP"          2  0x30 (10)     000110
    ;;  9  ="qq"   +0      No       No   (00)  "BCDEHLAF"          2  0x30 (10)     000110
    ;; 10  ="c"    +0      No       No   (00)  "NZZ NCC "          2  0x18 (01)     000101
    ;; 11  ="cc"   +0      No       No   (00)  "NZZ NCC POPEP M "  2  0x38 (11)     000111
    ;; 12  ="t"    +0      No       No   (00)  "0008101820283038"  2  0x38 (11)     000111
    ;; 13  ="b"    +0      No       No   (00)  "01234567"          1  0x38 (11)     000011
    ;; Each table entry is coded with the string number plus a byte
    ;;   containing BIILMM bits
    ;; Length bit is hi for strings with two character substitutions
DisOperandTable:
    .db  0x00, 0x00     ; 0b000000 ;Operand  1 = ""
    .db  0x00, 0x10     ; 0b010000 ;Operand  2 = "n"
    .db  0x00, 0x30     ; 0b110000 ;Operand  3 = "(n)"
    .db  0x00, 0x18     ; 0b011000 ;Operand  4 = "nn"
    .db  0x00, 0x38     ; 0b111000 ;Operand  5 = "(nn)"
    .db  0x0e, 0x03     ; 0b000011 ;Operand  6 = "r"
    .db  0x0e, 0x00     ; 0b000000 ;Operand  7 = "r2"
    .db  0x0f, 0x06     ; 0b000110 ;Operand  8 = "dd"
    .db  0x10, 0x06     ; 0b000110 ;Operand  9 = "qq"
    .db  0x11, 0x05     ; 0b000101 ;Operand 10 = "c"
    .db  0x12, 0x07     ; 0b000111 ;Operand 11 = "cc"
    .db  0x13, 0x07     ; 0b000111 ;Operand 12 = "t"
    .db  0x14, 0x03     ; 0b000011 ;Operand 13 = "b"

    ;; Mask table
    ;; These are the masks used to separate token values such as
    ;;   register "BCDEHL-A"
    ;; The index into the table is coded in the two mask bits from the
    ;;   above table.
DisMaskTable:
    .db  0x07           ; Mask type 0
    .db  0x18           ; Mask type 1
    .db  0x30           ; Mask type 2
    .db  0x38           ; Mask type 3


    ;; Condition mask table
    ;; The condition mask table contains one byte for each condition flag:
    ;; NZ,Z,NC,C,PO,PE,P,M where offset into table is 0 for Z/NZ,
    ;;   1 for C/NC, etc
    ;; The value of each table entry is a bit mask, which when exclusively
    ;;   for the flags register
    ;; SZ-H-PNC   Condition, Flag, Description
DisConTab:
    .db  0x40           ; xZxxxxxx   NZ,        Z=0,  Not Zero
    .db  0x01           ; xxxxxxxC   NC,        C=0,  No Carry
    .db  0x04           ; xxxxxxxC   PO,        P=0,  Parity Odd
    .db  0x80           ; xxxxxxxC   PO,        S=0,  Positive


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iDisIndex:
    .db  0              ; Index instruction opcode
iDisOpStr:
    .db  0              ; Operation string number
iDisOp1Str:
    .db  0              ; Operand 1 string number
iDisOpcode:
    .db  0              ; Primary instruction opcode
iDisImmed:
    .dw  0              ; Immediate value


    ;; Disassembler: How it works...
    ;; Solution is to use data table to define functions for each operand
    ;;   (see below)
    ;; Decoding table: where the table entry is determined by the operand
    ;;   string number
    ;; String numbers 0 to 12:
    ;;   If bracket flagged print "("
    ;;   If immediate byte flagged print hex byte at PC+Offset+1, Offset += 1
    ;;   If immediate word flagged print word byte at PC+Offset+1 and PC+Offset+2, Offset += 2
    ;;   If bracket flagged print ")"
    ;;   If substitution string specified: (non-zero value)
    ;;     n = opcode and SubsMask
    ;;     n = n >> x, where x is the number of right shifts of the mask til bit 0 is a 1
    ;;     If subsLen is 2 then n = n << 1
    ;;     c =  character at (start of Substitution String + n + 0)
    ;;     if = "-" then print "(HL)" else print character c
    ;;     If SubsLen = 2 then
    ;;       print character at (start of Substitution String + n + 1)
    ;;     Endif
    ;;   End if


    ;; Single stepping
    ;; Instructions which can change flow of code (ie. alter PC)
    ;;   DJNZ d          10 nn      0001 0000
    ;;   JR   d          18 nn      0001 1000
    ;;   JR   c,  d      xx nn      001c c000
    ;;   JP   nn         C3 nn nn   1100 0011
    ;;   JP   cc, nn     xx nn nn   11cc c010
    ;;   JP   HL         E9         1110 1001
    ;;   JP   IX         DD E9      1110 1001
    ;;   JP   IY         FD E9      1110 1001
    ;;   CALL nn         CD nn nn   1100 1101
    ;;   CALL cc, nn     xx nn nn   11cc c100
    ;;   RET             C9         1100 1001
    ;;   RET  cc         xx         11cc c000
    ;;   RETI            ED 4D      0100 1101
    ;;   RETN            ED 45      0100 0101
    ;;   RST  aa         xx         11tt t111
    ;; Also an interrupt or reset signal changes PC
    ;; The above instructions are trapped after disassembly and the next
    ;; instruction determined. The breakpoint is then placed here to allow
    ;; single stepping.


    ;; **********************************************************************
    ;; **  End of Disassembler support module                              **
    ;; **********************************************************************

    #endif // IncludeDisassemble
