    ;; **********************************************************************
    ;; **  Device Driver                             by Stephen C Cousins  **
    ;; **  Hardware:  RC2014                                               **
    ;; **  Interface: Serial 6850 ACIA                                     **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module is the driver for the RC2014 serial I/O interface which is
    ;; based on the 6850 Asynchronous Communications Interface Adapter (ACIA)
    ;;
    ;; Base addresses for ACIA externally defined. eg:
    ;; #define kACIA1     0x80        // Base address of serial ACIA #1
    ;; #define kACIA2     0x40        // Base address of serial ACIA #2
    ;;
    ;; RC2014 addresses for 68B50 number 2:
    ;; 0x40   Control registers (read and write)
    ;; 0x41   Data registers (read and write)
    ;;
    ;; Control registers (read and write)
    ;; Bit   Control write              Control read
    ;;  0    Counter divide select 1    Receive data register full
    ;;  1    Counter divide select 2    Transmit data register empty
    ;;  2    Word select 1              Data carrier detect (/DCD) input
    ;;  3    Word seelct 2              Clear to send (/CTS) input
    ;;  4    Word select 3              Framing error
    ;;  5    Transmit contol 1          Receiver overrun
    ;;  6    Transmit control 2         Parity error
    ;;  7    Receive interrupt enable   Interrupt request
    ;;
    ;; Control register write
    ;; Bit   7   6   5   4   3   2   1   0
    ;;       |   |   |   |   |   |   |   |
    ;;       |   |   |   |   |   |   0   0     Clock divide 1
    ;;       |   |   |   |   |   |   0   1     Clock divide 16
    ;; >     |   |   |   |   |   |   1   0  >  Clock divide 64
    ;;       |   |   |   |   |   |   1   1     Master reset
    ;;       |   |   |   |   |   |
    ;;       |   |   |   0   0   0     7 data bits, even parity, 2 stop bits
    ;;       |   |   |   0   0   1     7 data bits, odd parity,  2 stop bits
    ;;       |   |   |   0   1   0     7 data bits, even parity, 1 stop bit
    ;;       |   |   |   0   1   1     7 data bits, odd parity,  1 stop bit
    ;;       |   |   |   1   0   0     8 data bits, no parity,   2 stop bits
    ;;       |   |   |   1   0   1  >  8 data bits, no parity,   1 stop bit
    ;;       |   |   |   1   1   0     8 data bits, even parity, 1 stop bit
    ;;       |   |   |   1   1   1     8 data bits, odd parity,  1 stop bit
    ;;       |   |   |
    ;;       |   0   0  >  /RTS = low (ready), tx interrupt disabled
    ;;       |   0   1     /RTS = low (ready), tx interrupt enabled
    ;;       |   1   0     /RTS = high (not ready), tx interrupt disabled
    ;;       |   1   1     /RTS = low, tx break, tx interrupt disabled
    ;;       |
    ;;       0  >  Receive interrupt disabled
    ;;       1     Receive interrupt enabled
    ;;
    ;; Control register read
    ;; Bit   7   6   5   4   3   2   1   0
    ;;       |   |   |   |   |   |   |   |
    ;;       |   |   |   |   |   |   |   +-------  Receive data register full
    ;;       |   |   |   |   |   |   +-------  Transmit data register empty
    ;;       |   |   |   |   |   +-------  Data carrier detect (/DCD)
    ;;       |   |   |   |   +-------  Clear to send (/CTS)
    ;;       |   |   |   +-------  Framing error
    ;;       |   |   +-------  Receiver overrun
    ;;       |   +-------  Parity error
    ;;       +-------  Interrupt request

    ;; 6850 #1 registers derived from base address (above)
    #define kACIA1Cont +(kACIA1+0) // I/O address of control register
    #define kACIA1Data +(kACIA1+1) // I/O address of data register
    ;; 6850 #2 registers derived from base address (above)
    #define kACIA2Cont +(kACIA2+0) // I/O address of control register
    #define kACIA2Data +(kACIA2+1) // I/O address of data register

    ;; Control register values
    #define k6850Reset 0b00000011  // Master reset
    #define k6850Init  0b00010110  // No int, RTS low, 8+1, /64

    ;; Status (control) register bit numbers
    #define k6850RxRdy 0           // Receive data available bit number
    #define k6850TxRdy 1           // Transmit data empty bit number

    ;; Device detection, test 1
    ;; This test just reads from the devices' status (control) register
    ;; and looks for register bits in known states:
    ;; /CTS input bit = low
    ;; /DCD input bit = low
    ;; WARNING
    ;; Sometimes at power up the Tx data reg empty bit is zero, but
    ;; recovers after device initialised. So test 1 excludes this bit.
    #define k6850Mask1 0b00001100  // Mask for known bits in control reg
    #define k6850Test1 0b00000000  // Test value following masking

    ;; Device detection, test 2
    ;; This test just reads from the devices' status (control) register
    ;; and looks for register bits in known states:
    ;; /CTS input bit = low
    ;; /DCD input bit = low
    ;; Transmit data register empty bit = high
    #define k6850Mask2 0b00001110  // Mask for known bits in control reg
    #define k6850Test2 0b00000010  // Test value following masking


    ;; RC2014 serial 6850 initialise
    ;;   On entry: No parameters required
    ;;   On exit:  Z flagged if device is found and initialised
    ;;             AF BC DE HL not specified
    ;;             IX IY I AF' BC' DE' HL' preserved
    ;; If the device is found it is initialised
RC2014_SerialACIA1_Initialise:
    ;; First look to see if the device is present
    ;; Test 1, just read from chip, do not write anything
    in   a, (kACIA1Cont) ; Read status (control) register
    and  k6850Mask1     ; Mask for known bits in control reg
    cp   k6850Test1     ; and check for known values
    ret  nz             ; If not found return with NZ flag
    ;; Attempt to initialise the chip
    ld   a, k6850Reset  ; Master reset
    out  (kACIA1Cont), a ; Write to ACIA control register
    ld   a, k6850Init   ; No int, RTS low, 8+1, /64
    out  (kACIA1Cont), a ; Write to ACIA control register
    ;; Test 2, perform tests on chip following initialisation
    in   a, (kACIA1Cont) ; Read status (control) register
    and  k6850Mask2     ; Mask for known bits in control reg
    cp   k6850Test2     ; Test value following masking
    ;;ret  nz           ; Return not found NZ flagged
    ret                 ; Return Z if found, NZ if not

RC2014_SerialACIA2_Initialise:
    ;; First look to see if the device is present
    ;; Test 1, just read from chip, do not write anything
    in   a, (kACIA2Cont) ; Read status (control) register
    and  k6850Mask1     ; Mask for known bits in control reg
    cp   k6850Test1     ; and check for known values
    ret  nz             ; If not found return with NZ flag
    ;; Attempt to initialise the chip
    ld   a, k6850Reset  ; Master reset
    out  (kACIA2Cont), a ; Write to ACIA control register
    ld   a, k6850Init   ; No int, RTS low, 8+1, /64
    out  (kACIA2Cont), a ; Write to ACIA control register
    ;; Test 2, perform tests on chip following initialisation
    in   a, (kACIA2Cont) ; Read status (control) register
    and  k6850Mask2     ; Mask for known bits in control reg
    cp   k6850Test2     ; Test value following masking
    ;;ret  nz           ; Return not found NZ flagged
    ret                 ; Return Z if found, NZ if not


    ;; RC2014 serial 6850 input character
    ;;   On entry: No parameters required
    ;;   On exit:  A = Character input from the device
    ;;             NZ flagged if character input
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; This function does not return until a character is available
RC2014_SerialACIA1_InputChar:
    in   a, (kACIA1Cont) ; Address of status register
    bit  k6850RxRdy, a  ; Receive byte available
    ret  z              ; Return Z if no character
    in   a, (kACIA1Data) ; Read data byte
    ret                 ; NZ flagged if character input

RC2014_SerialACIA2_InputChar:
    in   a, (kACIA2Cont) ; Address of status register
    bit  k6850RxRdy, a  ; Receive byte available
    ret  z              ; Return Z if no character
    in   a, (kACIA2Data) ; Read data byte
    ret                 ; NZ flagged if character input


    ;; RC2014 serial 6850 output character
    ;;   On entry: A = Character to be output to the device
    ;;   On exit:  If character output successful (eg. device was ready)
    ;;               NZ flagged and A != 0
    ;;             If character output failed (eg. device busy)
    ;;               Z flagged and A = Character to output
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
RC2014_SerialACIA1_OutputChar:
    push bc
    ld   c, kACIA1Cont  ; ACIA control register
    in   b, (c)         ; Read ACIA control register
    bit  k6850TxRdy, b  ; Transmit register full?
    pop  bc
    ret  z              ; Return Z as character not output
    out  (kACIA1Data), a ; Write data byte
    or   0xff           ; Return success A=0xFF and NZ flagged
    ret

RC2014_SerialACIA2_OutputChar:
    push bc
    ld   c, kACIA2Cont  ; ACIA control register
    in   b, (c)         ; Read ACIA control register
    bit  k6850TxRdy, b  ; Transmit register full?
    pop  bc
    ret  z              ; Return Z as character not output
    out  (kACIA2Data), a ; Write data byte
    or   0xff           ; Return success A=0xFF and NZ flagged
    ret


    ;; **********************************************************************
    ;; **  End of driver: RC2014, Serial 6850 ACIA                         **
    ;; **********************************************************************
