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

    .BSS
    .GLOBAL Result
    .BALIGN 0x10
Result: .DW 0

    .TEXT

    ;; Test lower 32K of RAM
    .GLOBAL Test
Test:
    LD   A,1            ;So it works on LiNC80 etc
    OUT  (0x38),A       ;Page out ROM

    LD   HL,0x0000      ;Start location

.LLower:
    LD   A,(HL)         ;Current contents
    LD   C,A            ;Store current contents
    CPL                 ;Invert bits
    LD   (HL),A         ;Write test pattern
    CP   (HL)           ;Read back and compare
    JR   NZ,.LLoEnd     ;Abort if not the same
    LD   A,C            ;Get original contents
    LD   (HL),A         ;Restore origianl contents
    CP   (HL)           ;Read back and compare
    JR   NZ,.LLoEnd     ;Abort if not the same
    INC  HL             ;Point to next location
    LD   A,H
    CP   0x80           ;Have we finished?
    JR   NZ,.LLower

.LLoEnd:
    XOR  A              ;So it works on LiNC80 etc
    OUT  (0x38),A       ;Page in ROM

    LD   (Result),HL    ;Store current address
    LD   A,H
    CP   0x80           ;Pass?
    JR   NZ,.LFailed    ;No, so go report failure

    ;; Test upper 32K of RAM

    LD   HL,BeginTest   ;Start location

.LUpper:
    LD   A,(HL)         ;Current contents
    LD   C,A            ;Store current contents
    CPL                 ;Invert bits
    LD   (HL),A         ;Write test pattern
    CP   (HL)           ;Read back and compare
    JR   NZ,.LHiEnd     ;Abort if not the same
    LD   A,C            ;Get original contents
    LD   (HL),A         ;Restore origianl contents
    CP   (HL)           ;Read back and compare
    JR   NZ,.LHiEnd     ;Abort if not the same
    INC  HL             ;Point to next location
    LD   A,H
    CP   0x00           ;Have we finished?
    JR   NZ,.LUpper

.LHiEnd:
    LD   (Result),HL    ;Store current address
    LD   A,H
    CP   0x00           ;Pass?
    JR   NZ,.LFailed    ;No, so go report failure

    LD   DE,.LPass      ;Pass message
    LD   C,6            ;API 6
    RST  0x30           ;  = Output message at DE

    LD   C,3            ;API 3
    RST  0x30           ;  = Test for input character
    JR   Z,Test         ;None, so repeat test

    LD   C,1            ;API 1
    RST  0x30           ;  = Input character (flush it)

    LD   C,7            ;API 7
    RST  0x30           ;  = Output new line

    RET

.LFailed:
    LD   DE,.LFail      ;Fail message
    LD   C,6            ;API 6
    RST  0x30           ;  = Output message at DE
    RET

.LPass: .ASCIZ "Pass "
.LFail: .ASCIZ "Fail\r\n"

BeginTest:  ; Upper memory test begins here
