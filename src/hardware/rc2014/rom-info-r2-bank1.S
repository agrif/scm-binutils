    ;; **********************************************************************
    ;; **  ROM info: R2-Bank1                        by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; Standard 16K ROM
    ;; Requires:
    ;;   ROM from 0x0000 to 0x3FFF   eg. Paged ROM board
    ;;   RAM from 0x4000 to 0xFFFF   eg. 64K RAM board


    .section .rominfo, "a"

    ;; Executable: BASIC.COM
    .balign 0x2000
BasicCode:
    .incbin MSBASIC_2000_4000_BIN
BasicCodeEnd:
    ;; (agrif) FIXME this should be using the symbols from msbasic
    .equ BasicCodeW, BasicCode+3 ; Warm start entry

    ;; Help extension: BASIC.HLP
BasicHelp:
    .ascii "BASIC    Grant Searle's adaptation of Microsoft BASIC\r\n"
    .asciz "WBASIC   Warm start BASIC (retains BASIC program)\r\n"
BasicHelpEnd:


    .section .romfiles, "a"

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
