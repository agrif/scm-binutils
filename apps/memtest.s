    ;; **********************************************************************
    ;; **  Memory test for RC2014 etc                by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    ;; Lower 32K memory test:
    ;; The ROM is paged out so there is RAM from 0x0000 to 0x7FFF
    ;; This RAM is then tested
    ;; If a failure is found the faulty address is stored at <result>
    ;; otherwise <result> contains 0x8000
    ;;
    ;; Upper 32K memory test:
    ;; If a failure is found the faulty address is stored at <result>
    ;; otherwise <result> contains 0x0000

    .bss
    .global Result
    .balign 0x10
Result:
    .skip 2

    .text

    ;; Test lower 32K of RAM
    .global Test
Test:
    ld   a, 1           ; So it works on LiNC80 etc
    out  (0x38), a      ; Page out ROM

    ld   hl, 0x0000     ; Start location

.LLower:
    ld   a, (hl)        ; Current contents
    ld   c, a           ; Store current contents
    cpl                 ; Invert bits
    ld   (hl), a        ; Write test pattern
    cp   (hl)           ; Read back and compare
    jr   nz, .LLoEnd    ; Abort if not the same
    ld   a, c           ; Get original contents
    ld   (hl), a        ; Restore origianl contents
    cp   (hl)           ; Read back and compare
    jr   nz, .LLoEnd    ; Abort if not the same
    inc  hl             ; Point to next location
    ld   a, h
    cp   0x80           ; Have we finished?
    jr   nz, .LLower

.LLoEnd:
    xor  a              ; So it works on LiNC80 etc
    out  (0x38), a      ; Page in ROM

    ld   (Result), hl   ; Store current address
    ld   a, h
    cp   0x80           ; Pass?
    jr   nz, .LFailed   ; No, so go report failure

    ;; Test upper 32K of RAM

    ld   hl, BeginTest  ; Start location

.LUpper:
    ld   a, (hl)        ; Current contents
    ld   c, a           ; Store current contents
    cpl                 ; Invert bits
    ld   (hl), a        ; Write test pattern
    cp   (hl)           ; Read back and compare
    jr   nz, .LHiEnd    ; Abort if not the same
    ld   a, c           ; Get original contents
    ld   (hl), a        ; Restore origianl contents
    cp   (hl)           ; Read back and compare
    jr   nz, .LHiEnd    ; Abort if not the same
    inc  hl             ; Point to next location
    ld   a, h
    cp   0x00           ; Have we finished?
    jr   nz, .LUpper

.LHiEnd:
    ld   (Result), hl   ; Store current address
    ld   a, h
    cp   0x00           ; Pass?
    jr   nz, .LFailed   ; No, so go report failure

    ld   de, .LPass     ; Pass message
    ld   c, 6           ; API 6
    rst  0x30           ;  = Output message at DE

    ld   c, 3           ; API 3
    rst  0x30           ;  = Test for input character
    jr   z, Test        ; None, so repeat test

    ld   c, 1           ; API 1
    rst  0x30           ;  = Input character (flush it)

    ld   c, 7           ; API 7
    rst  0x30           ;  = Output new line

    ret

.LFailed:
    ld   de, .LFail     ; Fail message
    ld   c, 6           ; API 6
    rst  0x30           ;  = Output message at DE
    ret

.LPass:
    .asciz "Pass "
.LFail:
    .asciz "Fail\r\n"

    ;; Upper memory test begins here
BeginTest:
