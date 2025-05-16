    ;; **********************************************************************
    ;; **  Memory fill for RC2014 etc                by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    ;; The program fills all 64k RAM except the few bytes used by this code.

Test:
    ld   c, 0x55        ; Byte to fill memory with

    ld   a, 1           ; So it works on LiNC80 etc
    out  (0x38), a      ; Page out ROM

    ;; Fill lower 32K of RAM
    ld   hl, 0x0000     ; Start location
.LLower:
    ld   (hl), c        ; Write fill byte to RAM
    inc  hl             ; Point to next location
    ld   a, h
    cp   0x80           ; Have we finished?
    jr   nz, .LLower

    xor  a              ; So it works on LiNC80 etc
    out  (0x38), a      ; Page in ROM

    ;; Fill upper 32K of RAM
    ld   hl, BeginTest  ; Start location
.LUpper:
    ld   (hl), c        ; Write fill byte to RAM
    inc  hl             ; Point to next location
    ld   a, h
    cp   0x00           ; Have we finished?
    jr   nz, .LUpper

    jp   0x0000         ; Reset system

    ;; Upper memory fill begins here
BeginTest:
