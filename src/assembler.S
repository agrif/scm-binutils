    ;; **********************************************************************
    ;; **  Assembler support                         by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides in-line assembly for a single instruction. It
    ;; provides one public function which assembles the supplied string:
    ;;
    ;; Function: Assemble
    ;; This takes the string pointed to by DE (eg. "LD A,2") and writes
    ;; the instruction's opcodes to the address pointed to by HL.
    ;;
    ;; This module requires the Disassembler support module to be included
    ;; as it makes heavy use of its functions and data.
    ;;
    ;; Assembly method:
    ;; Try each possible instruction in the DistInst list.
    ;; To save time the following are cached first:
    ;;   Operation string number
    ;;   Location of start of each operand string
    ;;   Each operand string is null terminated

    #ifdef IncludeAssembler

    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Assemble instruction in input buffer
    ;;   On entry: DE = Start location of buffer
    ;;             HL = Address to store opcodes
    ;;   On exit:  If instruction is valid:
    ;;               Opcodes written to memory
    ;;               A = Length of instruction in bytes and NZ flagged
    ;;               HL = Address of next instruction
    ;;             If invalid instruction:
    ;;               Opcodes not written to memory
    ;;               A = Error messgae number and Z flagged
    ;;                   0 = Unspecified error, so report 'Syntax error'
    ;;             IY I AF' BC' DE' HL' preserved
Assemble:
    call InputBufConvUpper ; Convert input string to upper case
    push hl             ; Preserve address of opcodes
    ld   b, 1           ; Length of instruction
    ;; Get operation string number
    ld   hl, DisString+1 ; Skip string 1 (blank string)
    ;;call SearchStringListNA
    call SearchStringList
    jr   z, .AssembleError ; Not found so error
    inc  a              ; Adjust as first string skipped
    ld   (iAsmOper), a  ; Store operation string number
    ;; Get operand 1 string start address
    call AsmSkipOverDelimiter
    ld   (iAsmOp1), de  ; Store operand 1 start address
    call AsmSkipToDelimiter
    ld   h, d           ; Remember start of delimiter
    ld   l, e
    ;; Get operand 2 string start address
    call AsmSkipOverDelimiter
    ld   (iAsmOp2), de  ; Store operand 2 start address
    call AsmSkipToDelimiter
    ;; Terminate operands and set default index instruction
    xor  a
    ld   (hl), a        ; Terminate operand 1 with null
    ld   (de), a        ; Terminate operand 2 with null
    ld   (iAsmIndex), a ; Default to no index instruction
    ld   (iAsmDisFl), a ; Clear displacement flag
    ;; Substitute HL for IX and IY
    ld   hl, (iAsmOp1)  ; Start of operand 1 string
    call AsmSubsIndex   ; Substitute HL for IX/IY in operand 1
    ld   hl, (iAsmOp2)  ; Start of operand 2 string
    call AsmSubsIndex   ; Substitute HL for IX/IY in operand 1
    ;; Try each instruction in the instruction list
    ld   ix, DisInst    ; Start of instruction list
.AssembleNext:
    xor  a              ; Clear A
    ld   (iAsmPri), a   ; Clear primary opcode special bits
    ld   (iAsmLenIm), a ; Clear length of immediate value
    call AsmTestInstruction
    jr   z, .AssembleFound ; Instruction found in table so skip
    push bc             ; Preserve BC
    ld   b, 5           ; Move IX to start of next
.AssembleInc:
    inc  ix             ;  table entry by adding 5
    djnz .AssembleInc
    pop  bc             ; Restore BC
    ld   a, (IX+1)      ; Get instruction bit mask
    or   a              ; Bit mask zero? (marks end of table)
    jr   nz, .AssembleNext ; No, so go try this instrucion
    ;; Operation string not found in table
.AssembleError:
    pop  hl             ; Restore address of opcodes
    xor  a              ; Return error A=0 and Z flagged
    ret
    ;; Found instruction, so write opcodes to memory
    ;; If there is an index instruction with displacement the displacement
    ;; value is always the third opcode of the instruction
.AssembleFound:
    pop  hl             ; Restore address of opcodes
    ld   c, 0           ; Clear opcode counter
    ;; Index instruction prefix
    ld   a, (iAsmIndex) ; Get index instuction opcode
    or   a              ; Zero? (not an index instruction)
    jr   z, .AssembleNoIndex ; Yes, so skip
    ld   (hl), a        ; Store index instruction opcode
    inc  hl             ; Increment opcode pointer
    inc  c              ; Increment opcode counter
.AssembleNoIndex:
    ;; Extended instruction prefix
    bit  7, (IX+3)      ; Extended instruction?
    jr   z, .AssembleNoExtn ; No, so skip
    ld   a, 0xcb        ; Default prefix = 0xCB
    bit  6, (IX+3)      ; Is Prefix = 0xED?
    jr   z, .AssembleGotPrefix ; No, so skip
    ld   a, 0xed        ; Prefix = 0xED
.AssembleGotPrefix:
    ld   (hl), a        ; Store extended instruction opcode
    inc  hl             ; Increment opcode pointer
    inc  c              ; Increment opcode counter
.AssembleNoExtn:
    ;; Index instruction displacement
    call .AssembleDisplace ; Optionally put displacement here
    ;; Primary opcode
    ld   a, (iAsmPri)   ; Get extra bits for primary opcode
    or   (IX+0)         ; Include primary opcode from table
    ld   (hl), a        ; Store primary opcode in memory
    inc  hl             ; Increment opcode pointer
    inc  c              ; Increment opcode counter
    ;; Index instruction displacement
    call .AssembleDisplace ; Optionally put displacement here
    ;; Immediate value
    ld   a, (iAsmLenIm) ; Get length of immediate value
    or   a              ; Zero? (no immediate value)
    jr   z, .AssembleNoImmed ; Yes, so skip
    ld   b, a           ; Remember length of immediate value
    ;; Is immediate value a relative jump?
    ld   a, (iAsmOper)  ; Get operation number
    cp   kDisJR         ; JR instruction ?
    jr   z, .AssembleRelJp ; Yes, so skip
    cp   kDisDJNZ       ; DJNZ instruction ?
    jr   nz, .AssembleGetImmed ; No, so skip
    ;; Immediate value is a relative jump
.AssembleRelJp:
    push hl             ; Preserve current opcode pointer
    ld   d, h           ; Get current address..
    ld   e, l
    inc  de             ; Increment to end of instruction
    ld   hl, (iAsmImmed) ; Get destination address..
    ld   a, h           ; If the value entered is a single
    or   a              ;  byte we skip the calculation
    ld   a, l           ;  and just use value supplied
    jr   z, .AssembleRelStore
    or   a              ; Clear carry flag
    sbc  hl, de         ; Calculate relative jump
    ;; Trap jump which is too bog
    jr   c, .AssembleRelJpNeg ; Skip if negative displacement
    ld   a, h           ; Get hi byte of displacement
    or   a              ; 0x00 ?
    jr   nz, .AssembleRelTooBig ; No, so too big
    bit  7, l           ; Test if < 128
    jr   z, .AssembleRelJpOK ; Skip if within range
    jr   .AssembleRelTooBig ; Displacement too big
.AssembleRelJpNeg:
    ld   a, h           ; Get hi byte of displacement
    inc  a              ; 0xFF ?
    jr   nz, .AssembleRelTooBig ; No, so too big
    bit  7, l           ; Test if > -128
    jr   nz, .AssembleRelJpOK ; Skip if within range
.AssembleRelTooBig:
    pop  hl             ; Restore opcode pointer
    jr   .AssembleTooBig ; Return with error
.AssembleRelJpOK:
    ld   a, l           ; Get relative jump
.AssembleRelStore:
    pop  hl             ; Restore opcode pointer
    ld   (hl), a        ; Store relative jump in memory
    inc  hl             ; Point to next opcode address
    jr   .AssembleNoImmed
    ;; Immediate value is not a relative jump
    ;; B = Length of immediate value in bytes (ie. 1 or 2)
.AssembleGetImmed:
    ld   a, b           ; Get length of immediate value
    cp   2              ; Two byte value?
    jr   z, .AssembleWrImmed ; Yes, so skip test for too big
    ld   a, (iAsmImmed+1) ; Get hi byte of immediate value
    or   a              ; Zero?
    jr   nz, .AssembleTooBig ; No, so value is too big
.AssembleWrImmed:
    ld   de, iAsmImmed  ; Get address of immediate value
.AssembleWrImLoop:
    ld   a, (de)        ; Get byte of immediate value
    ld   (hl), a        ; Write to memory
    inc  de             ; Point to next byte of immediate value
    inc  hl             ; Increment opcode pointer
    inc  c              ; Increment opcode counter
    djnz .AssembleWrImLoop ; Loop until immediate is finished
.AssembleNoImmed:
    ;; Return with length of instruction or failure flag
    ld   a, c           ; Return success A>0 and NZ flagged
    or   a              ;  or error A=0 and Z flagged
    ret
    ;; Return with failure flagged (immediate value to big)
.AssembleTooBig:
    xor  a              ; Return error A=0 and Z flagged
    ld   a, kMsgBadPar
    cp   a
    ret
    ;; Consider if displacement opcode should be stored here
.AssembleDisplace:
    ld   a, c           ; Get opcode counter
    cp   2              ; Opcode byte 2?
    ret  nz             ; No, so return
    ld   a, (iAsmDisFl) ; Get opcode displacement flag
    or   a              ; Zero? (no displacement)
    ret  z              ; Yes, so return
    ld   a, (iAsmDisp)  ; Get displacement value
    ld   (hl), a        ; Store as opcode
    inc  hl             ; Increment opcode pointer
    inc  c              ; Increment opcode counter
    xor  a              ; Clear A
    ld   (iAsmDisFl), a ; Clear displacement flag
    ret                 ;  as we've handled it


    ;; **********************************************************************
    ;; **  Private functions                                               **
    ;; **********************************************************************


    ;; Substitue index instruction (where appropriate)
    ;;   On entry: HL = Start of operand string
    ;;   On exit:  Operand string modified (where appropriate)
    ;;             iAsmPri, iAsmImmed, iAsmLenIm updated
    ;;             B IX IY I AF' BC' DE' HL' preserved
    ;; Substitute "HL" for "IX" or "IY"
    ;; Substitute "(HL)" for "(IX+d)" or "(IY+d)", and store displacement
    ;;   except for JP instruction which does not have a displacement
    ;; Substitute "-" for "(HL)" and thus also "(IX+d)" and "(IY+d)"
AsmSubsIndex:
    ld   d, h           ; Remember start of operand..
    ld   e, l
    ;; Is the operand string "(HL)" ?
    ld   a, (hl)        ; Get first character
    cp   '('            ; Is it '(' ?
    jr   nz, .AsmSubsIndexNoBrac ; No, so skip
    inc  hl             ; Point to second character
    ld   a, (hl)        ; Get second character
    cp   'H'            ; Is it 'H' ?
    jr   nz, .AsmSubsIndexNoBrac ; No, so skip
    inc  hl             ; Point to third character
    ld   a, (hl)        ; Get third character
    cp   'L'            ; Is it 'L' ?
    jr   nz, .AsmSubsIndexNoBrac ; No, so skip
    inc  hl             ; Point to fourth character
    ld   a, (hl)        ; Get fourth character
    cp   ')'            ; Is it ')' ?
    jr   z, .AsmSubsIndexSubMinus ; Yes, so we found "(HL)"
    ;; Not "(HL)" so check for "IX", "IY" (can have leading bracket)
.AsmSubsIndexNoBrac:
    cp   'I'            ; Operand character = 'I' ?
    ret  nz             ; No, so exit
    inc  hl             ; Point to next character
    ;;push bc
    ld   c, 0           ; Default to no index
    ld   a, (hl)        ; Get next character
    cp   'X'            ; Operand character = 'X' ?
    jr   nz, .AsmSubsIndexNotIndX ; No, so not index register X
    ld   c, 0xdd        ; Store IX opcode
.AsmSubsIndexNotIndX:
    cp   'Y'            ; Operand character = 'Y' ?
    jr   nz, .AsmSubsIndexNotIndY ; No, so not index register Y
    ld   c, 0xfd        ; Store IX opcode
.AsmSubsIndexNotIndY:
    ld   a, c           ; Get index opcode (if there is one)
    ;;pop  bc
    or   a              ; Is this an index instruction?
    ret  z              ; No, so exit
    ;; We found IX or IY, so replace with "HL"
    ld   (iAsmIndex), a ; Store index opcode
    dec  hl             ; Point to previous character ('I')
    ld   (hl), 'H'      ; Replace with 'H'
    inc  hl             ; Point to next character
    ld   (hl), 'L'      ; Replace with 'L'
    ;; Now look for <+displacement> eg. "(IX+12)"
    ;; Replacing with "-" and storing displacement value
    ld   a, (iAsmOper)  ; Get instruction number
    cp   kDisJP         ; JP instruction?
    ret  z              ; Yes, so abort as no displacement
    inc  hl             ; Point to next character
    ld   a, (hl)        ; Get next character
    cp   '+'            ; Displacement to follow?
    ret  nz             ; No, so exit
    ;; We are not bothering to raise an error for bad syntax here
    ;; as it gets trapped later.
    push de             ; Preserve start of operand string
    inc  hl             ; Point to displacement string
    ld   d, h           ; Get address hi byte of string
    ld   e, l           ; Get address lo byte of string
    call ConvertStringToNumber
    ld   a, l           ; Get lo byte of number
    ld   (iAsmDisp), a  ; Store as displacement
    ld   a, 0xff        ; Get value to use as flag
    ld   (iAsmDisFl), a ; Flag displacement present
    pop  de             ; Restore start of operand string
    ;; Store "-" in string instead of "(HL)" or "(IX+d)" or "(IY+d)"
    ;; Except for JP (HL) or (IX) or (IY)
.AsmSubsIndexSubMinus:
    ld   a, (iAsmOper)  ; Get instruction number
    cp   kDisJP         ; JP instruction?
    ret  z              ; Yes, so abort
    ld   h, d           ; Restore to start of operand..
    ld   l, e
    ld   (hl), '-'      ; Replace operand string with "-"
    inc  hl
    ld   (hl), 0        ; Terminate operand string
.AsmSubsIndexNotInd:
    ret


    ;; Skip over delimiter
    ;;   On entry: DE = Start of target string
    ;;   On exit:  DE = Address of first non-delimiter or null
    ;;             If null found then A=0 and Z flagged
    ;;             If other non-delimiter found then A>0 and NZ flagged
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;; A delimiter is a space, a comma or any control character other than null.
    ;; The address returned can be that of the string's null terminator.
AsmSkipOverDelimiter:
.AsmSkipOverDelimiterLoop:
    ld   a, (de)        ; Get character from input line
    or   a              ; End of line (null)?
    ret  z              ; Yes, so return with Z flagged
    cp   ','            ; Comma?
    jr   z, .AsmSkipOverDelimiterNext ; Yes, so skip
    cp   kSpace+1       ; Character > space?
    jr   nc, .AsmSkipOverDelimiterOther ; Yes, so skip
.AsmSkipOverDelimiterNext:
    inc  de             ; No, so skip delimiter
    jr   .AsmSkipOverDelimiterLoop ;  and go try next character
.AsmSkipOverDelimiterOther:
    or   a              ; Return NZ as non-delimiter other
    ret                 ;  than null


    ;; Skip to delimiter
    ;;   On entry: DE = Start of target string
    ;;   On exit:  DE = Address of first delimiter or null
    ;;             If null found then A=0 and Z flagged
    ;;             If delimiter found then A>0 but Z flag unknown
    ;;             A=0 and Z flagged if non-delimter is not found
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;; A delimiter is a space, a comma or any control character other than null.
    ;; The address returned can be that of the string's null terminator.
AsmSkipToDelimiter:
.AsmSkipToDelimiterLoop:
    ld   a, (de)        ; Get character from input line
    or   a              ; End of line (null)?
    ret  z              ; Yes, so return with Z flagged
    cp   ','            ; Comma?
    ret  z              ; Yes, so return with Z flagged
    cp   kSpace+1       ; Character > space?
    ret  c              ; No, so return with NZ flagged
.AsmSkipToDelimiterNext:
    inc  de             ; Yes, so skip non-delimiter
    jr   .AsmSkipToDelimiterLoop ;  and go try next character


    ;; Test if instruction matches table entry
    ;;   On entry: IX = Instruction table entry address
    ;;             iAsmOper = Operation string number
    ;;             iAsmOp1 = Pointer to start of operand 1 string
    ;;             iAsmOp2 = Pointer to start of operand 2 string
    ;;   On exit:  If match found A = 0 and Z flagged
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;;   Calls AsmTestOperand:
    ;;             iAsmPri, iAsmImmed, iAsmLenIm updated
AsmTestInstruction:
    ld   a, (iAsmOper)  ; Get operation string number
    cp   (IX+2)         ; Compare with table
    ret  nz             ; Failed so return NZ
    ld   de, (iAsmOp1)  ; Get address of operand 1 string
    ld   a, (IX+3)      ; Get operand 1 string number
    and  0x3f           ; Mask away unwanted bits
    call AsmTestOperand ; Test this operand
    ret  nz             ; Failed so return NZ
    ld   de, (iAsmOp2)  ; Get address of operand 2 string
    ld   a, (IX+4)      ; Get operand 2 string number
    and  0x3f           ; Mask away unwabted bits
    call AsmTestOperand ; Test this operand
    ret  nz             ; Failed so return NZ
    ;;ld   (iAsmOp2), hl ; Store result of operand 2
    ;; Succeeded in finding instruction in table
.AsmTestInstructionSuccess:
    xor  a              ; Success so return Z
    ret


    ;; Test if operand matches table entry
    ;;   On entry: A = Operand string number from table
    ;;             DE = Start of target operand string
    ;;             IX = Instruction table entry address
    ;;             iAsmOper = Operation string number
    ;;             iAsmOp1 = Pointer to start of operand 1 string
    ;;             iAsmOp2 = Pointer to start of operand 2 string
    ;;   On exit:  If match found A = 0 and Z flagged
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;;             iAsmPri, iAsmImmed, iAsmLenIm updated
AsmTestOperand:
    ld   c, a           ; Store string number from table
    cp   kDisSubsL+1    ; Is operand a substitution string?
    jr   c, .AsmTestOperandSubs ; Yes, so skip
    ;; Operand is a constant string which should be in string list
    ld   hl, DisString+1 ; Skip string 1 (blank string)
    ;;call SearchStringListNA
    call SearchStringList
    jr   z, .AsmTestOperandFailure ; Not found so failure
    inc  a              ; Adjust for first string number
    cp   c              ; Do strings match?
    jr   z, .AsmTestOperandSuccess ; Yes, so we've found it
    jr   .AsmTestOperandFailure ; No, so go return failure
    ;; Operand in table is a substitution string
.AsmTestOperandSubs:
    cp   1              ; String 1 = ""
    jr   nz, .AsmTestOperandNotNull
    ld   a, (de)        ; Get operand's first character
    or   a              ; Null
    ret  z              ; Yes, so return success
.AsmTestOperandNotNull:
    ;; Calculate operand table location for this operand and get details
    ld   hl, DisOperandTable-2
    add  a, a           ; Two bytes per entry
    add  a, l           ; Add to start of table
    ld   l, a           ; Store updated lo byte
    jr   nc, .AsmTestOperandNoOverFlo ; Skip if no overflow
    inc  h              ; Overflow so increment hi byte
.AsmTestOperandNoOverFlo:
    ld   c, (hl)        ; Get substitution string number
    inc  hl             ; Point to BIILMM bits
    ld   b, (hl)        ; Get BIILMM function bits
    ;;push de           ; So we can use E for scratch reg
    ;; Process this operand as detailed in DE, left bracket?
    bit  kDisBrack, b   ; Bracket flagged?
    jr   z, .AsmTestOperandNoBracL ; No, so skip
    ld   a, (de)        ; Get char from target string
    inc  de             ; Point to next char in target
    cp   '('            ; Is it a left bracket character?
    jr   nz, .AsmTestOperandFailure
.AsmTestOperandNoBracL:
    ;; Process this operand as detailed in BC, immediate value?
    bit  kDisImmed, b   ; Immediate value flagged?
    jr   z, .AsmTestOperandNoImmedia ; No, so skip
    call ConvertStringToNumber
    jr   nz, .AsmTestOperandFailure
    ld   (iAsmImmed), hl ; Store immediate value
    ld   a, 1
    bit  kDisWord, b    ; Immediate value is a word?
    jr   z, .AsmTestOperandImmedLo ; No, so skip
    inc  a              ; Increment offset to hi byte
.AsmTestOperandImmedLo:
    ld   (iAsmLenIm), a ; Store length of immediate value
.AsmTestOperandNoImmedia:
    ;; Process this operand as detailed in DE, right bracket?
    bit  kDisBrack, b   ; Bracket flagged?
    jr   z, .AsmTestOperandNoBracR ; No, so skip
    ld   a, (de)        ; Get char from target string
    inc  de             ; Point to next char in target
    cp   ')'            ; Is it a left bracket character?
    jr   nz, .AsmTestOperandFailure
.AsmTestOperandNoBracR:
    ;; Process this operand as detailed in DE, substitution string?
    ld   a, c           ; Get substitution string number?
    or   a              ; Substitution string?
    jr   z, .AsmTestOperandSuccess ; No, so we've finished
    ;; A = Substitution string number eg. "CDEHL-A"
    ;; Find the substitution string and search it for target string
    ld   hl, DisString  ; Start of disassembler's string list
    call FindStringInList ; Set HL=Start of substitution string
    call .AsmTestOperandInstring ; Look for target in subs string
    jr   nz, .AsmTestOperandFailure
    ;; C = Target string's position in substitution string (0 to 3)
    ;; B = Function bits BIILMM from DisOperandTable
    ;; Convert position to bit pattern for instruction opcode
    ;; Do this by shifting bits right as many times as it takes to shift
    ;; right the mask, from masktable, to get a one in the carry flag.
    ld   a, b           ; Get BIILMM function bits
    and  kDisMask       ; Separate mask type bits
    ld   hl, DisMaskTable ; Point to table of mask bits
    add  a, l           ; Add to start of table
    ld   l, a           ; Store updated lo byte
    jr   nc, .AsmTestOperandNoOFlow ; Skip if no overflow
    inc  h              ; Overflow so increment hi byte
.AsmTestOperandNoOFlow:
    ld   b, (hl)        ; Get bit mask from mask table
    ld   a, c           ; Get position in string
.AsmTestOperandSubsShift:
    srl  b              ; Shift mask right
    jr   c, .AsmTestOperandDoneShift ; If bit 1 was set then we're done
    rlca                ; Shift position/opcode bits left
    jr   .AsmTestOperandSubsShift ; Go repeat..
.AsmTestOperandDoneShift:
    ld   hl, iAsmPri    ; Point to primary opcode bits
    or   (hl)           ; Include new bits
    ld   (hl), a        ; Store primary opcode bits
    jr   .AsmTestOperandSuccess
    ;; Failed to find operand in table etc
.AsmTestOperandFailure:
    ld   a, 0xff
    or   a              ; Failure so return NZ
    ret
    ;; Succeeded in finding operand in table
.AsmTestOperandSuccess:
    xor  a              ; Success so return Z
    ret


    ;; Instring function
    ;;   On entry: A = Substitution string number
    ;;             DE = Start of target string (1 or 2 characters)
    ;;             HL = Start of substitution string
    ;;   On exit:  If match found Z flagged, and
    ;;               C = Position in substitution string (0 to 3)
    ;;             B IX IY I AF' BC' DE' HL' preserved
    ;; Subroutine to look for target string (DE) is substitution string (HL)
    ;; Substitution string may be something like this: "BCDEHL-A"
    ;; Target string may be something like "BC"<null>
    ;; Substitution strings are delimited by first character having bit 7 set
    ;; Target strings can be one or two characters long and null terminated
.AsmTestOperandInstring:
    ;; Special handling for RST instruction
    cp   0x13           ; Substution of RST address?
    jr   nz, .AsmTestOperandInStNotRST ; Skip if not RST instruction
    push hl
    call ConvertStringToNumber ; Convert string at DE
    ld   a, l           ; Get operand
    call ConvertByteToNibbles
    ld   a, d           ; Get MSByte of operand
    or   '0'            ; Convert to ASCII
    ld   (kStrBuffer+$70), a ; Store in temporary space
    ld   a, e           ; Get MSByte of operand
    or   '0'            ; Convert to ASCII
    ld   (kStrBuffer+$71), a ; Store in temporary space
    xor  a              ; Clear A as string terminator
    ld   (kStrBuffer+$72), a ; StoreRST 00 in temporary space
    ld   de, kStrBuffer+$70
    pop  hl
.AsmTestOperandInStNotRST:
    ;; Handle standard formats
    ld   c, 0xff        ; Count poisition in subs string
    bit  kDisLength, b  ; Two character substitution
    jr   nz, .AsmTestOperandInstr2 ; Yes, so go..
    ;; Single byte target string
.AsmTestOperandNextS1:
    inc  c              ; Count position in subs string
    ld   a, (de)        ; Get character from target string
    xor  (hl)           ; Compare with char from subs string
    and  0x7f           ; Mask off start of string bit
    jr   z, .AsmTestOperandInstrOK ; Skip if characters match
    inc  hl             ; Try next character in subs string
    bit  7, (hl)        ; End of substitution string?
    jr   z, .AsmTestOperandNextS1 ; No, so try next character
    ret                 ; Return failure (NZ flagged)
    ;; Two byte target string
.AsmTestOperandInstr2:
    inc  c              ; Count position in subs string
    ld   a, (de)        ; Get character from target string
    cp   'H'            ; Substitute '*' for 'H'...
    jr   nz, .AsmTestOperandNotH
    ld   a, '*'
.AsmTestOperandNotH:
    xor  (hl)           ; Compare with char from subs string
    and  0x7f           ; Mask off start of string bit
    inc  hl             ; Prepare to try next char in subs
    jr   nz, .AsmTestOperandInstrN1 ; Skip if chars don't match
    inc  de             ; Compare with second char in target
    ld   a, (de)        ; Get character from target string
    cp   'L'            ; Substitute '*' for 'L'...
    jr   nz, .AsmTestOperandNotL
    ld   a, '*'
.AsmTestOperandNotL:
    xor  (hl)           ; Compare with char from subs string
    jr   z, .AsmTestOperandInstrOK ; Characters match so go..
    dec  de             ; Compare with first char in target
    ld   a, (hl)        ; Check if subs is a null character
    cp   '.'            ;  represented by a '.'
    jr   z, .AsmTestOperandInstrOK ; Yes, so go..
.AsmTestOperandInstrN1:
    inc  hl             ; Point to next pair in subs string
.AsmTestOperandInstrNext:
    bit  7, (hl)        ; End of substitution string?
    jr   z, .AsmTestOperandInstr2 ; No, so try next character
    ret                 ; Return failure (NZ flagged)
    ;; Strings match so check there are no more chars in target string
.AsmTestOperandInstrOK:
    inc  de             ; Check next char in target is null
    ld   a, (de)        ; Get character from target string
    or   a              ; Null?
    ret                 ; Yes, so return success(Z)/failure(NZ)


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iAsmOper:
    .db  0              ; Instruction operation number
iAsmOp1:
    .dw  0              ; Instruction operand 1 number
iAsmOp2:
    .dw  0              ; Instruction operand 2 number
iAsmIndex:
    .db  0              ; Index instruction opcode
iAsmPri:
    .db  0              ; Primary opcode
iAsmImmed:
    .dw  0              ; Immediate value
iAsmLenIm:
    .db  0              ; Length of immedaite value
iAsmDisp:
    .db  0              ; Displacement value
iAsmDisFl:
    .db  0              ; Displacement flag


    ;; **********************************************************************
    ;; **  End of Assembler support module                                 **
    ;; **********************************************************************

    #endif // IncludeAssembler
