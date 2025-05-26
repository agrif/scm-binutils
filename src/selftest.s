    ;; **********************************************************************
    ;; **  Self test at reset                        by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    ;; This module provides a self test function that runs at reset.
    ;;
    ;; The code is written to be INCLUDED in-line during the early stages
    ;; following a reset. It therefore does not end in a RET instruction.
    ;;
    ;; Initially the digital status port LEDs each flash in turn. This
    ;; will run even if there is no RAM.
    ;;
    ;; A very simple RAM test using just location 0xFFFE and 0xFFFF is then
    ;; performed. If it fails the self test repeats from the beginning, so
    ;; the LEDs keep flashing if the RAM fails.
    ;;

    ;; Must be defined in a config.h. eg:
    ;;#define kPrtOut    0           // Assume digital status port is present


    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Initialially we assume that there is no RAM so we avoid subroutines.

    ;; Flash LEDs in turn to show we get as far as running code
Selftest:
    ld   de, 1          ; Prepared for delay loop
    ld   a, e           ; First byte to write to LEDs = 0x01
.SelftestLoop1:
    out  (kPrtOut), a   ; Write to LEDs
    ld   hl, -7744      ; Set delay time (agrif: was -8000)
.SelftestDelay1:
    add  hl, de         ; Delay loop increments HL until
    jr   nc, .SelftestDelay1 ;  it reaches zero
    rlca                ; Rotate LED bit left
    jr   nc, .SelftestLoop1 ; Repeat until last LED cleared
    xor  a              ; Clear A
    out  (kPrtOut), a   ; All LEDs off

    ;; Very brief RAM test
    ld   hl, 0xffff     ; Location to be tested
    ld   a, 0x55        ; Test pattern 01010101
    ld   (hl), a        ; Store 01010101 at 0xFFFF
    dec  hl             ; HL = 0xFFFE
    cpl                 ; Invert bits to 10101010
    ld   (hl), a        ; Store 10101010 at 0xFFFE
    inc  hl             ; HL = 0xFFFF
    cpl                 ; Invert bits to 01010101
    cp   (hl)           ; Test 01010101 at 0xFFFF
    jr   nz, Selftest   ; Failed, so restart
    dec  hl             ; HL = 0xFFFE
    cpl                 ; Invert bits to 10101010
    cp   (hl)           ; Test 10101010 at 0xFFFE
    jr   nz, Selftest   ; Failed so restart
    ;; Repeat with all tests inverted
    cpl                 ; Invert bits to 01010101
    ld   (hl), a        ; Store 01010101 at 0xFFFE
    inc  hl             ; HL = 0xFFFF
    cpl                 ; Invert bits to 10101010
    ld   (hl), a        ; Store 10101010 at 0xFFFF
    dec  hl             ; HL = 0xFFFE
    cpl                 ; Invert bits to 01010101
    cp   (hl)           ; Test 01010101 at 0xFFFE
    jr   nz, Selftest   ; Failed, so restart
    inc  hl             ; HL = 0xFFFF
    cpl                 ; Invert bits to 10101010
    cp   (hl)           ; Test 10101010 at 0xFFFF
    jr   nz, Selftest   ; Failed, so restart

SelftestEnd:
    xor  a
    out  (kPrtOut), a   ; All LEDs off


    ;; **********************************************************************
    ;; **  End of Self test module                                         **
    ;; **********************************************************************
