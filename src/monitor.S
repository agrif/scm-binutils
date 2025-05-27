    ;; **********************************************************************
    ;; **  Monitor essentials                        by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module provides the following:
    ;;   Defines monitor's global workspace / variables
    ;;   Defines monitor's constant message data
    ;;   Function to output monitor messages
    ;;
    ;; Public functions provided:
    ;;   MonOutputMsg          Output monitor messages

    #ifdef IncludeMonitor

    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Monitor: Output message
    ;;  On entry:  A = Message number (1 to n)
    ;;   On exit:  If message output by monitor A = 0
    ;;             otherwise A = Message number
    ;;             BC IX IY I AF' BC' DE' HL' preserved
MonOutputMsg:
    ;; Monitor message?
    cp   kMsgMonFst     ; Valid system message number?
    ret  c              ; No, so abort
    cp   kMsgMonLst+1   ; Valid system message number?
    ret  nc             ; No, so abort
    sub  kMsgMonFst     ; Adjust message number to 0 to n
    ld   e, a           ; Get message number
    ld   d, 0
    ld   hl, MsgTabMon  ; Get start of message table
    add  hl, de         ; Calculate location in table
    add  hl, de
    ld   a, (hl)        ; Get address from table...
    inc  hl
    ld   d, (hl)
    ld   e, a
    call OutputZString  ; Output message as DE
    xor  a              ; Flag message output by monitor
    ret

    ;; **********************************************************************
    ;; **  Constant data                                                   **
    ;; **********************************************************************

    .section .rodata

    ;; Register and flag strings
    ;; Terminate register name strings with '-' (for flags) or a null
    ;; These strings must match the order the registers are stored in RAM
sRegisters:
    .db  "PC:,AF:,BC:,DE:,HL:,IX:,IY:,Flags:-"
sRegister2:
    .db  "SP:,AF',BC',DE',HL',(S),IR:,Flags'-"
sFlags:
    .db  "SZ-H-PNC"


    ;; Message strings (zero terminated)
szBadCmd:
    .db  "Bad command", kNewLine, kNull
szBadParam:
    .db  "Bad parameter", kNewLine, kNull
szAsmError:
    .db  "Syntax error", kNewLine, kNull
szBPSet:
    .db  "Breakpoint set", kNewLine, kNull
szBPClear:
    .db  "Breakpoint cleared", kNewLine, kNull
szBPFail:
    .db  "Unable to set breakpoint here", kNewLine, kNull
szNotAvail:
    .db  "Feature not included", kNewLine, kNull
szReady:
    .db  "Ready", kNewLine, kNull
szFileErr:
    .db  "File error", kNewLine, kNull

szCmdHelp:
    #ifdef IncludeHelp
    .db  "Monitor commands:", kNewLine
;;; Single character cmds   20        30        40        50        60        70        80
;;;       12345678901234567890123456789012345678901234567890123456789012345678901234567890
    .db  "A [<address>]  = Assemble        |  D [<address>]   = Disassemble", kNewLine
    .db  "M [<address>]  = Memory display  |  E [<address>]   = Edit memory", kNewLine
    .db  "R [<name>]     = Registers/edit  |  F [<name>]      = Flags/edit", kNewLine
    .db  "B [<address>]  = Breakpoint      |  S [<address>]   = Single step", kNewLine
    .db  "I <port>       = Input from port |  O <port> <data> = Output to port", kNewLine
    .db  "G [<address>]  = Go to program", kNewLine
    ;; Full word commands
    .db  "BAUD <device> <rate>             |  CONSOLE <device>", kNewLine
    .db  "FILL <start> <end> <byte>        |  API <function> [<A>] [<DE>]", kNewLine
    .db  "DEVICES, DIR, HELP, RESET", kNewLine
    ;; Optional commands
    #ifdef IncludeScripting
    .db  "Scripting commands:", kNewLine
    .db  "RUN, SCRIPT (list), OLD, NEW", kNewLine
    #endif
    ;;.db  kNewLine
    #endif
    .db  kNull


    ;; Message table
MsgTabMon:
    .dw  szBadCmd
    .dw  szBadParam
    .dw  szAsmError
    .dw  szBPSet
    .dw  szBPClear
    .dw  szBPFail
    .dw  szCmdHelp
    .dw  szNotAvail
    .dw  szReady
    .dw  szFileErr

    ;; **********************************************************************
    ;; **  Global workspace                                                **
    ;; **********************************************************************

    .bss

iRegisters:
    ;; Order is hard coded so do not change (see strings above)
iPC:
    .dw  0              ; Register pair PC (Program Counter)
iAF:
    .dw  0              ; Register pair AF
iBC:
    .dw  0              ; Register pair BC
iDE:
    .dw  0              ; Register pair DE
iHL:
    .dw  0              ; Register pair HL
iIX:
    .dw  0              ; Register pair IX
iIY:
    .dw  0              ; Register pair IY

iRegister2:
    ;; Order is hard coded so do not change (see strings above)
iSP:
    .dw  0              ; Register pair SP (Stack Pointer)
iAF2:
    .dw  0              ; Register pair AF'
iBC2:
    .dw  0              ; Register pair BC'
iDE2:
    .dw  0              ; Register pair DE'
iHL2:
    .dw  0              ; Register pair HL'
iCSP:
    .dw  0              ; Register pair (SP)
iIR:
    .dw  0              ; Register pair IR


    ;; **********************************************************************
    ;; **  End of Monitor essentials                                       **
    ;; **********************************************************************

    #endif // IncludeMonitor
