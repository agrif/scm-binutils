    ;; **********************************************************************
    ;; **  ROM info: R1-Bank1                        by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; Standard 8K ROM suitable for all RC2014 systems
    ;; Requires:
    ;;   ROM from 0x0000 to 0x1FFF
    ;;   RAM from 0x8000 to 0xFFFF


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
