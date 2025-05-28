    ;; **********************************************************************
    ;; **  ROM info: R3-Bank1                        by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; Standard 32K ROM
    ;; Requires:
    ;;   ROM from 0x0000 to 0x7FFF   eg. Paged ROM board
    ;;   RAM from 0x8000 to 0xFFFF   eg. 64K RAM board
    ;;        and 0x0000 to 0xFFFF when ROM paged out


    .section .rominfo, "a"

    ;; Executable: BASIC.COM
    .balign 0x2000
BasicCode:
    .incbin MSBASIC_2000_8000_BIN
BasicCodeEnd:
    ;; (agrif) FIXME this should be using the symbols from msbasic
    .equ BasicCodeW, BasicCode+3 ; Warm start entry

    ;; Executable: CPM.COM
CPMCode:
    .incbin CPM_LOADER_BIN
CPMCodeEnd:

    ;; Help extension: BASIC.HLP
BasicHelp:
    .ascii "BASIC    Grant Searle's adaptation of Microsoft BASIC\r\n"
    .asciz "WBASIC   Warm start BASIC (retains BASIC program)\r\n"
BasicHelpEnd:

    ;; Help extension: CPM.HLP
CPMHelp:
    .asciz "CPM      Load CP/M from Compact Flash (requires prepared CF card)\r\n"
    ;;.asciz "CPM      Load CP/M from Compact Flash\r\n"
CPMHelpEnd:


    .section .romfiles, "a"

    .dw  0xaa55         ; Identifier
    .db  "CPM     "     ; File name ("CPM.HLP")
    .db  0x03           ; File type 3 = Help
    .db  0              ; Not used
    .dw  CPMHelp        ; Start address
    .dw  CPMHelpEnd-CPMHelp ; Length

    .dw  0xaa55         ; Identifier
    .db  "CPM     "     ; File name ("CPM.COM")
    .db  0x41           ; File type 1 = Monitor command, moved to RAM
    .db  0x80           ; Run in RAM at 0x8000
    .dw  CPMCode        ; Start address
    .dw  CPMCodeEnd-CPMCode ; Length

    .dw  0xaa55         ; Identifier
    .db  "BASIC   "     ; File name ("BASIC.HLP")
    .db  0x03           ; File type 3 = Help
    .db  0              ; Not used
    .dw  BasicHelp      ; Start address
    .dw  BasicHelpEnd-BasicHelp ; Length

    .dw  0xaa55         ; Identifier
    .db  "WBASIC  "     ; File name ("WBASIC.COM")
    .db  0x01           ; File type 1 = Monitor command
    .db  0              ; Not used
    .dw  BasicCodeW     ; Start address
    .dw  BasicCodeEnd-BasicCodeW ; Length

    .dw  0xaa55         ; Identifier
    .db  "BASIC   "     ; File name ("BASIC.COM")
    .db  0x01           ; File type 1 = Monitor command
    .db  0              ; Not used
    .dw  BasicCode      ; Start address
    .dw  BasicCodeEnd-BasicCode ; Length

    #include "monitor-info.inc.s"
    ;; Include Monitor.EXE information at top of bank 1. eg:
    ;; .section .romfiles.monitor, "a"
    ;; .dw  0xaa55         ; Identifier
    ;; .db  "Monitor "     ; File name ("Monitor.EXE")
    ;; .db  2              ; File type 2 = Executable from ROM
    ;; .db  0              ; Not used
    ;; .dw  0x0000         ; Start address
    ;; .dw  EndOfMonitor-StartOfMonitor ; Length

    ;; **********************************************************************
    ;; **  End of ROM information module                                   **
    ;; **********************************************************************
