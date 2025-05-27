    ;; **********************************************************************
    ;; **  Utility functions                         by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides a group of utility functions
    ;;   ConvertBCDToBinary    Convert BCD to binary
    ;;   ConvertBinaryToBCD    Convert binary to BCD
    ;;   ConvertByteToAscii    Convert byte to ASCII character
    ;;   ConvertByteToNibbles  Convert byte to nibbles
    ;;   ConvertCharToLCase    Convert character to lower case
    ;;   ConvertCharToNumber   Convert character to numeric value
    ;;   ConvertCharToUCase    Convert character to upper case
    ;;   ConvertStringToNumber Convert hex or decimal string to number
    ;;   FindStringInList      Find start of string in bit 7 delimited list
    ;;   IsCharHex             Is character hexadecimal (0 to 9, A to F)
    ;;   IsCharNumeric         Is character numeric (0 to 9)
    ;;   SearchStringList      Find number of string in bit 7 delimited list
    ;;   SearchStringListNA    Find number of string in bit 7 delimited list
    ;;   WrHexPrefix           Write hex prefix to current string buffer
    ;;   WrInstruction         Write disassembled instruction to buffer
    ;;   WrMemoryDump          Write memory dump line to string buffer
    ;;   WrRegister1           Write registers line 1 to string buffer
    ;;   WrRegister2           Write registers line 2 to string buffer

    #ifdef IncludeUtilities

    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    #ifdef kIncludeUnusedCode
    ;; Utility: Convert BCD to binary
    ;;   On entry: A = BCD byte
    ;;   On exit:  A = Binary byte
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts not enabled
    ;; Method: Determine the value in the top nibble of the supplied BCD
    ;; number, then subtract 6 from the BCD number that many times.
    ;; So for a BCD number of 45 (hex value 0x45), subtract 4 x 6 from
    ;; 0x45 = 0x45 - (4 * 6) = 0x45 - 24 = 69 - 24 = 45 = 0x2D
ConvertBCDToBinary:
    push bc
    ld   c, a           ; Store BCD number
    srl  a              ; Shift top nibble to
    srl  a              ;  bottom nibble and
    srl  a              ;  clear top nibble
    srl  a              ;  so 45 BCD =>  4
    ld   b, a           ; Store shifted value as counter
    or   a              ; Set zero flag if result is zero
    ld   a, c           ; Get original BCD number
    jr   z, .ConvertBCDToBinaryZJB ; Skip if shifted value is zero
.ConvertBCDToBinaryZJA:
    sub  6              ; Subtract 6 from BCD number
    djnz .ConvertBCDToBinaryZJA ; Repeat until counter is zero
.ConvertBCDToBinaryZJB:
    pop  bc
    ret
    #endif


    #ifdef kIncludeUnusedCode
    ;; Utility: Convert binary to BCD
    ;;   On entry: A = Binary byte
    ;;   On exit:  A = BCD byte
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts not enabled
    ;; Values > 99 decimal roll over, so 129 is returned as 29
ConvertBinaryToBCD:
    push bc
    ld   c, 0           ; Build result in C
.ConvertBinaryToBCDZAB:
    cp   10             ; Remaining value > 9?
    jr   c, .ConvertBinaryToBCDZAA ; No, so finish loop
    sub  10             ; Subtract 10 from remainder
    ld   b, a           ; Store remaining value
    ld   a, c           ; Get result so far
    add  0x10           ; Add 0x10 (10 in BCD)
    cp   0xa0           ; Result > 0x90? (90 in BCD)
    jr   c, .ConvertBinaryToBCDZAC ; No, so skip
    xor  a              ; Yes, so clear result to 0
.ConvertBinaryToBCDZAC:
    ld   c, a           ; Store result so far
    ld   a, b           ; Get remaining value
    jr   .ConvertBinaryToBCDZAB ; Loop round again
.ConvertBinaryToBCDZAA:
    add  a, c           ; Add remainder to result
    pop  bc
    ret
    #endif


    ;; Utility: Convert byte to ascii character
    ;;   On entry: A = Byte
    ;;   On exit:  A = ASCII character
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts enabled during this call
    ;; If not printable then a dot is output instead.
ConvertByteToAscii:
    cp   32             ; <SPACE?
    jr   c, .ConvertByteToAsciiZGW
    cp   0x7f           ; >&7F?
    jr   c, .ConvertByteToAsciiZGX
.ConvertByteToAsciiZGW:
    ld   a, '.'
.ConvertByteToAsciiZGX:
    ret


    ;; Utility: Convert byte to nibbles
    ;;   On entry: A = Hex byte
    ;;   On exit:  D = Most significant nibble
    ;;             E = Least significant nibble
    ;;             A BC HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts not enabled
ConvertByteToNibbles:
    push af
    ld   e, a           ; Get byte to convert
    rra                 ; Shift top nibble to
    rra                 ;  botom four bits..
    rra
    rra
    and  0x0f           ; Mask off unwanted bits
    ld   d, a           ; Store top nibble
    ld   a, e           ; Get byte to convert
    and  0x0f           ; Mask off unwanted bits
    ld   e, a           ; Store bottom nibble
    pop  af
    ret


    #ifdef kIncludeUnusedCode
    ;; Utility: Convert character to lower case
    ;;   On entry: A = Character in either case
    ;;   On exit:  A = Character in lower case
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
ConvertCharToLCase:
    cp   'A'            ; Character less than 'A'?
    ret  c              ; Yes, so finished
    cp   'Z'+1          ; Character greater than 'Z'?
    ret  nc             ; Yes, so finished
    add  'a'-'A'        ; Convert case
    ret
    #endif


    ;; Utility: Convert character to numberic value
    ;;   On entry: A = ASCII character (0-9 or A-F)
    ;;   On exit:  If character is a valid hex digit:
    ;;               A = Numberic value (0 to 15) and Z flagged
    ;;             If character is not a valid hex digit:
    ;;               A = 0xFF and NZ flagged
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts not enabled
ConvertCharToNumber:
    call ConvertCharToUCase
    cp   '0'            ; Character < '0'?
    jr   c, .ConvertCharToNumberBad ; Yes, so no hex character
    cp   '9'+1          ; Character <= '9'?
    jr   c, .ConvertCharToNumberOK ; Yes, got hex character
    cp   'A'            ; Character < 'A'
    jr   c, .ConvertCharToNumberBad ; Yes, so not hex character
    cp   'F'+1          ; Character <= 'F'
    jr   c, .ConvertCharToNumberOK ; No, not hex
    ;; Character is not a hex digit so return
.ConvertCharToNumberBad:
    ld   a, 0xff        ; Return status: not hex character
    or   a              ;  A = 0xFF and NZ flagged
    ret
    ;; Character is a hex digit so adjust from ASCII to number
.ConvertCharToNumberOK:
    sub  '0'            ; Subtract '0'
    cp   0x0a           ; Number < 10 ?
    jr   c, .ConvertCharToNumberFinished ; Yes, so finished
    sub  0x07           ; Adjust for 'A' to 'F'
.ConvertCharToNumberFinished:
    cp   a              ; Return A = number (0 to 15) and Z flagged to
    ret                 ;  indicate character is a valid hex digital


    ;; Utility: Convert character to upper case
    ;;   On entry: A = Character in either case
    ;;   On exit:  A = Character in upper case
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
ConvertCharToUCase:
    cp   'a'            ; Character less than 'a'?
    ret  c              ; Yes, so finished
    cp   'z'+1          ; Character greater than 'z'?
    ret  nc             ; Yes, so finished
    sub  'a'-'A'        ; Convert case
    ret


    ;; Utility: Convert hexadecimal or decimal text to number
    ;;   On entry: DE = Pointer to start of ASCII string
    ;;   On exit:  If valid number found:
    ;;               A = 0 and Z flagged
    ;;               HL = Number found
    ;;             If valid number not found:
    ;;               A != 0 and NZ flagged
    ;;               HL = Not specified
    ;;             DE = Not specified
    ;;             HL = Number
    ;;             BC DE IX IY I AF' BC' DE' HL' preserved
    ;; Hexadecmal numbers can be prefixed with either "$" or "0x"
    ;; Decimal numbers must be prefixed with "+"
    ;; A number without a prefix is assumed to be hexadecimal
    ;; Hexadecimal number without a prefix must start with "0" to "9"
    ;; ... this is to stop the assembler getting confused between
    ;; ... register names and constants which could be fixed by
    ;; ... re-ordering the (dis)assebmer's instruction table
    ;; Numbers can be terminated with ")", space, null or control code
    ;; Negative numbers, preceded with "-", are not supported
    ;; Text must be terminated with ')', space or control char.
ConvertStringToNumber:
    push bc
    ld   hl, 0          ; Build result here
    ld   a, (de)        ; Get character from string
    cp   '+'            ; Does string start with '+' ?
    jr   z, .ConvertStringToNumberDecimal ; Yes, so its decimal
    cp   '$'            ; Does string start with '$' ?
    jr   z, .ConvertStringToNumberHdecimal ; Yes, so its hexadecimal
    cp   kApostroph     ; Does string start with apostrophe?
    jr   z, .ConvertStringToNumberChar ; Yes, so its a character
    cp   kQuote         ; Does string start with '"' ?
    jr   z, .ConvertStringToNumberChar ; Yes, so its a character
    ;;call IsCharNumeric ; Is first character '0' to '9' ?
    ;;jr   nc, .ConvertStringToNumberFailure ; No, so invalid number
    ;;call IsCharHex    ; Is first character hexadecimal ?
    ;;jr   nc, .ConvertStringToNumberFailure ; No, so invalid hex character
    cp   '0'            ; Is first character '0' ?
    jr   nz, .ConvertStringToNumberHexNext ; No, so default to hexadecimal
    ;;jr   nz, .ConvertStringToNumberDecNext ; No, so default to decimal
    inc  de             ; Point to next character in string
    ld   a, (de)        ; Get character from string
    call ConvertCharToUCase
    cp   'X'            ; Is second character 'x' ?
    jr   nz, .ConvertStringToNumberHexNext ; No, so must be default format
    ;;jr   nz, .ConvertStringToNumberDecNext ; No, so must be default format
    ;; Hexadecimal number...
.ConvertStringToNumberHdecimal:
    inc  de             ; Point to next character in string
.ConvertStringToNumberHexNext:
    ld   a, (de)        ; Get character from string
    cp   ')'            ; Terminated with a bracket?
    jr   z, .ConvertStringToNumberSuccess ; yes, so success
    cp   kSpace+1       ; Space or control character?
    jr   c, .ConvertStringToNumberSuccess ; Yes, so successld hl
    call ConvertCharToNumber ; Convert character to number
    jr   nz, .ConvertStringToNumberFailure ; Return if failure (NZ flagged)
    inc  de             ; Point to next character in string
    add  hl, hl         ; Current result = 16 * current result..
    add  hl, hl
    add  hl, hl
    add  hl, hl
    or   l              ; Add new number (0 to 15)..
    ld   l, a
    jr   .ConvertStringToNumberHexNext
    ;; Decimal number...
.ConvertStringToNumberDecimal:
    inc  de             ; Point to next character in string
.ConvertStringToNumberDecNext:
    ld   a, (de)        ; Get character from string
    cp   ')'            ; Terminated with a bracket?
    jr   z, .ConvertStringToNumberSuccess ; yes, so success
    cp   kSpace+1       ; Space or control character?
    jr   c, .ConvertStringToNumberSuccess ; Yes, so success
    call IsCharNumeric  ; Is first character '0' to '9' ?
    jr   nc, .ConvertStringToNumberFailure ; No, so invalid number
    call ConvertCharToNumber ; Convert character to number
    jr   nz, .ConvertStringToNumberFailure ; Return if failure (NZ flagged)
    inc  de             ; Point to next character in string
    push de
    ld   b, 9           ; Current result = 10 * current result..
    ld   d, h
    ld   e, l
.ConvertStringToNumberDecLoop:
    add  hl, de         ; Add result to itself 9 times
    djnz .ConvertStringToNumberDecLoop
    pop  de
    add  a, l           ; Add new number (0 to 15)..
    ld   l, a
    jr   nc, .ConvertStringToNumberDecNext
    inc  h
    jr   .ConvertStringToNumberDecNext
    ;; Character...
.ConvertStringToNumberChar:
    inc  de             ; Point to next character in string
    ld   a, (de)        ; Get ASCII character
    ld   l, a           ; Store ASCII value as result
    ld   h, 0
    ;;jr   .ConvertStringToNumberSuccess
    ;; Return result...
.ConvertStringToNumberSuccess:
    pop  bc
    xor  a              ; Return success with A = 0 and Z flagged
    ret
.ConvertStringToNumberFailure:
    pop  bc
    ld   a, 0xff        ; Return failure with A != 0
    or   a              ;  and NZ flagged
    ret


    ;; Utility: Find start of specified string in bit 7 delimited list
    ;;   On entry: A = String number
    ;;             HL = Start of string list
    ;;   On exit:  HL = Start of string
    ;;             AF BC DE IX IY I AF' BC' DE' HL' preserved
    ;; Find string A in bit 7 delimited string list
FindStringInList:
    push af
    push bc
    dec  hl             ; Point to address before string list
    ld   b, a           ; Get string number
.FindStringInListNext:
    inc  hl             ; Point to next character
    bit  7, (hl)        ; Start of new string?
    jr   z, .FindStringInListNext ; No, so go get next character
    djnz .FindStringInListNext ; Loop back if not the right string
    pop  bc
    pop  af
    ret


    ;; Utility: Is character hexadecimal?
    ;;   On entry: A = ASCII character
    ;;   On exit:  Carry flag set if character is hexadecimal (0 to 9, A to F)
    ;;             A BC DE HL IX IY I AF' BC' DE' HL' preserved
IsCharHex:
    cp   '0'            ; Less than '0'?
    jr   c, .IsCharHexNot ; Yes, so go return NOT hex
    cp   '9'+1          ; Less than or equal to '9'?
    ret  c              ; Yes, so numeric (C flagged)
    call ConvertCharToUCase
    cp   'A'            ; Less than 'A'
    jr   c, .IsCharHexNot ; Yes, so go return NOT hex
    cp   'F'+1          ; Less than or equal to 'F'?
    ret  c              ; Yes, so hexadecimal (C flagged)
.IsCharHexNot:
    or   a              ; No, so NOT numeric (NC flagged)
    ret


    ;; Utility: Is character numeric?
    ;;   On entry: A = ASCII character
    ;;   On exit:  Carry flag set if character is numeric (0 to 9)
    ;;             A BC DE HL IX IY I AF' BC' DE' HL' preserved
IsCharNumeric:
    cp   '0'            ; Less than '0'?
    jr   c, .IsCharNumericNot ; Yes, so go return NOT numeric
    cp   '9'+1          ; Less than or equal to '9'?
    ret  c              ; Yes, so numeric (C flagged)
.IsCharNumericNot:
    or   a              ; No, so NOT numeric (NC flagged)
    ret


    ;; Utility: Find number of matching string in bit 7 delimited string list
    ;;   On entry: BC = Start of address list
    ;;             DE = Start of target string
    ;;             HL = Start of bit 7 delimited string list
    ;;   On exit:  If string found in list:
    ;;               A = String number in list (1 to 127) and NZ flagged
    ;;               DE = Next address after target string
    ;;               HL = Address from address list
    ;;             If string not found in list:
    ;;               A = 0 and Z flagged
    ;;               DE = Start of target string (preserved)
    ;;               HL = Not specified
    ;;             BC IX IY I AF' BC' DE' HL' preserved
    ;; Target string can be terminated with and control character or a space.
SearchStringList:
    push bc             ; Preserve start of address table
    ld   b, 0           ; String counter
    push de             ; Preserve start of target string
    ;; Find start of next string in list
.SearchStringListNextStr:
    inc  b              ; Increment string count
    pop  de             ; Restore start of target string
    push de             ; Preserve start of target string
.SearchStringListNextChar:
    bit  7, (hl)        ; Start of new string?
    jr   nz, .SearchStringListCompNext ; Yes, so go compare characters
    inc  hl             ; No, so point to next character
    jr   .SearchStringListNextChar ;  and go consider it
    ;; Compare target string (at DE) with string from list (at HL)
.SearchStringListCompNext:
    ld   a, (hl)        ; Get character from list
    cp   0x80           ; End of list?
    jr   z, .SearchStringListFailed ; Yes, so failed to find string
.SearchStringListCompChar:
    ld   a, (hl)        ; Get character from list string
    and  0x7f           ; Mask off bit 7 start flag
    ld   c, a           ; Store upper case char from list
    ld   a, (de)        ; Get character from target string
    inc  hl             ; Point to next character in list
    inc  de             ; Point to next character in target
    call ConvertCharToUCase
    cp   c              ; Match with list character?
    jr   nz, .SearchStringListNextStr ; No, so go try next list string
    ;; Strings matching so far so check for end of both
    ld   a, (de)        ; Get character from target
    ;;cp   kSpace+1     ; End if target string?
    ;;jr   c, .SearchStringListbbrev ; Yes, so go (allow abbreviations)
    cp   kSpace+1       ; End of target string?
    jr   c, .SearchStringListEndT ; Yes, so go check end of list str
    bit  7, (hl)        ; End of string in list?
    jr   z, .SearchStringListCompChar ; No, so go compare next character
    jr   .SearchStringListNextStr ; Yes, so go try next string
    ;; End of target string found
.SearchStringListEndT:
    bit  7, (hl)        ; End of string in list as well?
    jr   z, .SearchStringListNextStr ; No, so go try next string
    ;; Found target string in string list
    ;; So get address from address list
    ;;.SearchStringListAbbrev:
    pop  hl             ; Restore start of target string
    pop  hl             ; Restore start of address table
    push hl             ; Preserve start of address table
    dec  hl             ; Point to start address -2
    dec  hl
    ld   c, b           ; Get string number (1 to N)
.SearchStringListLoop:
    inc  hl
    inc  hl
    djnz .SearchStringListLoop
    ld   b, (hl)        ; Get address from table
    inc  hl
    ld   h, (hl)
    ld   l, b
    ld   a, c           ; Return number of this string in list
    jr   .SearchStringListExit
    ;; Failed to find target string in string list
.SearchStringListFailed:
    pop  bc             ; Restore start of target string
    xor  a              ; Return zero if failed to find string
.SearchStringListExit:
    or   a              ; Return Z flag if not found
    pop  bc             ; Restore start of address table
    ret


    ;; Utility: Find number of matching string in bit 7 delimited string list
    ;;   On entry: DE = Start of target string
    ;;             HL = Start of bit 7 delimited string list
    ;;   On exit:  If string found in list:
    ;;               A = String number in list (1 to 127) and NZ flagged
    ;;               DE = Next address after target string
    ;;               HL = Address from address list
    ;;             If string not found in list:
    ;;               A = 0 and Z flagged
    ;;               DE = Not specified
    ;;               HL = Not specified
    ;;             BC IX IY I AF' BC' DE' HL' preserved
    ;; Target string can be terminated with and control character or a space.
    ;; This version of the search function is for use where there is no
    ;; associated address table. A dummy address table is set up here such
    ;; that the main search function has somewhere harmless to pick up an
    ;; address word (which is just whatever is in memory at the time).
SearchStringListNA:
    push bc             ; Preserve start of address table
    ld   bc, SearchStringListNA ; Dummy address
    call SearchStringList
    pop  bc
    ret


    ;; Utility: Write hex prefix (eg. "0x") to current string buffer
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
WrHexPrefix:
    push af
    ld   a, '$'
    call StrWrChar      ; Write '$'
    ;;ld   a, '0'
    ;;call StrWrChar    ; Write '0'
    ;;ld   a, 'x'
    ;;call StrWrChar    ; Write 'x'
    pop  af
    ret


    ;; Utility: Disassemble instruction and write to default string
    ;;   On entry: HL = Start of instruction to be disassembled
    ;;   On exit:  HL = Address after this instruction
    ;;                  or start address + 1 if no disassembler
    ;;             BC IX IY I AF' BC' DE' HL' preserved
    ;; If the disassembler is not included the address and hex opcode bytes
    ;; are output instead.
WrInstruction:
    #ifdef IncludeDisassemble
    ;; Disassembler available so display address, opcode bytes and mnemonic
    call DisWrInstruction
    ld   a, 47          ; Column number
    call StrWrPadding   ; Pad with spaces to specified column
    #else
    ;; No disassembler so just display address and hex opcode bytes
    call StrInitDefault ; Initialise default string buffer
    ld   d, h           ; Get current address
    ld   e, l
    inc  hl             ; Prepare return address
    call StrWrHexWord   ; Display breakpoint address
    ld   a, ':'
    call StrWrChar      ; Print ':'
    ;;ld   a, (de)      ; Get op-code at PC
    ld   a, 4           ; Get length of instruction TODO
    ld   b, a
.WrInstructionZAO:
    call StrWrSpace
    ld   a, (de)        ; Read byte at PC
    call StrWrHexByte
    inc  de
    djnz .WrInstructionZAO
    ;;ld   a, '?'
    ;;call StrWrChar    ; Print '?' (no disassembly)
    ld   a, 25          ; Column number
    call StrWrPadding   ; Pad with spaces to specified column
    #endif
    ;; With or without disassembler, terminate instruction line
    ld   a, '>'
    call StrWrChar      ; Write '>' to string
    jp   StrWrSpace     ; Write space to string


    ;; Utility: Write memory dump line to default string buffer
    ;;   On entry: DE = Start location
    ;;   On exit:  DE = Next address after dump
    ;;             AF BC HL IX IY I AF' BC' DE' HL' preserved
WrMemoryDump:
    push af
    push bc
    ;; Write once line of memory dump
    ;; Write memory contents in hex
.WrMemoryDumpLine:
    push de             ; Store start address of this line
    call StrInitDefault ; Initialise default string buffer
    call StrWrAddress   ; Write address, colon, space
    ld   b, 16          ; Write 16 hex bytes...
.WrMemoryDumpHex:
    call StrWrSpace     ; Write space to string buffer
    ld   a, (de)        ; Get byte from memory
    call StrWrHexByte   ; Write hex byte to string buffer
    inc  de             ; Point to next memory location
    ld   a, e           ; Add extra space after 8 bytes...
    and  7              ; Test for byte 8
    call z, StrWrSpace  ; Tes, so write space to string
    djnz .WrMemoryDumpHex ; Repeat until all done
    pop  de             ; Get start address of this line
    call StrWrSpace     ; Write spaces
    ld   b, 16          ; Write 16 ascii characters...
    ;; Write memory contents in ASCII
.WrMemoryDumpAscii:
    ld   a, (de)        ; Get byte from memory
    call StrWrAsciiChar ; Convert to ASCII character or dot
    inc  de             ; Point to next memory location
    djnz .WrMemoryDumpAscii ; Repeat until all done
    call StrWrNewLine   ; Write new line to string buffer
    pop  bc
    pop  af
    ret


    ;; Utility: Write register values and flags to default string bufffer
    ;;   On entry: No parameters
    ;;   On exit:  IX IY I AF' BC' DE' HL' I AF' BC' DE' HL' preserved
WrRegister1:
    ld   de, sRegisters ; Register strings (line 1)
    ld   hl, iRegisters ; Register values
    ld   bc, iAF        ; Flags value
    jr   WrRegister     ; Go write registers
WrRegister2:
    ld   de, sRegister2 ; Register strings (line 2)
    ld   hl, iRegister2 ; Register values
    ld   bc, iAF2       ; Flags value
    ;; Write register details in BC, DE and HL, to string buffer
WrRegister:
    call StrInitDefault ; Initialise default string buffer
.WrRegisterName:
    ld   a, (de)        ; Get character of register name
    inc  de             ; Point to next character of name
    cp   ','            ; Character is comma?
    jr   z, .WrRegisterValue ; Yes, so go write value
    cp   '-'            ; Character is '-'?
    jr   z, .WrRegisterWriteFlag ; Yes, so go write flags
    or   a              ; Null terminator?
    jr   z, .WrRegisterWriteEOL ; Yes, so we've finished
    call StrWrChar      ; Write character of register name
    jr   .WrRegisterName ; Loop back for next character
    ;; Write register values in hex
.WrRegisterValue:
    push de
    ld   e, (hl)        ; Get lo byte of register value
    inc  hl
    ld   d, (hl)        ; Get hi byte of register value
    inc  hl
    call StrWrHexWord   ; Write register value
    pop  de
    call StrWrSpace
    jr   .WrRegisterName ; Loop back for next register
    ;; Write flags
.WrRegisterWriteFlag:
    ld   d, b           ; Get address of flags register
    ld   e, c
    ld   c, 0x80        ; Initialise flag bit mask
    ld   hl, sFlags     ; Point to flags string
.WrRegisterNextFlag:
    ld   a, (hl)        ; Get flag character
    cp   '-'            ; Flag bit used?
    jr   z, .WrRegisterZBU ; No, so skip
    ld   a, (de)        ; Get flags register
    and  c              ; Test with bit mask C
    jr   z, .WrRegisterZBT ; Flag not set, so skip
    ld   a, (hl)        ; Flag set, so get flag char
    jr   .WrRegisterZBU
.WrRegisterZBT:
    ld   a, '-'         ; Flag not set, so use '-' char
.WrRegisterZBU:
    call StrWrChar      ; Write flag character or '-'
    inc  hl             ; Prepare for next flag
    srl  c              ; Shift flag bit mask
    jr   nc, .WrRegisterNextFlag ; No carry, so loop to next bit
    ;; Write end of line
.WrRegisterWriteEOL:
    call StrWrNewLine   ; New line
    ret


    ;; **********************************************************************
    ;; **  End of Utility functions module                                 **
    ;; **********************************************************************

    #endif // IncludeUtilities
