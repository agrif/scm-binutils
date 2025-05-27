    ;; **********************************************************************
    ;; **  Port functions                            by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    ;; This module provides functions to manipulate I/O ports.
    ;;
    ;; Public functions provided
    ;;   PrtOInit              Initialise output port
    ;;   PrtOWr                Write to output port
    ;;   PrtORd                Read from output port
    ;;   PrtOTst               Test output port bit
    ;;   PrtOSet               Set output port bit
    ;;   PrtOClr               Clear output port bit
    ;;   PrtOInv               Invert output port bit
    ;;   PrtIInit              Initialise input port
    ;;   PrtIRd                Read from input port
    ;;   PrtITst               Test input port bit


    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Ports: Initialise output port
    ;;   On entry: A = Output port address
    ;;   On exit:  A = Output port data byte (which will be zero)
    ;;             DE HL IX IY I AF' BC' DE' HL' preserved
PrtOInit:
    ld   (iPrtOutA), a  ; Store port address
    xor  a              ; Clear A (data)
    jr   PrtOWr         ; Write A to output port

    ;; Ports: Read output port data
    ;;   On entry: no parameters required
    ;;   On exit:  A = Output port data
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
PrtORd:
    ld   a, (iPrtOutD)  ; Read output port
    ret

    ;; Ports: Test output port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = 0 and Z flagged if bit low
    ;;             A !=0 and NZ flagged if bit high
    ;;             DE IX IY I AF' BC' DE' HL' preserved
PrtOTst:
    call PortMask       ; Get bit mask for bit A
    and  b              ; Test against bit masked in B
    ret                 ; Flag NZ if bit set

    ;; Ports: Set output port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = Output port data
    ;;             DE IX IY I AF' BC' DE' HL' preserved
PrtOSet:
    call PortMask       ; Get bit mask for bit A
    or   b              ; Set bit masked in B
    jr   PrtOWr         ; Write to port

    ;; Ports: Clear output port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = Output port data
    ;;             DE IX IY I AF' BC' DE' HL' preserved
PrtOClr:
    call PortMask       ; Get bit mask for bit A
    ld   c, a           ; Remember output port data
    ld   a, b           ; Get bit mask
    cpl                 ; Complement mask (invert bits)
    and  c              ; Invert bit masked in A
    jr   PrtOWr         ; Write to port

    ;; Ports: Invert output port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = Output port data
    ;;             DE IX IY I AF' BC' DE' HL' preserved
PrtOInv:
    call PortMask       ; Get bit mask for bit A
    xor  b              ; Invert bit masked in B
    ;; JR   PrtOWr        ;Write to port

    ;; Ports: Write to output port
    ;;   On entry: A = Output data byte
    ;;   On exit:  A = Output port data
    ;;             DE HL IX IY I AF' BC' DE' HL' preserved
PrtOWr:
    ld   b, a           ; Remember port data
    ld   a, (iPrtOutA)  ; Get port address
    ld   c, a           ; Remember port address
    ld   a, b           ; Get port data
    ld   (iPrtOutD), a  ; Store port data
    out  (c), a         ; Write to port
    ret


    ;; Ports: Initialise input port
    ;;   On entry: A = Input port address
    ;;   On exit:  A = Input port data
    ;;             DE HL IX IY I AF' BC' DE' HL' preserved
PrtIInit:
    ld   (iPrtInA), a   ; Store port address
    xor  a              ; Clear A (data)
    ;; JR   PrtIRd        ;Write A to output port

    ;; Ports: Read input port data
    ;;   On entry: no parameters required
    ;;   On exit:  A = Input port data
    ;;             B DE HL IX IY I AF' BC' DE' HL' preserved
PrtIRd:
    ld   a, (iPrtInA)   ; Get input port address
    ld   c, a           ; Remember port address
    in   a, (c)         ; Read input port data
    ret

    ;; Ports: Test input port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = 0 and Z flagged if bit low
    ;;             A !=0 and NZ flagged if bit high
    ;;             DE IX IY I AF' BC' DE' HL' preserved
PrtITst:
    call PortMask       ; Get bit mask for bit A
    ld   a, (iPrtInA)   ; Get input port address
    ld   c, a           ; Remember port address
    in   a, (c)         ; Read input port data
    and  b              ; Test against bit masked in B
    ret                 ; Flag NZ if bit set


    ;; **********************************************************************
    ;; **  Private functions                                               **
    ;; **********************************************************************

    ;; Get bit mask for bit A
    ;;   On entry: A = Output port address
    ;;   On exit:  B = Bit mask
    ;;             A = Current output port value
    ;;             DE IX IY I AF' BC' DE' HL' preserved
PortMask:
    ld   hl, .PortMaskMaskTab ; Start of bit mask table
    ld   c, a           ; Get bit number
    ld   b, 0           ; Clear B
    add  hl, bc         ; Calculate location of bit mask in table
    ld   b, (hl)        ; Get bit mask
    ld   a, (iPrtOutD)  ; Get output data
    ret
    ;; Bit mask table: bit 0 mask, bit 1 mask, ...
    .pushsection .rodata
.PortMaskMaskTab:
    .db  1, 2, 4, 8, 16, 32, 64, 128
    .popsection


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

iPrtInA:
    .db  0              ; Input port address
iPrtOutA:
    .db  0              ; Output port address
iPrtOutD:
    .db  0              ; Output port data


    ;; **********************************************************************
    ;; **  End of Port functions module                                    **
    ;; **********************************************************************
