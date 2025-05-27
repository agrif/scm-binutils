    ;; **********************************************************************
    ;; **  Command Line Interpreter                  by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides the monitor's Command Line Interpreter (CLI)
    ;; including the commands themselves.
    ;;
    ;; Public functions provided:
    ;;   CLILoop               Command Line Interpreter main loop
    ;;   CLIExecute            Offer string to command line interpreter
    ;;   CLISkipNonDeli        Skip non-deliminaters in input line
    ;;   CLISkipDelim          Skip deliminaters in input line
    ;;   CLIGetHexParam        Get hex word/byte from input line

    #ifdef IncludeCommands

    ;; **********************************************************************
    ;; **  Constants                                                       **
    ;; **********************************************************************

    ;; Prompt character
    #define kPrompt    '*'          // Prompt character


    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Command Line Interpreter: Main loop
CLILoop:
    call StrInitDefault ; Initialise default string buffer
    ld   a, kPrompt     ; Get prompt character
    call OutputChar     ; Output a prompt character
    #ifdef IncludeMiniTerm
    xor  a              ; Flag command as
    ld   (iMiniTerm), a ;  not from mini terminal
    #endif
    #ifdef IncludeHexLoader
    ;; Trap colon character and input intel hex record(s)
.CLILoopPreview:
    call InputPreview   ; Preview first character in line
    cp   kColon         ; Start of Intel Hex record/line?
    jr   nz, .CLILoopNotHex ; No, so skip..
    call HexLoad        ; Load Intel Hex record
    call InputInsert    ; Insert returned character as waiting
    jr   .CLILoopPreview ; Go preview start of next line..
.CLILoopNotHex:
    #ifdef IncludeMiniTerm
    ;; WARNING this should be outside IncludeHexLoader
    cp   '-'
    jr   nz, .CLILoopNotMini
    ld   (iMiniTerm), a
    xor  a
    call InputInsert    ; Insert returned character as waiting
    jr   .CLILoopPreview ; Go preview start of next line..
.CLILoopNotMini:
    #endif
    #endif
    ;; Input line and execute it
    call InputLine      ; Input a text line
    call CLIExecute     ; Execute command line
    jr   CLILoop        ; Go get next line


    ;; Offer string to command line interpreter
    ;;  On entry:  DE = Start of command string terminated in Null
    ;;  On exit:   If command handled (blank line or executed command):
    ;;               A = 0x00 and Z flagged
    ;;             If command not handled:
    ;;               A = 0xFF and NZ flagged
    ;;             No register contents preserved
    ;; If found the command is executed before return. HL points to
    ;; start of parameter string when command code entered.
CLIExecute:
    ;;ei
.CLIExecuteLeading:
    ld   a, (de)        ; Skip leading spaces...
    cp   kSpace         ; Space character?
    jr   nz, .CLIExecuteNotSpace ; No, so continue to next char
    inc  de             ; Increment string pointer
    jr   .CLIExecuteLeading ; Go consider next character
.CLIExecuteNotSpace:
    cp   kNull          ; Blank line?
    ret  z              ; Yes, so exit with A=0x00 and Z flagged
    ;; Optionally include scripting
    #ifdef IncludeScripting
    ;; Scripting lines start with a numeric character
    call IsCharNumeric  ; Numeric character
    jr   nc, .CLIExecuteNotNum ; No, so skip..
    call CLIGetHexParam
    call ScrEdit        ; Send line to scripting editor
    jr   .CLIExecuteReturn
.CLIExecuteNotNum:
    #endif
    ;; Offer command string to system command line interpreter
    ;; DE = Start of command string
    ld   hl, CmdNameList
    ld   bc, CmdAddressList
    call SearchStringList
    ;;jr   z, .CLIExecuteError ; Not found so return error
    jr   z, .CLIExecuteNotFound ; Not found so try single letter
    ;; Execute command
    ld   bc, .CLIExecuteReturn ; Get return address
    push bc             ; Push return address onto stack
    jp   (hl)           ; Execute address from table
.CLIExecuteNotFound:
    ;; Try looking for command in ROM filing system
    #ifdef IncludeRomFS
    push de
    call RomExFile      ; Execute ROM file named at DE
    pop  de
    ret  z              ; Exit if command executed
    #endif
    ;; Try inserting space after first character in command string
    ;; to allow single letter commands to be entered without space
    ;; DE = Start of command string
    ld   h, d           ; Get start of command string..
    ld   l, e
    inc  hl             ; Skip first character in string
    ld   c, kSpace      ; Insert space
.CLIExecuteShift:
    ld   a, (hl)        ; Get current character
    ld   (hl), c        ; Write new character
    ld   c, a           ; Store previous character
    ld   a, (hl)        ; Get character just written
    inc  hl             ; Point to next character
    or   a              ; Null terminator?
    jr   nz, .CLIExecuteShift ; No, so repeat
    ld   hl, CmdNameList
    ld   bc, CmdAddressList
    call SearchStringList
    jr   z, .CLIExecuteError ; Not found so return error
    ;; Execute single letter command
    ld   bc, .CLIExecuteReturn ; Get return address
    push bc             ; Push return address onto stack
    jp   (hl)           ; Execute address from table
    ;; Return here after executing the command
.CLIExecuteReturn:
    xor  a              ; Return A = 0x00 and Z flagged
    ret
    ;; Bad command
.CLIExecuteError:
    ld   a, kMsgBadCmd  ; Message = Bad command
    call OutputMessage  ; Output message
    ld   a, 0xff        ; No match found, so return:
    or   a              ;  A = 0xFF and NZ flagged
    ret


    ;; Skip non-deliminaters in input line
    ;;   On entry: DE = Start address in input line
    ;;   On exit:  A = Character at returned address
    ;;             DE = Address of first non-delimiter character
    ;;             BC HL IX IY preserved
    ;; Delimiters are spaces or tabs (actually any control character other
    ;;   than null)
    ;; Input line must be null terminated
    ;; The return address can be that of the null terminator
CLISkipNonDeli:
.CLISkipNonDeliLoop:
    ld   a, (de)        ; Get character from input line
    or   a              ; End of line (null)?
    ret  z              ; Yes, so exit
    cp   kSpace+1       ; Character > space?
    ret  c              ; No, so exit
    inc  de             ; No, so non-delimiter
    jr   .CLISkipNonDeliLoop ;  and go try next character


    ;; Skip deliminaters in input line
    ;;   On entry: DE = Start address in input line
    ;;   On exit:  If end of line (null) found:
    ;;               A = Zero and Z flagged
    ;;               DE = Address of null character
    ;;             If non-delimiter character found:
    ;;               A = Character found and NZ flagged
    ;;               DE = Address of first non-delimiter character
    ;;             BC HL IX IY preserved
    ;; Delimiters are spaces or tabs (actually any control character other
    ;;   than null)
    ;; Input line must be null terminated
    ;; The return address can be that of the null terminator
CLISkipDelim:
.CLISkipDelimLoop:
    ld   a, (de)        ; Get character from input line
    or   a              ; End of line (null)?
    ret  z              ; Yes, so exit
    cp   kSpace+1       ; Character > space?
    ret  nc             ; Yes, so exit
    inc  de             ; No, so skip delimiter
    jr   .CLISkipDelimLoop ;  and go try next character


    ;; Get hex word/byte from input line
    ;;   On entry: A = Error reporting flags kReportXXX
    ;;             DE = Location of parameter in input line
    ;;             HL = Default value returned if no parameter found
    ;;   On exit:  If a valid hex parameter:
    ;;               A = 0x00 and Z flagged and C flagged
    ;;               DE = Location after parameter in input line
    ;;               HL = Hex byte/word from input line
    ;;               Carry flagged if no parameter found
    ;;             If no parameter if found:
    ;;               A = 0x00 and Z flagged and NC flagged
    ;;               DE = Location after parameter in input line
    ;;               HL = Hex byte/word from input line
    ;;               Carry flagged if no parameter found
    ;;               An error message is may be shown
    ;;             If an invalid hex parameter is found
    ;;               A = 0xFF and NZ flagged and NC flagged
    ;;               DE = Location after any valid characters
    ;;               HL = Unspecified
    ;;               An error message is may be shown
    ;;             BC IX IY preserved
    ;; If a non-hex character is encountered before a delimiter or null
    ;; an error is reported.
    ;; The hex conversion duplicates that in ConvertStringToNumber but we
    ;; can't use that function here for hex as it requires leading numeric
    ;; character ('0' to '9') for hex numbers:
    ;; ... this is to stop the assembler getting confused between
    ;; ... register names and constants which could be fixed by
    ;; ... re-ordering the (dis)assebmer's instruction table
CLIGetHexParam:
    push bc             ; Preserve BC
    ld   c, a           ; Store error report flags
    call CLISkipDelim   ; Skip deliminater
    or   a              ; End of line (null)? This clears carry flag
    jr   z, .CLIGetHexParamNone ; Yes, so exit as no parameter found
    call IsCharHex      ; Is first character hexadecimal ?
    jr   nc, .CLIGetHexParamOther ; No, so invalid hex character
    ld   hl, 0          ; Clear result (from supplied default)
.CLIGetHexParamLoop:
    ld   a, (de)        ; Get character from input line
    ;;or   a            ; End of line (null)? This clears carry flag
    ;;jr   z, .CLIGetHexParamNone ; Yes, so exit as ? with A = 0x00 and Z flagged
    cp   kSpace+1       ; Character > space?
    jr   c, .CLIGetHexParamFound ; No, so go end with delimiter
    call ConvertCharToUCase
    call ConvertCharToNumber
    jr   nz, .CLIGetHexParamBad ; Bad hex parameter
    sla  l              ; Rotate new nibble
    rl   h              ;  into 16 bit result...
    sla  l
    rl   h
    sla  l
    rl   h
    sla  l
    rl   h
    or   l
    ld   l, a
    inc  de
    jr   .CLIGetHexParamLoop
    ;; Try all other format not starting with hex character
.CLIGetHexParamOther:
    call ConvertStringToNumber
    jr   z, .CLIGetHexParamFound
    jr   .CLIGetHexParamBad
    ;; Valid hex parameter found
.CLIGetHexParamFound:
    pop  bc             ; Retore BC
    xor  a              ; Return with A = 0x00
    scf                 ;  and Z flagged (= no bad hex)
    ret                 ;  and C flagged (= no error)
    ;; Parameter error: no parameter found
.CLIGetHexParamNone:
    ld   a, c           ; Get error report flags
    and  kReportMis     ; Missing parameter report flag?
    call nz, .CLIGetHexParamError ; Yes, so report error
    pop  bc             ; Retore BC
    xor  a              ; Return with A = 0x00
    ;;  and Z flagged (= no bad hex)
    ret                 ;  and NC flagged (= error)
    ;; Parameter error: non-hex digit found
.CLIGetHexParamBad:
    ld   a, c           ; Get error report flags
    and  kReportBad     ; Bad parameter report flag?
    call nz, .CLIGetHexParamError ; Yes, so report error
    pop  bc             ; Retore BC
    ld   a, 0xff        ;; Return with A = 0xFF
    or   a              ;  and NZ flagged (= bad hex)
    ret                 ;  and NC flagged (= error)
    ;; Report error
    ;;push de
.CLIGetHexParamError:
    call CLIBadParam
    ;;pop  de
    inc  de
    ret


    ;; **********************************************************************
    ;; **  Private functions                                               **
    ;; **********************************************************************


    ;; Output bad parameter error message
CLIBadParam:
    push af
    ld   a, kMsgBadPar  ; Message = Bad parameter
    call OutputMessage  ; Output message
    pop  af
    ret


    ;; Returns NZ if mini-terminal mode
    #ifdef IncludeMiniTerm
IsMiniTerm:
    ld   a, (iMiniTerm) ; Get mini-terminal mode flag
    or   a              ; Return NZ in mini-terminal mode
    ret
    #else
IsMiniTerm:
    xor  a              ; Return Z as no mini-terminal mode
    ret
    #endif


    ;; **********************************************************************
    ;; **  Commands                                                        **
    ;; **********************************************************************


    ;; Command: API <fn> [<A>] [<DE>]
CmdAPI:
    ld   a, kReportAny  ; Report any error
    call CLIGetHexParam ; Get function number
    ret  nc             ; Abort if any error
    ld   c, l           ; Store function number
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam ; Get value for A register
    ;;jr   nc           ; Abort if any error
    ld   b, l           ; Store value for A register
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam ; Get value for DE registers
    ;;ret  nc           ; Abort if any error
    ex   de, hl         ; Prepare DE register value
    ld   a, b           ; Prepare A register
.CmdAPICall:
    rst  $30            ; Call API function C
    call StrWrHexByte   ; Write hex byte to string
    call StrWrSpace     ; Write space to string
    call StrWrHexWord   ; Write hex word to string
    call StrWrNewLine   ; Write new line to string
    jp   StrPrint       ; Output string


    ;; Command: Assembler: A [<start address>]
    #ifdef IncludeAssembler
CmdAssemble:
    ld   hl, (iParam1)  ; Default parameter
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam
    ret  nz             ; Abort if bad hex in parameter
    ;; Start new line. HL = Current memory location, DE = Not specified
.CmdAssembleNextLine:
    ld   (iParam1), hl  ; Update default parameter
    call WrInstruction
    call StrPrint
    ;; Input line. HL = Next memory location, DE = Not specified
    call InputLine      ; Input text line
    jr   nz, .CmdAssembleGotLine ; Skip if line is not a null string
    cp   kEscape        ; Escaped from input line?
    ret  z              ; Yes, so abort
    jr   .CmdAssembleNextLine ; No, so go to next line
    ;; Got line to process. HL = Not specified, DE = Start of line
.CmdAssembleGotLine:
    ld   hl, (iParam1)  ; Get address for this instruction
    ld   a, (de)        ; Get character from input line
    ;;or   a            ; End of line?
    ;;jr   z, .CmdAssembleNextLine ; Yes, so go to next location
    cp   '.'            ; End modify?
    ret  z              ; Yes, so exit
    ;;cp   kQuote       ; String? (quote character)
    ;;jr   z, .CmdAssembleString ; Yes...
    ;;cp   '^'          ; Back one address?
    ;;jr   z, .CmdAssembleBack ; Yes...
    ;; New assembler instruction
    call Assemble       ; Assemble string in input buffer
    jr   z, .CmdAssembleError
    ld   hl, (iParam1)
    call StrInitDefault ; Initiase default string buffer
    call DisWrInstruction ; Full disassembly to string buffer
    call StrWrNewLine
    call StrPrint       ; Print to output device
    jr   .CmdAssembleNextLine
    ;; Report error
.CmdAssembleError:
    or   a              ; Error 0 = unspecifed
    jr   nz, .CmdAssembleErrOut ; No, so skip
    ld   a, kMsgSyntax  ; Message = Syntax error
.CmdAssembleErrOut:
    call OutputMessage  ; Output message
    ld   hl, (iParam1)
    jr   .CmdAssembleNextLine
    #endif


    ;; Command: Baud rate: Baud <device> <rate-code>
    #ifdef IncludeBaud
CmdBaud:
    ld   a, kReportAny  ; Report bad or missing hex parameter
    call CLIGetHexParam
    ret  nc             ; Abort if bad hex in parameter
    ld   c, l           ; Store device number (1 to 6, or A to B)
    ld   a, kReportAny  ; Report bad or missing hex parameter
    call CLIGetHexParam
    ret  nc             ; Abort if bad hex in parameter
    ld   a, c           ; Get requested device identifier
    ld   e, l           ; Get requested baud rate code
    call SetBaud        ; Set device (A) to baud rate (E)
    jp   z, CLIBadParam ; Failed, so raise error
    ret
    #endif


    ;; Command: Breakpoint: B [<address>]
    #ifdef IncludeBreakpoint
CmdBP:
    ld   hl, (iParam1)  ; Default parameter
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam
    ret  nz             ; Abort if bad hex in parameter
    jr   c, .CmdBPSet   ; If address given then set breakpoint
    call BPReqClr       ; No address, so clear requested address
    ld   a, kMsgBPClr   ; String = Breakpoint cleared
    jr   .CmdBPResult   ; Go output message
.CmdBPSet:
    call BPReqSet       ; Attempt to set breakpoint
    ld   a, kMsgBPSet   ; String = Breakpoint set
    jr   nz, .CmdBPResult ; Skip if breakpiont set ok
    ld   a, kMsgBPFail  ; String = Breakpoint setting failed
.CmdBPResult:
    jp   OutputMessage  ; Output message A
    #endif


    ;; Command: Console <device>
CmdConsole:
    ld   a, kReportAny  ; Report bad or missing hex parameter
    call CLIGetHexParam
    ret  nc             ; Abort if bad hex in parameter
    ld   a, l           ; Get requested device number
    or   a              ; Device = 0?
    jp   z, CLIBadParam ; Yes, then error
    cp   0x0a           ; Identifier is a hex letter?
    jr   c, .CmdConsoleGotNum ; No, so skip
    sub  0x09           ; Convert 0x0A/B to 0x01/2
.CmdConsoleGotNum:
    cp   7              ; Device >= 7?
    jp   nc, CLIBadParam ; Yes, then error
    call SelConDev      ; Select console device
    ret


    ;; Command: Devices
    ;;ld   a, kMsgDevice ; ="Devices:"
CmdDevices:
    ;;call OutputMessage ; Output message
    jp   Hardware_Devices ; Output device list


    ;; Command: Directory: DIR
    #ifdef IncludeRomFS
CmdDir:
    call RomSearchInit  ; Initialise ROM file search
.CmdDirLoop:
    call RomSearchNext  ; Search for next file reference
    ret  nz             ; None found so abort
    call RomGetName     ; Get pointer to file name
    call StrPrintDE     ; Print file name
    ld   a, kPeriod     ; Get period character ('.')
    call OutputChar     ; Output character
    call RomGetType     ; Get file type
    and  0x0f           ; Remove file flags from type
    add  a, a           ; A = 2 x File type
    add  a, a           ; A = 4 x File type
    ld   l, a           ; Store as HL
    ld   h, 0
    ld   de, .CmdDirExtns ; Get start of extension strings
    add  hl, de         ; Add offset for this file type
    ex   de, hl
    call OutputZString  ; Output file extension
    call OutputNewLine  ; Output new line
    jr   .CmdDirLoop

    .section .rodata.CmdDirExtns
.CmdDirExtns:
    .db  "DAT", 0       ; Type 0 = Unspecified
    .db  "COM", 0       ; Type 1 = Monitor command
    .db  "EXE", 0       ; Type 2 = Executable
    .db  "HLP", 0       ; Type 3 = Help
    .db  "TXT", 0       ; Type 4 = Text
    .db  "???", 0       ; Type 5 = Unknown

    ;; use a subsection name to force it to come after the above .rodata
    .section .text.CmdDisassemble
    #endif


    ;; Command: Disassemble: D [<start address>]
    #ifdef IncludeDisassemble
CmdDisassemble:
CmdList:
    ld   hl, (iParam1)  ; Default parameter
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam
    ret  nz             ; Abort if bad hex in parameter
.CmdListMore:
    ld   d, 20          ; Number of instructions to list
.CmdListInstruct:
    call DisWrInstruction ; Full disassembly to string buffer
    call StrWrNewLine   ; Write new line to string buffer
    call StrPrint       ; Print to output device
    dec  d              ; Any more instruction to write?
    jr   nz, .CmdListInstruct ; Yes, so go write next one
    ld   (iParam1), hl  ; Update default parameter
    call InputMore      ; Print more?
    jr   z, .CmdListMore ; Yes, so repeat
    ret
    #endif


    ;; Command: Edit memory: E [<start address>]
CmdEdit:
    ld   hl, (iParam1)  ; Default start address
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam
    ret  nz             ; Abort if bad hex in parameter
    ;; Start new line. HL = Current memory location, DE = Not specified
.CmdEditNextLine:
    ld   (iParam1), hl  ; Store current address
    call IsMiniTerm     ; Is this command in mini-terminal mode?
    jr   nz, .CmdEditMini ; Yes, so skip
    ;; Normal terminal mode
    call WrInstruction  ; Write disassembled instruction string
    call StrPrint       ; Output disassembled instruction
    call InputLine      ; Input text line
    jr   .CmdEditInputed
    ;; Mini-terminal mode
.CmdEditMini:
    call StrInitDefault ; Initialise default string buffer
    ld   d, h           ; Get current address
    ld   e, l
    inc  hl             ; Prepare return address
    call StrWrHexWord   ; Write memory address string
    call StrWrSpace     ; Write space to string
    call StrPrint       ; Print string
    call StrInitDefault ; Initialise default string buffer
    ld   a, (de)        ; Read byte from memory
    call StrWrHexByte   ; Write hex byte to string buffer
    call InputLineEdit  ; Edit input line
    ;; Input line. HL = Next memory location, DE = Not specified
    ;;call InputLine    ; Input text line
.CmdEditInputed:
    jr   nz, .CmdEditGotLine ; Skip if line is not a null string
    cp   kEscape        ; Escaped from input line?
    ret  z              ; Yes, so abort
    jr   .CmdEditNextLine ; No, so go to next line
    ;; Got line to process. HL = Not specified, DE = Start of line
.CmdEditGotLine:
    ld   hl, (iParam1)  ; Get address for this instruction
.CmdEditNextParam:
    ld   a, (de)        ; Get character from input line
    or   a              ; End of line?
    jr   z, .CmdEditNextLine ; Yes, so go to next location
    cp   '.'            ; End modify?
    ret  z              ; Yes, so exit
    cp   kQuote         ; String? (quote character)
    jr   z, .CmdEditString ; Yes...
    cp   '^'            ; Back one address?
    jr   z, .CmdEditBack ; Yes...
    ;; New memory data is a hex value
    push hl             ; Remember current memory location
    ld   l, a           ; Set default value to current contents
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam
    ld   a, l           ; Get parameter value (lo byte only)
    pop  hl             ; Restore current location
    jr   nz, .CmdEditNextLine ; If bad hex parameter start next line
    jr   nc, .CmdEditNextLine ; If no parameter then start next line
    ld   (hl), a        ; Store new byte at current location
    inc  hl             ; Increment memory location
    ;;ld   (iParam1), hl ; Update memory location
    jr   .CmdEditNextParam
    ;; New memory data is a string
.CmdEditString:
    inc  de             ; Increment pointer to input line
    ld   a, (de)        ; Get character from input line
    or   a              ; End of string?
    jr   z, .CmdEditNextLine ; Yes, next line
    ld   (hl), a        ; Store new byte at current location
    inc  hl             ; Increment memory location
    jr   .CmdEditString
    ;; Back one location
.CmdEditBack:
    dec  hl             ; Back one memory location
    jr   .CmdEditNextLine


    ;; Command: Flag: F [<name>]
CmdFlag:
    call CLISkipDelim   ; Skip deliminater
    jr   z, .CmdFlagResults ; No flag specified so display flags
    ;; Flag name specified so set or clear flag
    ld   hl, FlagNames
    ld   bc, FlagLogic
    call SearchStringList
    jp   z, CLIBadParam ; Report error if flag name not found
    ld   a, (iAF)       ; Get flags register
    and  l              ; AND with value from list
    or   h              ; OR with value form list
    ld   (iAF), a       ; Get flags register
.CmdFlagResults:
    call WrRegister1    ; Write registers line 1 to buffer
    jp   StrPrint       ; Output registers (inc flags)


    ;; Command: Fill <start> <end> <data>
CmdFill:
    ld   a, kReportAny  ; Report any error
    call CLIGetHexParam ; Start address
    ret  nc             ; Abort if any error
    ld   (iParam1), hl  ; Store start address
    ld   a, kReportAny  ; Report any error
    call CLIGetHexParam ; End address
    ret  nc             ; Abort if any error
    ld   b, h           ; Store last address
    ld   c, l
    ld   a, kReportAny  ; Report any error
    call CLIGetHexParam ; Data byte
    ret  nc             ; Abort if any error
    ld   e, l           ; Store data byte
    ld   hl, (iParam1)  ; Get start address
    dec  hl
.CmdFillLoop:
    inc  hl             ; Point to next address to fill
    ld   (hl), e        ; Write date byte to memory
    ld   a, l           ; Lo byte of current address
    cp   c              ; Same as last address to fill?
    jr   nz, .CmdFillLoop ; No, so continue
    ld   a, h           ; Hi byte of current address
    cp   b              ; Same as last address to fill?
    jr   nz, .CmdFillLoop ; No, so continue
    ret


    ;; Command: Go: G [<start address>]
CmdGo:
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam
    ret  nz             ; Abort if bad hex in parameter
    jr   nc, .CmdGoRestore ; Skip if no address parameter
    ld   (iPC), hl      ; Store supplied address as PC
    ld   hl, kSPUsr     ; Get top of user stack
    ld   de, WarmStart  ; Get return address
    dec  hl             ;  and 'push' it onto
    ld   (hl), d        ;  user stack
    dec  hl
    ld   (hl), e
    ld   (iSP), hl      ; Store as user stack pointer
    #ifdef IncludeBreakpoint
.CmdGoRestore:
    jp   BPGo           ; Execute using stored register values
    #else
.CmdGoRestore:
    ld   hl, (iPC)      ; Get execution address
    jp   (hl)           ; Run from this address
    #endif


    ;; Command: Help: HELP or ?
    ;;#ifdef IncludeHelp
CmdHelp:
    ld   a, kMsgAbout   ; Message = about text
    call OutputMessage  ; Output message
    call OutputNewLine  ; Output new line
    ld   a, kMsgHelp    ; Message = help text
    ;;jp   OutputMessage ; Output message
    call OutputMessage  ; Output message
    ;; Look for ROM filing system help extensions
    #ifdef IncludeRomFS
    call RomSearchInit
.CmdHelpLoop:
    call RomSearchNext
    ret  nz
    call RomGetType
    cp   3
    jr   nz, .CmdHelpLoop
    call RomGetHlp
    call OutputZString
    jr   .CmdHelpLoop
    #else
    ret
    #endif
    ;;#endif


    ;; Command: Input: I <port address>
CmdIn:
    ld   a, kReportAny  ; Report any error
    call CLIGetHexParam
    ret  nc             ; Abort if any error
    ld   c, l
    in   a, (c)         ; Input from specified port
    call StrWrHexByte   ; Write hex byte to string
    call StrWrNewLine   ; Write new line to string
    jp   StrPrint       ; Output string


    ;; Command: Memory display: M [<start address>]
CmdMemory:
    ld   hl, (iParam1)  ; Default parameter
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam
    ret  nz             ; Abort if bad hex in parameter
.CmdMemoryMore:
    ld   d, h
    ld   e, l
    ld   c, 8           ; Number of lines of hex dump
.CmdMemoryLine:
    call WrMemoryDump   ; Build string of one line of dump
    call StrPrint       ; Print to output device
    dec  c              ; End of dump?
    jr   nz, .CmdMemoryLine ; No, so loop back for another line
    ld   h, d
    ld   l, e
    ld   (iParam1), hl  ; Update default parameter
    call InputMore      ; Print more?
    jr   z, .CmdMemoryMore ; Yes, so repeat
    ret


    ;; Command: New script: NEW
    #ifdef IncludeScripting
CmdNew:
    jp   ScrNew         ; Script, new command
    #endif


    ;; Command: Old script: OLD
    #ifdef IncludeScripting
CmdOld:
    jp   ScrOld         ; Script, old command
    #endif


    ;; Command: Output: O <port address> <port data>
CmdOut:
    ld   a, kReportAny  ; Report any error
    call CLIGetHexParam
    ret  nc             ; Abort if any error
    ld   c, l
    ld   a, kReportAny  ; Report any error
    call CLIGetHexParam
    ret  nc             ; Abort if any error
    ld   a, l
    out  (c), a
    ret


    ;; Command: Registers: R [<name>]
CmdRegisters:
    call CLISkipDelim   ; Skip deliminater
    jr   nz, .CmdRegistersParam ; Go handle parameter
    ;; No parameters, so just output register values
.CmdRegistersShow:
    call WrRegister1
    call StrPrint
    call WrRegister2
    jp   StrPrint
    ;; Handle parameter
.CmdRegistersParam:
    push de             ; Preserve start address of parameter
    ld   hl, RegisterNames
    ld   bc, RegisterAddresses
    call SearchStringList
    pop  de             ; Restore start address of parameter
    jp   z, CLIBadParam ; Report error if reg name not found
    ;; Edit specified register's value
    call StrInitDefault ; Initialise default string buffer
    ld   c, 0           ; Length of register name
.CmdRegistersNextChar:
    ld   a, (de)        ; Get character of register name
    cp   kSpace-1       ; End of register name?
    jr   c, .CmdRegistersColon ; Yes, so write colon
    call ConvertCharToUCase
    call StrWrChar      ; Write character to string buffer
    inc  c              ; Count characters in name
    inc  de             ; Increment to next char of name
    jr   .CmdRegistersNextChar ;  and go get next character
.CmdRegistersColon:
    ld   a, ':'         ; Get colon character
    call StrWrChar      ; Write colon to string buffer
    call StrWrSpace     ; Write space to string buffer
    ld   e, (hl)        ; Get register contents
    inc  hl
    ld   d, (hl)
    dec  hl
    ld   a, c           ; Length of register name
    cp   1              ; One character long?
    jr   nz, .CmdRegistersWord
    ld   a, e           ; Get lo byte
    call StrWrHexByte   ; Write hex byte value of register
    jr   .CmdRegistersSpace
.CmdRegistersWord:
    call StrWrHexWord   ; Write hex word value of register
.CmdRegistersSpace:
    ld   a, 2
    call StrWrSpaces    ; Write 2 spaces to string buffer
    call StrPrint       ; Print current string ot output device
    ;; Input line. HL = Memory location of register
    call InputLine      ; Input text line
    ret  z              ; No input, so we're done
    ;; Extract new register value from input buffer
    push hl             ; Preserve memory location
    ld   a, kReportAny  ; Report any error
    call CLIGetHexParam
    ld   e, l           ; Get hex value input
    ld   d, h
    pop  hl             ; Restore memory location
    ret  nc             ; If any error then we're done
    ld   (hl), e        ; Store lo byte at register location
    ld   a, c           ; Length of register name
    cp   1              ; One character long?
    ret  z              ; Yes, so we're done
    inc  hl             ; Increment memory location
    ld   (hl), d        ; Store hi byte at register location
    ret


    ;; Command: Reset: RESET
    .equ CmdReset, ColdStart ; Command reset = Cold start system
    di                  ; Disable interrupts
    jp   ColdStart      ; Run as if hardware reset


    ;; Command: Script list: SCRIPT
    #ifdef IncludeScripting
CmdScript:
    jp   ScrList
    #endif


    ;; Command: Step: S [<start address>]
    #ifdef IncludeDisassemble
CmdStep:
    ld   a, kReportBad  ; Only report bad hex parameter
    call CLIGetHexParam
    ret  nz             ; Abort if bad hex in parameter
    jr   nc, .CmdStepRestore ; Skip if no address parameter
    ld   (iPC), hl      ; Store supplied address as PC
    ld   hl, kSPUsr     ; Get top of user stack
    ld   de, WarmStart  ; Get return address
    dec  hl             ;  and 'push' it onto
    ld   (hl), d        ;  user stack
    dec  hl
    ld   (hl), e
    ld   (iSP), hl      ; Store as user stack pointer
.CmdStepRestore:
    jp   BPStep         ; Execute using stored register values
    #endif


    ;; Trap optional features that have not been included in this build
    #ifndef IncludeAssembler
CmdAssemble:
    #endif
    #ifndef IncludeBaud
CmdBaud:
    #endif
    #ifndef IncludeBreakpoint
CmdBP:
    #endif
    #ifndef IncludeDisassemble
CmdDisassemble:
CmdStep:
CmdList:
    #endif
    #ifndef IncludeRomFS
CmdDir:
    #endif
    #ifndef IncludeScripting
CmdNew:
CmdOld:
CmdScript:
    #endif
    #ifndef IncludeHelp
CmdHelp:
    #endif
    ld   a, kMsgNotAv   ; Message = Feature no included
    jp   OutputMessage  ; Output message


    ;; **********************************************************************
    ;; **  Constant data                                                   **
    ;; **********************************************************************

    .section .rodata

    ;; Command summary
    ;; Char/Cmd,  Description     ? Other possible commands
    ;;  :         Download intel hex record
    ;;  ?         Help
    ;;  A         Assemble        ?
    ;;  B         Breakpoint      ?
    ;;  C                         ? Compare, Copy, CPM
    ;;  CONSOLE   Console select  ?
    ;;  D         Disassemble     ? Dump, Display
    ;;  DEVICES   Device list     ?
    ;;  DIR       Directory list  ?
    ;;  E         Edit memory     ? Execute
    ;;  F         Flags           ?
    ;;  FILL      Fill memory     ?
    ;;  G         Go              ?
    ;;  H                         ?
    ;;  HELP      Help            ?
    ;;  I         Input from port ?
    ;;  J                         ? Jump
    ;;  K                         ?
    ;;  L                         ? Load, List
    ;;  M         Memory          ? Modify, Move
    ;;  N                         ? Next, New
    ;;  NEW       New script      ?
    ;;  O         Output to port  ? Old
    ;;  OLD       Old srcipt      ?
    ;;  P                         ?
    ;;  Q                         ?
    ;;  R         Registers       ?
    ;;  RESET     Reset           ?
    ;;  ROM       Directory list  ?
    ;;  S         Step            ? Save, Script
    ;;  SCRIPT    Script          ?
    ;;  T                         ? Transfer
    ;;  U                         ?
    ;;  V                         ? Verify
    ;;  W                         ?
    ;;  X                         ?
    ;;  Y                         ?
    ;;  Z                         ?

    ;; Command summary for mini-terminal
    ;;  B         Breakpoint
    ;;  E         Edit memory     (mini version -E)
    ;;  F         Flags           (mini version needed)
    ;;  G         Go
    ;;  I         Input from port (mini version needed)
    ;;  O         Output to port
    ;;  R         Registers       (mini version needed)
    ;; Problems to sort: Console, Fill (if it is worth it)

    ;; Command name list
    ;; If list search allows abbreviations then the first match will
    ;; be accepted
CmdNameList:
    ;; Single character commands
    .db  128+'?'        ; ?        Help
    .db  128+'A'        ; A        Assemble
    .db  128+'B'        ; B        Breakpoint
    .db  128+'D'        ; D        Disassemble
    .db  128+'E'        ; E        Edit memory
    .db  128+'F'        ; F        Flag
    .db  128+'G'        ; G        Go
    .db  128+'I'        ; I        Input from port
    .db  128+'M'        ; M        Memory display
    .db  128+'O'        ; O        Output to port
    .db  128+'R'        ; R        Registers
    .db  128+'S'        ; S        Step
    ;; Full word commands
    .db  128+'A', "PI"  ; API      API call
    .db  128+'B', "AUD" ; BAUD     Set baud rate
    .db  128+'C', "ONSOLE" ; CONSOLE  Set console device
    .db  128+'D', "EVICES" ; DEVICES  Devices list
    .db  128+'D', "IR"  ; DIR      Directory
    .db  128+'F', "ILL" ; FILL     Fill memory
    .db  128+'H', "ELP" ; HELP     Help
    .db  128+'R', "ESET" ; RESET    Reset
    .db  128+'R', "OM"  ; ROM      Directory
    ;; Optional commands
    #ifdef IncludeScripting
    .db  128+'N', "EW"  ; NEW      New (for script)
    .db  128+'O', "LD"  ; OLD      Old (for script)
    .db  128+'S', "CRIPT" ; SCRIPT  Script (list program)
    #endif
    .db  128            ; List terminator

    ;; Command address list
CmdAddressList:
    ;; Single character commands
    .dw  CmdHelp        ; ?        Help
    .dw  CmdAssemble    ; A        Assemble
    .dw  CmdBP          ; B        Breakpoint
    .dw  CmdDisassemble ; D        Disassemble
    .dw  CmdEdit        ; E        Edit memory
    .dw  CmdFlag        ; F        Flag
    .dw  CmdGo          ; G        Go
    .dw  CmdIn          ; I        In
    .dw  CmdMemory      ; M        Memory display
    .dw  CmdOut         ; O        Out
    .dw  CmdRegisters   ; R        Registers
    .dw  CmdStep        ; S        Step
    ;; Full word commands
    .dw  CmdAPI         ; API      API call
    .dw  CmdBaud        ; BAUD     Set baud rate
    .dw  CmdConsole     ; CONSOLE  Set console device
    .dw  CmdDevices     ; DEVICES  Devices list
    .dw  CmdDir         ; DIR      Directory
    .dw  CmdFill        ; FILL     Fill memory
    .dw  CmdHelp        ; HELP     Help
    .dw  CmdReset       ; RESET    Reset
    .dw  CmdDir         ; ROM      Directory
    ;; Optional commands
    #ifdef IncludeScripting
    .dw  CmdNew         ; NEW      New
    .dw  CmdOld         ; OLD      Old
    .dw  CmdScript      ; SCRIPT   Script
    #endif


    ;; Register name list (bit 7 delimited)
RegisterNames:
    .db  128+'P', 'C'   ; PC
    .db  128+'S', 'P'   ; SP
    .db  128+'(', ")"   ; ()
    .db  128+'(', "SP)" ; (SP)
    .db  128+'A', 'F'   ; AF
    .db  128+'B', 'C'   ; BC
    .db  128+'D', 'E'   ; DE
    .db  128+'H', 'L'   ; HL
    .db  128+'I', 'X'   ; IX
    .db  128+'I', 'Y'   ; IY
    .db  128+'A', "F'"  ; AF'
    .db  128+'B', "C'"  ; BC'
    .db  128+'D', "E'"  ; DE'
    .db  128+'H', "L'"  ; HL'
    .db  128+'A'        ; A
    .db  128+'F'        ; F
    .db  128+'B'        ; B
    .db  128+'C'        ; C
    .db  128+'D'        ; D
    .db  128+'E'        ; E
    .db  128+'H'        ; H
    .db  128+'L'        ; L
    .db  128+'I'        ; I
    .db  128            ; List terminator
    ;; Register address list
RegisterAddresses:
    .dw  iPC            ; PC
    .dw  iSP            ; SP
    .dw  iCSP           ; ()
    .dw  iCSP           ; (SP)
    .dw  iAF            ; AF
    .dw  iBC            ; BC
    .dw  iDE            ; DE
    .dw  iHL            ; HL
    .dw  iIX            ; IX
    .dw  iIY            ; IY
    .dw  iAF2           ; AF'
    .dw  iBC2           ; BC'
    .dw  iDE2           ; DE'
    .dw  iHL2           ; HL'
    .dw  iAF+1          ; A
    .dw  iAF            ; F
    .dw  iBC+1          ; B
    .dw  iBC            ; C
    .dw  iDE+1          ; D
    .dw  iDE            ; E
    .dw  iHL+1          ; H
    .dw  iHL            ; L
    .dw  iIR+1          ; H


    ;; Flag names list (bit 7 delimited)
FlagNames:
    .db  128+'S'        ; S    Bit 7, Flag S set to 1 (negative/minus)
    .db  128+'N', 'S'   ; NS   Bit 7, Flag S cleared to 0 (positive)
    .db  128+'M'        ; M    Bit 7, Flag S set to 1 (negative/minus)
    .db  128+'P'        ; P    Bit 7, Flag S cleared to 0 (positive)
    .db  128+'Z'        ; Z    Bit 6, Flag Z set to 1 (zero)
    .db  128+'N', 'Z'   ; NZ   Bit 6, Flag Z cleared to 0 (not zero)
    .db  128+'H'        ; H    Bit 4, Flag H set to 1 (half carry)
    .db  128+'N', 'H'   ; NH   4it 4, Flag H cleared to 0 (not half carry)
    .db  128+'P', 'A'   ; Pa   Bit 2, Flag P/V set to 1 (even parity or overflow)
    .db  128+'N', 'P'   ; NP   Bit 2, Flag P/V set to 0 (odd parity or no overflow)
    .db  128+'P', 'E'   ; PE   Bit 2, Flag P/V set to 1 (even parity or overflow)
    .db  128+'P', 'O'   ; Po   Bit 2, Flag P/V set to 0 (odd parity or no overflow)
    .db  128+'N'        ; N    Bit 1, Flag N set to 1 (subtract)
    .db  128+'N', 'N'   ; NN   Bit 1, Flag N cleared to 0 (add)
    .db  128+'C'        ; C    Bit 0, Flag C set to 1 (carry)
    .db  128+'N', 'C'   ; NC   Bit 0, Flag C cleared to 0 (not carry)
    .db  128            ; List terminator
    ;; Flag manipulation list
    ;; Lo byte is ANDed with flags register, then Hi byte is ORed with
    ;;   flags register
    ;; Yes, we could drive this from one byte but we are using the existing
    ;; list handlers which need words, so might as well specify both
    ;; AND and OR values!
FlagLogic:
    .db  0x7f, 0x80     ; S    Bit 7, Flag S set to 1 (negative/minus)
    .db  0x7f, 0x00     ; NS   Bit 7, Flag S cleared to 0 (positive)
    .db  0x7f, 0x80     ; M    Bit 7, Flag S set to 1 (negative/minus)
    .db  0x7f, 0x00     ; P    Bit 7, Flag S cleared to 0 (positive)
    .db  0xbf, 0x40     ; Z    Bit 6, Flag Z set to 1 (zero)
    .db  0xbf, 0x00     ; NZ   Bit 6, Flag Z cleared to 0 (not zero)
    .db  0xef, 0x10     ; H    Bit 4, Flag H set to 1 (half carry)
    .db  0xef, 0x00     ; NH   4it 4, Flag H cleared to 0 (not half carry)
    .db  0xfb, 0x04     ; Pa   Bit 2, Flag P/V set to 1 (even parity or overflow)
    .db  0xfb, 0x00     ; NP   Bit 2, Flag P/V set to 0 (odd parity or no overflow)
    .db  0xfb, 0x04     ; PE   Bit 2, Flag P/V set to 1 (even parity or overflow)
    .db  0xfb, 0x00     ; Po   Bit 2, Flag P/V set to 0 (odd parity or no overflow)
    .db  0xfd, 0x02     ; N    Bit 1, Flag N set to 1 (subtract)
    .db  0xfd, 0x00     ; NN   Bit 1, Flag N cleared to 0 (add)
    .db  0xfe, 0x01     ; C    Bit 0, Flag C set to 1 (carry)
    .db  0xfe, 0x00     ; NC   Bit 0, Flag C cleared to 0 (not carry)


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iParam1:
    .dw  0              ; CLI parameter 1

    #ifdef IncludeMiniTerm
iMiniTerm:
    .db  0              ; Mini terminal flag
    #endif


    ;; **********************************************************************
    ;; **  End of Command Line Interpreter                                 **
    ;; **********************************************************************

    #endif // IncludeCommands
