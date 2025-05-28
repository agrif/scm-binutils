    ;; **********************************************************************
    ;; **  ROM info: Monitor's own info              by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    .section .romfiles.monitor, "a"
    .dw  0xaa55         ; Identifier
    .db  "Monitor "     ; File name ("Monitor.EXE")
    .db  2              ; File type 2 = Executable from ROM
    .db  0              ; Not used
    .dw  0x0000         ; Start address
    .dw  EndOfMonitor-StartOfMonitor ; Length

    ;; **********************************************************************
    ;; **  End of ROM information module                                   **
    ;; **********************************************************************
