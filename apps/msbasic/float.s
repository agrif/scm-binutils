    ;; see msbasic.h for more info

.ROUND:
    ld   hl, .HALF      ; Add 0.5 to FPREG
ADDPHL:
    call LOADFP         ; Load FP at (HL) to BCDE
    jp   .FPADD         ; Add BCDE to FPREG

.SUBPHL:
    call LOADFP         ; FPREG = -FPREG + number at HL
    .db  0x21           ; Skip "POP BC" and "POP DE"
PSUB:
    pop  bc             ; Get FP number from stack
    pop  de
.SUBCDE:
    call INVSGN         ; Negate FPREG
.FPADD:
    ld   a, b           ; Get FP exponent
    or   a              ; Is number zero?
    ret  z              ; Yes - Nothing to add
    ld   a, (FPEXP)     ; Get FPREG exponent
    or   a              ; Is this number zero?
    jp   z, FPBCDE      ; Yes - Move BCDE to FPREG
    sub  b              ; BCDE number larger?
    jp   nc, .NOSWAP    ; No - Don't swap them
    cpl                 ; Two's complement
    inc  a              ;  FP exponent
    ex   de, hl
    call STAKFP         ; Put FPREG on stack
    ex   de, hl
    call FPBCDE         ; Move BCDE to FPREG
    pop  bc             ; Restore number from stack
    pop  de
.NOSWAP:
    cp   24+1           ; Second number insignificant?
    ret  nc             ; Yes - First number is result
    push af             ; Save number of bits to scale
    call .SIGNS         ; Set MSBs & sign of result
    ld   h, a           ; Save sign of result
    pop  af             ; Restore scaling factor
    call .SCALE         ; Scale BCDE to same exponent
    or   h              ; Result to be positive?
    ld   hl, FPREG      ; Point to FPREG
    jp   p, .MINCDE     ; No - Subtract FPREG from CDE
    call .PLUCDE        ; Add FPREG to CDE
    jp   nc, .RONDUP    ; No overflow - Round it up
    inc  hl             ; Point to exponent
    inc  (hl)           ; Increment it
    jp   z, OVERR       ; Number overflowed - Error
    ld   l, 1           ; 1 bit to shift right
    call .SHRT1         ; Shift result right
    jp   .RONDUP        ; Round it up

.MINCDE:
    xor  a              ; Clear A and carry
    sub  b              ; Negate exponent
    ld   b, a           ; Re-save exponent
    ld   a, (hl)        ; Get LSB of FPREG
    sbc  a, e           ; Subtract LSB of BCDE
    ld   e, a           ; Save LSB of BCDE
    inc  hl
    ld   a, (hl)        ; Get NMSB of FPREG
    sbc  a, d           ; Subtract NMSB of BCDE
    ld   d, a           ; Save NMSB of BCDE
    inc  hl
    ld   a, (hl)        ; Get MSB of FPREG
    sbc  a, c           ; Subtract MSB of BCDE
    ld   c, a           ; Save MSB of BCDE
.CONPOS:
    call c, .COMPL      ; Overflow - Make it positive

.BNORM:
    ld   l, b           ; L = Exponent
    ld   h, e           ; H = LSB
    xor  a
.BNRMLP:
    ld   b, a           ; Save bit count
    ld   a, c           ; Get MSB
    or   a              ; Is it zero?
    jp   nz, .PNORM     ; No - Do it bit at a time
    ld   c, d           ; MSB = NMSB
    ld   d, h           ; NMSB= LSB
    ld   h, l           ; LSB = VLSB
    ld   l, a           ; VLSB= 0
    ld   a, b           ; Get exponent
    sub  8              ; Count 8 bits
    cp   0xe0           ; Was number zero?   <SCC> was -24-8
    jp   nz, .BNRMLP    ; No - Keep normalising
RESZER:
    xor  a              ; Result is zero
.SAVEXP:
    ld   (FPEXP), a     ; Save result as zero
    ret

.NORMAL:
    dec  b              ; Count bits
    add  hl, hl         ; Shift HL left
    ld   a, d           ; Get NMSB
    rla                 ; Shift left with last bit
    ld   d, a           ; Save NMSB
    ld   a, c           ; Get MSB
    adc  a, a           ; Shift left with last bit
    ld   c, a           ; Save MSB
.PNORM:
    jp   p, .NORMAL     ; Not done - Keep going
    ld   a, b           ; Number of bits shifted
    ld   e, h           ; Save HL in EB
    ld   b, l
    or   a              ; Any shifting done?
    jp   z, .RONDUP     ; No - Round it up
    ld   hl, FPEXP      ; Point to exponent
    add  a, (hl)        ; Add shifted bits
    ld   (hl), a        ; Re-save exponent
    jp   nc, RESZER     ; Underflow - Result is zero
    ret  z              ; Result is zero
.RONDUP:
    ld   a, b           ; Get VLSB of number
.RONDB:
    ld   hl, FPEXP      ; Point to exponent
    or   a              ; Any rounding?
    call m, .FPROND     ; Yes - Round number up
    ld   b, (hl)        ; B = Exponent
    inc  hl
    ld   a, (hl)        ; Get sign of result
    and  10000000B      ; Only bit 7 needed
    xor  c              ; Set correct sign
    ld   c, a           ; Save correct sign in number
    jp   FPBCDE         ; Move BCDE to FPREG

.FPROND:
    inc  e              ; Round LSB
    ret  nz             ; Return if ok
    inc  d              ; Round NMSB
    ret  nz             ; Return if ok
    inc  c              ; Round MSB
    ret  nz             ; Return if ok
    ld   c, 0x80        ; Set normal value
    inc  (hl)           ; Increment exponent
    ret  nz             ; Return if ok
    jp   OVERR          ; Overflow error

.PLUCDE:
    ld   a, (hl)        ; Get LSB of FPREG
    add  a, e           ; Add LSB of BCDE
    ld   e, a           ; Save LSB of BCDE
    inc  hl
    ld   a, (hl)        ; Get NMSB of FPREG
    adc  a, d           ; Add NMSB of BCDE
    ld   d, a           ; Save NMSB of BCDE
    inc  hl
    ld   a, (hl)        ; Get MSB of FPREG
    adc  a, c           ; Add MSB of BCDE
    ld   c, a           ; Save MSB of BCDE
    ret

.COMPL:
    ld   hl, SGNRES     ; Sign of result
    ld   a, (hl)        ; Get sign of result
    cpl                 ; Negate it
    ld   (hl), a        ; Put it back
    xor  a
    ld   l, a           ; Set L to zero
    sub  b              ; Negate exponent,set carry
    ld   b, a           ; Re-save exponent
    ld   a, l           ; Load zero
    sbc  a, e           ; Negate LSB
    ld   e, a           ; Re-save LSB
    ld   a, l           ; Load zero
    sbc  a, d           ; Negate NMSB
    ld   d, a           ; Re-save NMSB
    ld   a, l           ; Load zero
    sbc  a, c           ; Negate MSB
    ld   c, a           ; Re-save MSB
    ret

.SCALE:
    ld   b, 0           ; Clear underflow
.SCALLP:
    sub  8              ; 8 bits (a whole byte)?
    jp   c, .SHRITE     ; No - Shift right A bits
    ld   b, e           ; <- Shift
    ld   e, d           ; <- right
    ld   d, c           ; <- eight
    ld   c, 0           ; <- bits
    jp   .SCALLP        ; More bits to shift

.SHRITE:
    add  a, 8+1         ; Adjust count
    ld   l, a           ; Save bits to shift
.SHRLP:
    xor  a              ; Flag for all done
    dec  l              ; All shifting done?
    ret  z              ; Yes - Return
    ld   a, c           ; Get MSB
.SHRT1:
    rra                 ; Shift it right
    ld   c, a           ; Re-save
    ld   a, d           ; Get NMSB
    rra                 ; Shift right with last bit
    ld   d, a           ; Re-save it
    ld   a, e           ; Get LSB
    rra                 ; Shift right with last bit
    ld   e, a           ; Re-save it
    ld   a, b           ; Get underflow
    rra                 ; Shift right with last bit
    ld   b, a           ; Re-save underflow
    jp   .SHRLP         ; More bits to do

    .section .rodata.unity

.UNITY:
    .db  0x00, 0x00, 0x00, 0x81 ; 1.00000

.LOGTAB:
    .db  3              ; Table used by LOG
    .db  0xaa, 0x56, 0x19, 0x80 ; 0.59898
    .db  0xf1, 0x22, 0x76, 0x80 ; 0.96147
    .db  0x45, 0xaa, 0x38, 0x82 ; 2.88539

    ;; make sure this comes after the above .rodata
    .section .text.log

LOG:
    call TSTSGN         ; Test sign of value
    or   a
    jp   pe, FCERR      ; ?FC Error if <= zero
    ld   hl, FPEXP      ; Point to exponent
    ld   a, (hl)        ; Get exponent
    ld   bc, 0x8035     ; BCDE = SQR(1/2)
    ld   de, 0x4f3
    sub  b              ; Scale value to be < 1
    push af             ; Save scale factor
    ld   (hl), b        ; Save new exponent
    push de             ; Save SQR(1/2)
    push bc
    call .FPADD         ; Add SQR(1/2) to value
    pop  bc             ; Restore SQR(1/2)
    pop  de
    inc  b              ; Make it SQR(2)
    call .DVBCDE        ; Divide by SQR(2)
    ld   hl, .UNITY     ; Point to 1.
    call .SUBPHL        ; Subtract FPREG from 1
    ld   hl, .LOGTAB    ; Coefficient table
    call .SUMSER        ; Evaluate sum of series
    ld   bc, 0x8080     ; BCDE = -0.5
    ld   de, 0x0000
    call .FPADD         ; Subtract 0.5 from FPREG
    pop  af             ; Restore scale factor
    call .RSCALE        ; Re-scale number
.MULLN2:
    ld   bc, 0x8031     ; BCDE = Ln(2)
    ld   de, 0x7218
    .db  0x21           ; Skip "POP BC" and "POP DE"

MULT:
    pop  bc             ; Get number from stack
    pop  de
.FPMULT:
    call TSTSGN         ; Test sign of FPREG
    ret  z              ; Return zero if zero
    ld   l, 0           ; Flag add exponents
    call .ADDEXP        ; Add exponents
    ld   a, c           ; Get MSB of multiplier
    ld   (MULVAL), a    ; Save MSB of multiplier
    ex   de, hl
    ld   (MULVAL+1), hl ; Save rest of multiplier
    ld   bc, 0          ; Partial product (BCDE) = zero
    ld   d, b
    ld   e, b
    ld   hl, .BNORM     ; Address of normalise
    push hl             ; Save for return
    ld   hl, .MULT8     ; Address of 8 bit multiply
    push hl             ; Save for NMSB,MSB
    push hl             ;
    ld   hl, FPREG      ; Point to number
.MULT8:
    ld   a, (hl)        ; Get LSB of number
    inc  hl             ; Point to NMSB
    or   a              ; Test LSB
    jp   z, .BYTSFT     ; Zero - shift to next byte
    push hl             ; Save address of number
    ld   l, 8           ; 8 bits to multiply by
.MUL8LP:
    rra                 ; Shift LSB right
    ld   h, a           ; Save LSB
    ld   a, c           ; Get MSB
    jp   nc, .NOMADD    ; Bit was zero - Don't add
    push hl             ; Save LSB and count
    ld   hl, (MULVAL+1) ; Get LSB and NMSB
    add  hl, de         ; Add NMSB and LSB
    ex   de, hl         ; Leave sum in DE
    pop  hl             ; Restore MSB and count
    ld   a, (MULVAL)    ; Get MSB of multiplier
    adc  a, c           ; Add MSB
.NOMADD:
    rra                 ; Shift MSB right
    ld   c, a           ; Re-save MSB
    ld   a, d           ; Get NMSB
    rra                 ; Shift NMSB right
    ld   d, a           ; Re-save NMSB
    ld   a, e           ; Get LSB
    rra                 ; Shift LSB right
    ld   e, a           ; Re-save LSB
    ld   a, b           ; Get VLSB
    rra                 ; Shift VLSB right
    ld   b, a           ; Re-save VLSB
    dec  l              ; Count bits multiplied
    ld   a, h           ; Get LSB of multiplier
    jp   nz, .MUL8LP    ; More - Do it
POPHRT:
    pop  hl             ; Restore address of number
    ret

.BYTSFT:
    ld   b, e           ; Shift partial product left
    ld   e, d
    ld   d, c
    ld   c, a
    ret

.DIV10:
    call STAKFP         ; Save FPREG on stack
    ld   bc, 0x8420     ; BCDE = 10.
    ld   de, 0x0000
    call FPBCDE         ; Move 10 to FPREG

DIV:
    pop  bc             ; Get number from stack
    pop  de
.DVBCDE:
    call TSTSGN         ; Test sign of FPREG
    jp   z, DZERR       ; Error if division by zero
    ld   l, -1          ; Flag subtract exponents
    call .ADDEXP        ; Subtract exponents
    inc  (hl)           ; Add 2 to exponent to adjust
    inc  (hl)
    dec  hl             ; Point to MSB
    ld   a, (hl)        ; Get MSB of dividend
    ld   (DIV3), a      ; Save for subtraction
    dec  hl
    ld   a, (hl)        ; Get NMSB of dividend
    ld   (DIV2), a      ; Save for subtraction
    dec  hl
    ld   a, (hl)        ; Get MSB of dividend
    ld   (DIV1), a      ; Save for subtraction
    ld   b, c           ; Get MSB
    ex   de, hl         ; NMSB,LSB to HL
    xor  a
    ld   c, a           ; Clear MSB of quotient
    ld   d, a           ; Clear NMSB of quotient
    ld   e, a           ; Clear LSB of quotient
    ld   (DIV4), a      ; Clear overflow count
.DIVLP:
    push hl             ; Save divisor
    push bc
    ld   a, l           ; Get LSB of number
    call DIVSUP         ; Subt' divisor from dividend
    sbc  a, 0           ; Count for overflows
    ccf
    jp   nc, .RESDIV    ; Restore divisor if borrow
    ld   (DIV4), a      ; Re-save overflow count
    pop  af             ; Scrap divisor
    pop  af
    scf                 ; Set carry to
    .db  0xd2           ; Skip "POP BC" and "POP HL"

.RESDIV:
    pop  bc             ; Restore divisor
    pop  hl
    ld   a, c           ; Get MSB of quotient
    inc  a
    dec  a
    rra                 ; Bit 0 to bit 7
    jp   m, .RONDB      ; Done - Normalise result
    rla                 ; Restore carry
    ld   a, e           ; Get LSB of quotient
    rla                 ; Double it
    ld   e, a           ; Put it back
    ld   a, d           ; Get NMSB of quotient
    rla                 ; Double it
    ld   d, a           ; Put it back
    ld   a, c           ; Get MSB of quotient
    rla                 ; Double it
    ld   c, a           ; Put it back
    add  hl, hl         ; Double NMSB,LSB of divisor
    ld   a, b           ; Get MSB of divisor
    rla                 ; Double it
    ld   b, a           ; Put it back
    ld   a, (DIV4)      ; Get VLSB of quotient
    rla                 ; Double it
    ld   (DIV4), a      ; Put it back
    ld   a, c           ; Get MSB of quotient
    or   d              ; Merge NMSB
    or   e              ; Merge LSB
    jp   nz, .DIVLP     ; Not done - Keep dividing
    push hl             ; Save divisor
    ld   hl, FPEXP      ; Point to exponent
    dec  (hl)           ; Divide by 2
    pop  hl             ; Restore divisor
    jp   nz, .DIVLP     ; Ok - Keep going
    jp   OVERR          ; Overflow error

.ADDEXP:
    ld   a, b           ; Get exponent of dividend
    or   a              ; Test it
    jp   z, .OVTST3     ; Zero - Result zero
    ld   a, l           ; Get add/subtract flag
    ld   hl, FPEXP      ; Point to exponent
    xor  (hl)           ; Add or subtract it
    add  a, b           ; Add the other exponent
    ld   b, a           ; Save new exponent
    rra                 ; Test exponent for overflow
    xor  b
    ld   a, b           ; Get exponent
    jp   p, .OVTST2     ; Positive - Test for overflow
    add  a, 0x80        ; Add excess 128
    ld   (hl), a        ; Save new exponent
    jp   z, POPHRT      ; Zero - Result zero
    call .SIGNS         ; Set MSBs and sign of result
    ld   (hl), a        ; Save new exponent
    dec  hl             ; Point to MSB
    ret

.OVTST1:
    call TSTSGN         ; Test sign of FPREG
    cpl                 ; Invert sign
    pop  hl             ; Clean up stack
.OVTST2:
    or   a              ; Test if new exponent zero
.OVTST3:
    pop  hl             ; Clear off return address
    jp   p, RESZER      ; Result zero
    jp   OVERR          ; Overflow error

.MLSP10:
    call BCDEFP         ; Move FPREG to BCDE
    ld   a, b           ; Get exponent
    or   a              ; Is it zero?
    ret  z              ; Yes - Result is zero
    add  a, 2           ; Multiply by 4
    jp   c, OVERR       ; Overflow - ?OV Error
    ld   b, a           ; Re-save exponent
    call .FPADD         ; Add BCDE to FPREG (Times 5)
    ld   hl, FPEXP      ; Point to exponent
    inc  (hl)           ; Double number (Times 10)
    ret  nz             ; Ok - Return
    jp   OVERR          ; Overflow error

TSTSGN:
    ld   a, (FPEXP)     ; Get sign of FPREG
    or   a
    ret  z              ; RETurn if number is zero
    ld   a, (FPREG+2)   ; Get MSB of FPREG
    .db  0xfe           ; Test sign
.RETREL:
    cpl                 ; Invert sign
    rla                 ; Sign bit to carry
FLGDIF:
    sbc  a, a           ; Carry to all bits of A
    ret  nz             ; Return -1 if negative
    inc  a              ; Bump to +1
    ret                 ; Positive - Return +1

SGN:
    call TSTSGN         ; Test sign of FPREG
FLGREL:
    ld   b, 0x80+8      ; 8 bit integer in exponent
    ld   de, 0          ; Zero NMSB and LSB
RETINT:
    ld   hl, FPEXP      ; Point to exponent
    ld   c, a           ; CDE = MSB,NMSB and LSB
    ld   (hl), b        ; Save exponent
    ld   b, 0           ; CDE = integer to normalise
    inc  hl             ; Point to sign of result
    ld   (hl), 0x80     ; Set sign of result
    rla                 ; Carry = sign of integer
    jp   .CONPOS        ; Set sign of result

ABS:
    call TSTSGN         ; Test sign of FPREG
    ret  p              ; Return if positive
INVSGN:
    ld   hl, FPREG+2    ; Point to MSB
    ld   a, (hl)        ; Get sign of mantissa
    xor  0x80           ; Invert sign of mantissa
    ld   (hl), a        ; Re-save sign of mantissa
    ret

STAKFP:
    ex   de, hl         ; Save code string address
    ld   hl, (FPREG)    ; LSB,NLSB of FPREG
    ex   (sp), hl       ; Stack them,get return
    push hl             ; Re-save return
    ld   hl, (FPREG+2)  ; MSB and exponent of FPREG
    ex   (sp), hl       ; Stack them,get return
    push hl             ; Re-save return
    ex   de, hl         ; Restore code string address
    ret

PHLTFP:
    call LOADFP         ; Number at HL to BCDE
FPBCDE:
    ex   de, hl         ; Save code string address
    ld   (FPREG), hl    ; Save LSB,NLSB of number
    ld   h, b           ; Exponent of number
    ld   l, c           ; MSB of number
    ld   (FPREG+2), hl  ; Save MSB and exponent
    ex   de, hl         ; Restore code string address
    ret

BCDEFP:
    ld   hl, FPREG      ; Point to FPREG
LOADFP:
    ld   e, (hl)        ; Get LSB of number
    inc  hl
    ld   d, (hl)        ; Get NMSB of number
    inc  hl
    ld   c, (hl)        ; Get MSB of number
    inc  hl
    ld   b, (hl)        ; Get exponent of number
.INCHL:
    inc  hl             ; Used for conditional "INC HL"
    ret

FPTHL:
    ld   de, FPREG      ; Point to FPREG
DETHL4:
    ld   b, 4           ; 4 bytes to move
.DETHLB:
    ld   a, (de)        ; Get source
    ld   (hl), a        ; Save destination
    inc  de             ; Next source
    inc  hl             ; Next destination
    dec  b              ; Count bytes
    jp   nz, .DETHLB    ; Loop if more
    ret

.SIGNS:
    ld   hl, FPREG+2    ; Point to MSB of FPREG
    ld   a, (hl)        ; Get MSB
    rlca                ; Old sign to carry
    scf                 ; Set MSBit
    rra                 ; Set MSBit of MSB
    ld   (hl), a        ; Save new MSB
    ccf                 ; Complement sign
    rra                 ; Old sign to carry
    inc  hl
    inc  hl
    ld   (hl), a        ; Set sign of result
    ld   a, c           ; Get MSB
    rlca                ; Old sign to carry
    scf                 ; Set MSBit
    rra                 ; Set MSBit of MSB
    ld   c, a           ; Save MSB
    rra
    xor  (hl)           ; New sign of result
    ret

CMPNUM:
    ld   a, b           ; Get exponent of number
    or   a
    jp   z, TSTSGN      ; Zero - Test sign of FPREG
    ld   hl, .RETREL    ; Return relation routine
    push hl             ; Save for return
    call TSTSGN         ; Test sign of FPREG
    ld   a, c           ; Get MSB of number
    ret  z              ; FPREG zero - Number's MSB
    ld   hl, FPREG+2    ; MSB of FPREG
    xor  (hl)           ; Combine signs
    ld   a, c           ; Get MSB of number
    ret  m              ; Exit if signs different
    call .CMPFP         ; Compare FP numbers
    rra                 ; Get carry to sign
    xor  c              ; Combine with MSB of number
    ret

.CMPFP:
    inc  hl             ; Point to exponent
    ld   a, b           ; Get exponent
    cp   (hl)           ; Compare exponents
    ret  nz             ; Different
    dec  hl             ; Point to MBS
    ld   a, c           ; Get MSB
    cp   (hl)           ; Compare MSBs
    ret  nz             ; Different
    dec  hl             ; Point to NMSB
    ld   a, d           ; Get NMSB
    cp   (hl)           ; Compare NMSBs
    ret  nz             ; Different
    dec  hl             ; Point to LSB
    ld   a, e           ; Get LSB
    sub  (hl)           ; Compare LSBs
    ret  nz             ; Different
    pop  hl             ; Drop RETurn
    pop  hl             ; Drop another RETurn
    ret

FPINT:
    ld   b, a           ; <- Move
    ld   c, a           ; <- exponent
    ld   d, a           ; <- to all
    ld   e, a           ; <- bits
    or   a              ; Test exponent
    ret  z              ; Zero - Return zero
    push hl             ; Save pointer to number
    call BCDEFP         ; Move FPREG to BCDE
    call .SIGNS         ; Set MSBs & sign of result
    xor  (hl)           ; Combine with sign of FPREG
    ld   h, a           ; Save combined signs
    call m, .DCBCDE     ; Negative - Decrement BCDE
    ld   a, 0x80+24     ; 24 bits
    sub  b              ; Bits to shift
    call .SCALE         ; Shift BCDE
    ld   a, h           ; Get combined sign
    rla                 ; Sign to carry
    call c, .FPROND     ; Negative - Round number up
    ld   b, 0           ; Zero exponent
    call c, .COMPL      ; If negative make positive
    pop  hl             ; Restore pointer to number
    ret

.DCBCDE:
    dec  de             ; Decrement BCDE
    ld   a, d           ; Test LSBs
    and  e
    inc  a
    ret  nz             ; Exit if LSBs not FFFF
    dec  bc             ; Decrement MSBs
    ret

INT:
    ld   hl, FPEXP      ; Point to exponent
    ld   a, (hl)        ; Get exponent
    cp   0x80+24        ; Integer accuracy only?
    ld   a, (FPREG)     ; Get LSB
    ret  nc             ; Yes - Already integer
    ld   a, (hl)        ; Get exponent
    call FPINT          ; F.P to integer
    ld   (hl), 0x80+24  ; Save 24 bit integer
    ld   a, e           ; Get LSB of number
    push af             ; Save LSB
    ld   a, c           ; Get MSB of number
    rla                 ; Sign to carry
    call .CONPOS        ; Set sign of result
    pop  af             ; Restore LSB of number
    ret

MLDEBC:
    ld   hl, 0          ; Clear partial product
    ld   a, b           ; Test multiplier
    or   c
    ret  z              ; Return zero if zero
    ld   a, 16          ; 16 bits
.MLDBLP:
    add  hl, hl         ; Shift P.P left
    jp   c, BSERR       ; ?BS Error if overflow
    ex   de, hl
    add  hl, hl         ; Shift multiplier left
    ex   de, hl
    jp   nc, .NOMLAD    ; Bit was zero - No add
    add  hl, bc         ; Add multiplicand
    jp   c, BSERR       ; ?BS Error if overflow
.NOMLAD:
    dec  a              ; Count bits
    jp   nz, .MLDBLP    ; More
    ret

ASCTFP:
    cp   '-'            ; Negative?
    push af             ; Save it and flags
    jp   z, .CNVNUM     ; Yes - Convert number
    cp   '+'            ; Positive?
    jp   z, .CNVNUM     ; Yes - Convert number
    dec  hl             ; DEC 'cos GETCHR INCs
.CNVNUM:
    call RESZER         ; Set result to zero
    ld   b, a           ; Digits after point counter
    ld   d, a           ; Sign of exponent
    ld   e, a           ; Exponent of ten
    cpl
    ld   c, a           ; Before or after point flag
.MANLP:
    call GETCHR         ; Get next character
    jp   c, .ADDIG      ; Digit - Add to number
    cp   '.'
    jp   z, .DPOINT     ; '.' - Flag point
    cp   'E'
    jp   nz, .CONEXP    ; Not 'E' - Scale number
    call GETCHR         ; Get next character
    call SGNEXP         ; Get sign of exponent
.EXPLP:
    call GETCHR         ; Get next character
    jp   c, .EDIGIT     ; Digit - Add to exponent
    inc  d              ; Is sign negative?
    jp   nz, .CONEXP    ; No - Scale number
    xor  a
    sub  e              ; Negate exponent
    ld   e, a           ; And re-save it
    inc  c              ; Flag end of number
.DPOINT:
    inc  c              ; Flag point passed
    jp   z, .MANLP      ; Zero - Get another digit
.CONEXP:
    push hl             ; Save code string address
    ld   a, e           ; Get exponent
    sub  b              ; Subtract digits after point
.SCALMI:
    call p, .SCALPL     ; Positive - Multiply number
    jp   p, .ENDCON     ; Positive - All done
    push af             ; Save number of times to /10
    call .DIV10         ; Divide by 10
    pop  af             ; Restore count
    inc  a              ; Count divides

.ENDCON:
    jp   nz, .SCALMI    ; More to do
    pop  de             ; Restore code string address
    pop  af             ; Restore sign of number
    call z, INVSGN      ; Negative - Negate number
    ex   de, hl         ; Code string address to HL
    ret

.SCALPL:
    ret  z              ; Exit if no scaling needed
.MULTEN:
    push af             ; Save count
    call .MLSP10        ; Multiply number by 10
    pop  af             ; Restore count
    dec  a              ; Count multiplies
    ret

.ADDIG:
    push de             ; Save sign of exponent
    ld   d, a           ; Save digit
    ld   a, b           ; Get digits after point
    adc  a, c           ; Add one if after point
    ld   b, a           ; Re-save counter
    push bc             ; Save point flags
    push hl             ; Save code string address
    push de             ; Save digit
    call .MLSP10        ; Multiply number by 10
    pop  af             ; Restore digit
    sub  '0'            ; Make it absolute
    call .RSCALE        ; Re-scale number
    pop  hl             ; Restore code string address
    pop  bc             ; Restore point flags
    pop  de             ; Restore sign of exponent
    jp   .MANLP         ; Get another digit

.RSCALE:
    call STAKFP         ; Put number on stack
    call FLGREL         ; Digit to add to FPREG
PADD:
    pop  bc             ; Restore number
    pop  de
    jp   .FPADD         ; Add BCDE to FPREG and return

.EDIGIT:
    ld   a, e           ; Get digit
    rlca                ; Times 2
    rlca                ; Times 4
    add  a, e           ; Times 5
    rlca                ; Times 10
    add  a, (hl)        ; Add next digit
    sub  '0'            ; Make it absolute
    ld   e, a           ; Save new digit
    jp   .EXPLP         ; Look for another digit

LINEIN:
    push hl             ; Save code string address
    ld   hl, INMSG      ; Output " in "
    call PRS            ; Output string at HL
    pop  hl             ; Restore code string address
PRNTHL:
    ex   de, hl         ; Code string address to DE
    xor  a
    ld   b, 0x80+24     ; 24 bits
    call RETINT         ; Return the integer
    ld   hl, PRNUMS     ; Print number string
    push hl             ; Save for return
NUMASC:
    ld   hl, PBUFF      ; Convert number to ASCII
    push hl             ; Save for return
    call TSTSGN         ; Test sign of FPREG
    ld   (hl), ' '      ; Space at start
    jp   p, .SPCFST     ; Positive - Space to start
    ld   (hl), '-'      ; '-' sign at start
.SPCFST:
    inc  hl             ; First byte of number
    ld   (hl), '0'      ; '0' if zero
    jp   z, .JSTZER     ; Return '0' if zero
    push hl             ; Save buffer address
    call m, INVSGN      ; Negate FPREG if negative
    xor  a              ; Zero A
    push af             ; Save it
    call .RNGTST        ; Test number is in range
.SIXDIG:
    ld   bc, 0x9143     ; BCDE - 99999.9
    ld   de, 0x4ff8
    call CMPNUM         ; Compare numbers
    or   a
    jp   po, .INRNG     ; > 99999.9 - Sort it out
    pop  af             ; Restore count
    call .MULTEN        ; Multiply by ten
    push af             ; Re-save count
    jp   .SIXDIG        ; Test it again

.GTSIXD:
    call .DIV10         ; Divide by 10
    pop  af             ; Get count
    inc  a              ; Count divides
    push af             ; Re-save count
    call .RNGTST        ; Test number is in range
.INRNG:
    call .ROUND         ; Add 0.5 to FPREG
    inc  a
    call FPINT          ; F.P to integer
    call FPBCDE         ; Move BCDE to FPREG
    ld   bc, 0x0306     ; 1E+06 to 1E-03 range
    pop  af             ; Restore count
    add  a, c           ; 6 digits before point
    inc  a              ; Add one
    jp   m, .MAKNUM     ; Do it in 'E' form if < 1E-02
    cp   6+1+1          ; More than 999999 ?
    jp   nc, .MAKNUM    ; Yes - Do it in 'E' form
    inc  a              ; Adjust for exponent
    ld   b, a           ; Exponent of number
    ld   a, 2           ; Make it zero after

.MAKNUM:
    dec  a              ; Adjust for digits to do
    dec  a
    pop  hl             ; Restore buffer address
    push af             ; Save count
    ld   de, .POWERS    ; Powers of ten
    dec  b              ; Count digits before point
    jp   nz, .DIGTXT    ; Not zero - Do number
    ld   (hl), '.'      ; Save point
    inc  hl             ; Move on
    ld   (hl), '0'      ; Save zero
    inc  hl             ; Move on
.DIGTXT:
    dec  b              ; Count digits before point
    ld   (hl), '.'      ; Save point in case
    call z, .INCHL      ; Last digit - move on
    push bc             ; Save digits before point
    push hl             ; Save buffer address
    push de             ; Save powers of ten
    call BCDEFP         ; Move FPREG to BCDE
    pop  hl             ; Powers of ten table
    ld   b, '0'-1       ; ASCII '0' - 1
.TRYAGN:
    inc  b              ; Count subtractions
    ld   a, e           ; Get LSB
    sub  (hl)           ; Subtract LSB
    ld   e, a           ; Save LSB
    inc  hl
    ld   a, d           ; Get NMSB
    sbc  a, (hl)        ; Subtract NMSB
    ld   d, a           ; Save NMSB
    inc  hl
    ld   a, c           ; Get MSB
    sbc  a, (hl)        ; Subtract MSB
    ld   c, a           ; Save MSB
    dec  hl             ; Point back to start
    dec  hl
    jp   nc, .TRYAGN    ; No overflow - Try again
    call .PLUCDE        ; Restore number
    inc  hl             ; Start of next number
    call FPBCDE         ; Move BCDE to FPREG
    ex   de, hl         ; Save point in table
    pop  hl             ; Restore buffer address
    ld   (hl), b        ; Save digit in buffer
    inc  hl             ; And move on
    pop  bc             ; Restore digit count
    dec  c              ; Count digits
    jp   nz, .DIGTXT    ; More - Do them
    dec  b              ; Any decimal part?
    jp   z, .DOEBIT     ; No - Do 'E' bit
.SUPTLZ:
    dec  hl             ; Move back through buffer
    ld   a, (hl)        ; Get character
    cp   '0'            ; '0' character?
    jp   z, .SUPTLZ     ; Yes - Look back for more
    cp   '.'            ; A decimal point?
    call nz, .INCHL     ; Move back over digit

.DOEBIT:
    pop  af             ; Get 'E' flag
    jp   z, .NOENED     ; No 'E' needed - End buffer
    ld   (hl), 'E'      ; Put 'E' in buffer
    inc  hl             ; And move on
    ld   (hl), '+'      ; Put '+' in buffer
    jp   p, .OUTEXP     ; Positive - Output exponent
    ld   (hl), '-'      ; Put '-' in buffer
    cpl                 ; Negate exponent
    inc  a
.OUTEXP:
    ld   b, '0'-1       ; ASCII '0' - 1
.EXPTEN:
    inc  b              ; Count subtractions
    sub  10             ; Tens digit
    jp   nc, .EXPTEN    ; More to do
    add  a, '0'+10      ; Restore and make ASCII
    inc  hl             ; Move on
    ld   (hl), b        ; Save MSB of exponent
.JSTZER:
    inc  hl             ;
    ld   (hl), a        ; Save LSB of exponent
    inc  hl
.NOENED:
    ld   (hl), c        ; Mark end of buffer
    pop  hl             ; Restore code string address
    ret

.RNGTST:
    ld   bc, 0x9474     ; BCDE = 999999.
    ld   de, 0x23f7
    call CMPNUM         ; Compare numbers
    or   a
    pop  hl             ; Return address to HL
    jp   po, .GTSIXD    ; Too big - Divide by ten
    jp   (hl)           ; Otherwise return to caller

    .section .rodata.half

.HALF:
    .db  0x00, 0x00, 0x00, 0x80 ; 0.5

.POWERS:
    .db  0xa0, 0x86, 0x01 ; 100000
    .db  0x10, 0x27, 0x00 ;  10000
    .db  0xe8, 0x03, 0x00 ;   1000
    .db  0x64, 0x00, 0x00 ;    100
    .db  0x0a, 0x00, 0x00 ;     10
    .db  0x01, 0x00, 0x00 ;      1

    ;; make sure this comes after the above .rodata
    .section .text.negaft

.NEGAFT:
    ld   hl, INVSGN     ; Negate result
    ex   (sp), hl       ; To be done after caller
    jp   (hl)           ; Return to caller

SQR:
    call STAKFP         ; Put value on stack
    ld   hl, .HALF      ; Set power to 1/2
    call PHLTFP         ; Move 1/2 to FPREG

POWER:
    pop  bc             ; Get base
    pop  de
    call TSTSGN         ; Test sign of power
    ld   a, b           ; Get exponent of base
    jp   z, EXP         ; Make result 1 if zero
    jp   p, .POWER1     ; Positive base - Ok
    or   a              ; Zero to negative power?
    jp   z, DZERR       ; Yes - ?/0 Error
.POWER1:
    or   a              ; Base zero?
    jp   z, .SAVEXP     ; Yes - Return zero
    push de             ; Save base
    push bc
    ld   a, c           ; Get MSB of base
    or   01111111B      ; Get sign status
    call BCDEFP         ; Move power to BCDE
    jp   p, .POWER2     ; Positive base - Ok
    push de             ; Save power
    push bc
    call INT            ; Get integer of power
    pop  bc             ; Restore power
    pop  de
    push af             ; MSB of base
    call CMPNUM         ; Power an integer?
    pop  hl             ; Restore MSB of base
    ld   a, h           ; but don't affect flags
    rra                 ; Exponent odd or even?
.POWER2:
    pop  hl             ; Restore MSB and exponent
    ld   (FPREG+2), hl  ; Save base in FPREG
    pop  hl             ; LSBs of base
    ld   (FPREG), hl    ; Save in FPREG
    call c, .NEGAFT     ; Odd power - Negate result
    call z, INVSGN      ; Negative base - Negate it
    push de             ; Save power
    push bc
    call LOG            ; Get LOG of base
    pop  bc             ; Restore power
    pop  de
    call .FPMULT        ; Multiply LOG by power

EXP:
    call STAKFP         ; Put value on stack
    ld   bc, 0x8138     ; BCDE = 1/Ln(2)
    ld   de, 0xaa3b
    call .FPMULT        ; Multiply value by 1/LN(2)
    ld   a, (FPEXP)     ; Get exponent
    cp   0x80+8         ; Is it in range?
    jp   nc, .OVTST1    ; No - Test for overflow
    call INT            ; Get INT of FPREG
    add  a, 0x80        ; For excess 128
    add  a, 2           ; Exponent > 126?
    jp   c, .OVTST1     ; Yes - Test for overflow
    push af             ; Save scaling factor
    ld   hl, .UNITY     ; Point to 1.
    call ADDPHL         ; Add 1 to FPREG
    call .MULLN2        ; Multiply by LN(2)
    pop  af             ; Restore scaling factor
    pop  bc             ; Restore exponent
    pop  de
    push af             ; Save scaling factor
    call .SUBCDE        ; Subtract exponent from FPREG
    call INVSGN         ; Negate result
    ld   hl, .EXPTAB    ; Coefficient table
    call .SMSER1        ; Sum the series
    ld   de, 0          ; Zero LSBs
    pop  bc             ; Scaling factor
    ld   c, d           ; Zero MSB
    jp   .FPMULT        ; Scale result to correct value

    .section .rodata.exptab

.EXPTAB:
    .db  8              ; Table used by EXP
    .db  0x40, 0x2e, 0x94, 0x74 ; -1/7! (-1/5040)
    .db  0x70, 0x4f, 0x2e, 0x77 ;  1/6! ( 1/720)
    .db  0x6e, 0x02, 0x88, 0x7a ; -1/5! (-1/120)
    .db  0xe6, 0xa0, 0x2a, 0x7c ;  1/4! ( 1/24)
    .db  0x50, 0xaa, 0xaa, 0x7e ; -1/3! (-1/6)
    .db  0xff, 0xff, 0x7f, 0x7f ;  1/2! ( 1/2)
    .db  0x00, 0x00, 0x80, 0x81 ; -1/1! (-1/1)
    .db  0x00, 0x00, 0x00, 0x81 ;  1/0! ( 1/1)

    ;; make sure this comes after the above .rodata
    .section .text.sumser

.SUMSER:
    call STAKFP         ; Put FPREG on stack
    ld   de, MULT       ; Multiply by "X"
    push de             ; To be done after
    push hl             ; Save address of table
    call BCDEFP         ; Move FPREG to BCDE
    call .FPMULT        ; Square the value
    pop  hl             ; Restore address of table
.SMSER1:
    call STAKFP         ; Put value on stack
    ld   a, (hl)        ; Get number of coefficients
    inc  hl             ; Point to start of table
    call PHLTFP         ; Move coefficient to FPREG
    .db  0x06           ; Skip "POP AF"
.SUMLP:
    pop  af             ; Restore count
    pop  bc             ; Restore number
    pop  de
    dec  a              ; Cont coefficients
    ret  z              ; All done
    push de             ; Save number
    push bc
    push af             ; Save count
    push hl             ; Save address in table
    call .FPMULT        ; Multiply FPREG by BCDE
    pop  hl             ; Restore address in table
    call LOADFP         ; Number at HL to BCDE
    push hl             ; Save address in table
    call .FPADD         ; Add coefficient to FPREG
    pop  hl             ; Restore address in table
    jp   .SUMLP         ; More coefficients

RND:
    call TSTSGN         ; Test sign of FPREG
    ld   hl, SEED+2     ; Random number seed
    jp   m, .RESEED     ; Negative - Re-seed
    ld   hl, LSTRND     ; Last random number
    call PHLTFP         ; Move last RND to FPREG
    ld   hl, SEED+2     ; Random number seed
    ret  z              ; Return if RND(0)
    add  a, (hl)        ; Add (SEED)+2)
    and  00000111B      ; 0 to 7
    ld   b, 0
    ld   (hl), a        ; Re-save seed
    inc  hl             ; Move to coefficient table
    add  a, a           ; 4 bytes
    add  a, a           ; per entry
    ld   c, a           ; BC = Offset into table
    add  hl, bc         ; Point to coefficient
    call LOADFP         ; Coefficient to BCDE
    call .FPMULT        ;       ; Multiply FPREG by coefficient
    ld   a, (SEED+1)    ; Get (SEED+1)
    inc  a              ; Add 1
    and  00000011B      ; 0 to 3
    ld   b, 0
    cp   1              ; Is it zero?
    adc  a, b           ; Yes - Make it 1
    ld   (SEED+1), a    ; Re-save seed
    ld   hl, .RNDTAB-4  ; Addition table
    add  a, a           ; 4 bytes
    add  a, a           ; per entry
    ld   c, a           ; BC = Offset into table
    add  hl, bc         ; Point to value
    call ADDPHL         ; Add value to FPREG
.RND1:
    call BCDEFP         ; Move FPREG to BCDE
    ld   a, e           ; Get LSB
    ld   e, c           ; LSB = MSB
    xor  01001111B      ; Fiddle around
    ld   c, a           ; New MSB
    ld   (hl), 0x80     ; Set exponent
    dec  hl             ; Point to MSB
    ld   b, (hl)        ; Get MSB
    ld   (hl), 0x80     ; Make value -0.5
    ld   hl, SEED       ; Random number seed
    inc  (hl)           ; Count seed
    ld   a, (hl)        ; Get seed
    sub  171            ; Do it modulo 171
    jp   nz, .RND2      ; Non-zero - Ok
    ld   (hl), a        ; Zero seed
    inc  c              ; Fillde about
    dec  d              ; with the
    inc  e              ; number
.RND2:
    call .BNORM         ; Normalise number
    ld   hl, LSTRND     ; Save random number
    jp   FPTHL          ; Move FPREG to last and return

.RESEED:
    ld   (hl), a        ; Re-seed random numbers
    dec  hl
    ld   (hl), a
    dec  hl
    ld   (hl), a
    jp   .RND1          ; Return RND seed

    .section .rodata.rndtab

.RNDTAB:
    .db  0x68, 0xb1, 0x46, 0x68 ; Table used by RND
    .db  0x99, 0xe9, 0x92, 0x69
    .db  0x10, 0xd1, 0x75, 0x68

    ;; make sure this comes after the above .rodata
    .section .text.cos

COS:
    ld   hl, .HALFPI    ; Point to PI/2
    call ADDPHL         ; Add it to PPREG
SIN:
    call STAKFP         ; Put angle on stack
    ld   bc, 0x8349     ; BCDE = 2 PI
    ld   de, 0x0fdb
    call FPBCDE         ; Move 2 PI to FPREG
    pop  bc             ; Restore angle
    pop  de
    call .DVBCDE        ; Divide angle by 2 PI
    call STAKFP         ; Put it on stack
    call INT            ; Get INT of result
    pop  bc             ; Restore number
    pop  de
    call .SUBCDE        ; Make it 0 <= value < 1
    ld   hl, .QUARTR    ; Point to 0.25
    call .SUBPHL        ; Subtract value from 0.25
    call TSTSGN         ; Test sign of value
    scf                 ; Flag positive
    jp   p, .SIN1       ; Positive - Ok
    call .ROUND         ; Add 0.5 to value
    call TSTSGN         ; Test sign of value
    or   a              ; Flag negative
.SIN1:
    push af             ; Save sign
    call p, INVSGN      ; Negate value if positive
    ld   hl, .QUARTR    ; Point to 0.25
    call ADDPHL         ; Add 0.25 to value
    pop  af             ; Restore sign
    call nc, INVSGN     ; Negative - Make positive
    ld   hl, .SINTAB    ; Coefficient table
    jp   .SUMSER        ; Evaluate sum of series

    .section .rodata.halfpi

.HALFPI:
    .db  0xdb, 0x0f, 0x49, 0x81 ; 1.5708 (PI/2)

.QUARTR:
    .db  0x00, 0x00, 0x00, 0x7f ; 0.25

.SINTAB:
    .db  5              ; Table used by SIN
    .db  0xba, 0xd7, 0x1e, 0x86 ; 39.711
    .db  0x64, 0x26, 0x99, 0x87 ; -76.575
    .db  0x58, 0x34, 0x23, 0x87 ; 81.602
    .db  0xe0, 0x5d, 0xa5, 0x86 ; -41.342
    .db  0xda, 0x0f, 0x49, 0x83 ;  6.2832

    ;; make sure this comes after the above .rodata
    .section .text.tan

TAN:
    call STAKFP         ; Put angle on stack
    call SIN            ; Get SIN of angle
    pop  bc             ; Restore angle
    pop  hl
    call STAKFP         ; Save SIN of angle
    ex   de, hl         ; BCDE = Angle
    call FPBCDE         ; Angle to FPREG
    call COS            ; Get COS of angle
    jp   DIV            ; TAN = SIN / COS

ATN:
    call TSTSGN         ; Test sign of value
    call m, .NEGAFT     ; Negate result after if -ve
    call m, INVSGN      ; Negate value if -ve
    ld   a, (FPEXP)     ; Get exponent
    cp   0x81           ; Number less than 1?
    jp   c, .ATN1       ; Yes - Get arc tangnt
    ld   bc, 0x8100     ; BCDE = 1
    ld   d, c
    ld   e, c
    call .DVBCDE        ; Get reciprocal of number
    ld   hl, .SUBPHL    ; Sub angle from PI/2
    push hl             ; Save for angle > 1
.ATN1:
    ld   hl, .ATNTAB    ; Coefficient table
    call .SUMSER        ; Evaluate sum of series
    ld   hl, .HALFPI    ; PI/2 - angle in case > 1
    ret                 ; Number > 1 - Sub from PI/2

    .section .rodata.atntab

.ATNTAB:
    .db  9              ; Table used by ATN
    .db  0x4a, 0xd7, 0x3b, 0x78 ; 1/17
    .db  0x02, 0x6e, 0x84, 0x7b ; -1/15
    .db  0xfe, 0xc1, 0x2f, 0x7c ; 1/13
    .db  0x74, 0x31, 0x9a, 0x7d ; -1/11
    .db  0x84, 0x3d, 0x5a, 0x7d ; 1/9
    .db  0xc8, 0x7f, 0x91, 0x7e ; -1/7
    .db  0xe4, 0xbb, 0x4c, 0x7e ; 1/5
    .db  0x6c, 0xaa, 0xaa, 0x7f ; -1/3
    .db  0x00, 0x00, 0x00, 0x81 ; 1/1
