    ;; **********************************************************************
    ;; **  Small Computer Monitor API                by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif
    ;;
    ;; **  Written as a module to be included in Small Computer Monitor Apps
    ;; **  Version 0.2 SCC 2018-05-15
    ;; **  www.scc.me.uk
    ;;
    ;; **********************************************************************
    ;;
    ;; This module provides shims for SCMonitor API functions
    ;;
    ;; **********************************************************************
    ;;
    ;; These are the function names provided by this module:
    ;; aSystemReset                  API 0x00: System reset
    ;; aInputChar                    API 0x01: Input character from console
    ;; aOutputChar                   API 0x02: Output character to console
    ;; aInputStatus                  API 0x03: Get console input status
    ;; aInputLineTo                  API 0x04: Input line to specified address
    ;; aInputLineDef                 API 0x05: Input line to default address
    ;; aOutputText                   API 0x06: Output null terminated string
    ;; aOutputNewLine                API 0x07: Output new line (eg. CR+LF)
    ;; aGetVersion                   API 0x08: Get version details
    ;; aClaimJumpTab                 API 0x09: Claim jump table entry
    ;; aDelayInMS                    API 0x0A: Delay in milliseconds
    ;; aOutputSysMsg                 API 0x0B: Output system message
    ;; aReadJumpTab                  API 0x0C: Read jump table entry
    ;; aSelectConDev                 API 0x0D: Select console I/O device
    ;; aSelectConIn                  API 0x0E: Select console input device
    ;; aSelectConOut                 API 0x0F: Select console output device
    ;; aInputFromDev                 API 0x10: Input from specified device
    ;; aOutputToDev                  API 0x11: Output to specified device
    ;; aPollEvents                   API 0x12: Poll idle events
    ;; aConfigEvents                 API 0x13: Configure idle events
    ;; aSet1msTimer                  API 0x14: Set up 1 ms timer 1
    ;; aSet10msTimer                 API 0x15: Set up 10 ms timer 2
    ;; aSet100msTimer                API 0x16: Set up 100 ms timer 3
    ;; aInitOutPort                  API 0x17: Initialise output port
    ;; aWriteOutPort                 API 0x18: Write to output port
    ;; aReadOutPort                  API 0x19: Read from output port
    ;; aTestOutBit                   API 0x1A: Test output port bit
    ;; aSetOutBit                    API 0x1B: Set output port bit
    ;; aClearOutBit                  API 0x1C: Clear output port bit
    ;; aInvertOutBit                 API 0x1D: Invert output port bit
    ;; aInitInPort                   API 0x1E: Initialise input port
    ;; aReadInPort                   API 0x1F: Read from input port
    ;; aTestInBit                    API 0x20: Test input port bit
    ;; aSetBaudRate                  API 0x21: Set baud rate
    ;; aExecuteCL                    API 0x22: Execute command line string
    ;; aGetPtrToCL                   API 0x23: Get pointer to command line
    ;; aSkipDelim                    API 0x24: Skip delimiter in line
    ;; aSkipNonDelim                 API 0x25: Skip non-delimiter in line
    ;; aGetHexParam                  API 0x26: Get hex parameter from line
    ;; aGetConDevices                API 0x27: Get console device numbers
    ;; aGetTopOfMem                  API 0x28: Get top of free memory
    ;; aSetTopOfMem                  API 0x29: Set top of free memory

    #include "scm-api.h"


    ;; **********************************************************************
    ;; **  SC Monitor API functions
    ;; **********************************************************************

    ;; API 0x00: System reset
    ;;  On entry:  A = Reset type:
    ;;               0 = Cold start monitor
    ;;               1 = Warm start monitor
    ;;   On exit:  System resets
    .pushsection .text.aSystemReset
    .global aSystemReset
aSystemReset:
    ld   c, 0x00        ; API 0x00
    rst  0x30           ;  = System reset
    .popsection


    ;; API 0x01: Input character
    ;;   On entry: No parameters required
    ;;   On exit:  A = Character input from current console device
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Function does not return until a character has been received
    .pushsection .text.aInputChar
    .global aInputChar
aInputChar:
    push bc
    push de
    push hl
    ld   c, 0x01        ; API 0x01
    rst  0x30           ;  = Input character
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x02: Output character
    ;;   On entry: A = Character to be output to the current console device
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aOutputChar
    .global aOutputChar
aOutputChar:
    push af
    push bc
    push de
    push hl
    ld   c, 0x02        ; API 0x02
    rst  0x30           ;  = Output character
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x03: Get character input status
    ;;   On entry: No parameters required
    ;;   On exit:  NZ if character available
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aInputStatus
    .global aInputStatus
aInputStatus:
    push bc
    push de
    push hl
    ld   c, 0x03        ; API 0x03
    rst  0x30           ;  = Character input status
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x04: Input line to specified buffer
    ;;   On entry: DE = Start of buffer
    ;;             A = Size of input buffer in bytes
    ;;   On exit:  A = Number of characters in input buffer
    ;;             Z flagged if no characters in bufffer ???
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts enabled during this call ???
    ;; Maximum buffer length 255 bytes.
    ;; The buffer length includes the string termination character (null).
    ;; The number of characters returned does not include the null terminator.
    .pushsection .text.aInputLineTo
    .global aInputLineTo
aInputLineTo:
    push bc
    push de
    push hl
    ld   c, 0x04        ; API 0x04
    rst  0x30           ;  = Input line
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x05: Input line to default buffer
    ;;   On entry: No parameters required
    ;;   On exit:  DE = Start location of buffer
    ;;             A = Number of characters in buffer
    ;;             Z flagged if no characters in bufffer
    ;;             BC HL IX IY I AF' BC' DE' HL' preserved
    ;;             Interrupts enabled during this call ???
    ;; The number of characters returned does not include the null terminator.
    ;; DE points to a null terminated string to be edited
    .pushsection .text.aInputLineDef
    .global aInputLineDef
aInputLineDef:
    push bc
    push hl
    ld   c, 0x05        ; API 0x05
    rst  0x30           ;  = Input line default
    pop  hl
    pop  bc
    ret
    .popsection


    ;; API 0x06: Output text string (null terminated)
    ;;   On entry: DE = Pointer to start of null terminated string
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aOutputText
    .global aOutputText
aOutputText:
    push af
    push bc
    push de
    push hl
    ld   c, 0x06        ; API 0x06
    rst  0x30           ;  = Output string
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x07: Output new line
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aOutputNewLine
    .global aOutputNewLine
aOutputNewLine:
    push af
    push bc
    push de
    push hl
    ld   c, 0x07        ; API 0x07
    rst  0x30           ;  = Output new line
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x08: Get version details
    ;;   On entry: No parameters required
    ;;   On exit:  D,E and A = Monitor code version
    ;;               D = kVersMajor
    ;;               E = kVersMinor
    ;;               A = kVersRevis(ion)
    ;;             B,C = Configuration ID
    ;;               B = kConfMajor ('R'=RC2014, 'L'=LiNC80, etc)
    ;;               C = kConfMinor (sub-type '1', '2', etc)
    ;;             H,L = Target hardware ID
    ;;               H = kHardID (1=Simulator, 2=,SCDevKt, 3=RC2014, etc)
    ;;               L = Hardware option flags (hardware specific)
    ;;             IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aGetVersion
    .global aGetVersion
aGetVersion:
    ld   c, 0x08        ; API 0x08
    rst  0x30           ;  = Get version details
    ret
    .popsection


    ;; API 0x09: Claim/write jump table entry
    ;;   On entry: A = Entry number (0 to n)
    ;;             DE = Address of function
    ;;   On exit:  No parameters returned
    ;;             AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Some system functions, such as console in and console out, are
    ;; redirected through a jump table. By claiming a jump table entry the
    ;; function can be handled by any required code. This might allow
    ;; swapping output to a different device, such as a printer.
    .pushsection .text.aClaimJumpTab
    .global aClaimJumpTab
aClaimJumpTab:
    push af
    push bc
    push de
    push hl
    ld   c, 0x09        ; API 0x09
    rst  0x30           ;  = Claim jump table entry
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x0A: Delay in milliseconds
    ;;   On entry: A = Number of milliseconds delay
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aDelayInMS
    .global aDelayInMS
aDelayInMS:
    push af
    push bc
    push de
    push hl
    ld   d, 0
    ld   e, a
    ld   c, 0x0a        ; API 0x0A
    rst  0x30           ;  = Delay in milliseconds
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x0B: Output system message
    ;;  On entry:  A = Message number (0 to n)
    ;;  On exit:   AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aOutputSysMsg
    .global aOutputSysMsg
aOutputSysMsg:
    push af
    push bc
    push de
    push hl
    ld   c, 0x0b        ; API 0x0B
    rst  0x30           ;  = Output system message
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x0C: Read system jump table entry
    ;;   On entry: A = Entry number (0 to n)
    ;;   On exit:  DE = Address of function
    ;;             AF BC HL IX IY I AF' BC' DE' HL' preserved
    ;; Some system functions, such as console in and console out, are
    ;; redirected through a jump table. By claiming a jump table entry the
    ;; function can be handled by any required code. This might allow
    ;; swapping output to a different device, such as a printer.
    .pushsection .text.aReadJumpTab
    .global aReadJumpTab
aReadJumpTab:
    push af
    push bc
    push hl
    ld   c, 0x0c        ; API 0x0C
    rst  0x30           ;  = Read jump table entry
    pop  hl
    pop  bc
    pop  af
    ret
    ;; Jump table entry numbers defined in aClaimJumpTab (above)
    .popsection


    ;; API 0x0D: Select console I/O device
    ;;   On entry: A = New console device number (1 to n)
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Select both input and output device
    .pushsection .text.aSelectConDev
    .global aSelectConDev
aSelectConDev:
    push af
    push bc
    push de
    push hl
    ld   c, 0x0d        ; API 0x0D
    rst  0x30           ;  = Select console I/O device
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x0E: Select console input device
    ;;   On entry: A = New console device number (1 to n)
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Select input device only
    .pushsection .text.aSelectConIn
    .global aSelectConIn
aSelectConIn:
    push af
    push bc
    push de
    push hl
    ld   c, 0x0e        ; API 0x0E
    rst  0x30           ;  = Select console input device
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x0F: Select console output device
    ;;   On entry: A = New console device number (1 to n)
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Select output device only
    .pushsection .text.aSelectConOut
    .global aSelectConOut
aSelectConOut:
    push af
    push bc
    push de
    push hl
    ld   c, 0x0f        ; API 0x0F
    rst  0x30           ;  = Select console output device
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x10: Input from specified console device
    ;;   On entry: E = Console device number (1 to n)
    ;;   On exit:  A = Character input 9if there is one ready)
    ;;             NZ flagged if character has been input
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aInputFromDev
    .global aInputFromDev
aInputFromDev:
    push bc
    push de
    push hl
    ld   c, 0x10        ; API 0x10
    rst  0x30           ;  = Input from specified device
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x11: Output to specified console device
    ;;   On entry: A = Character to be output
    ;;             E = Console device number (1 to n)
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aOutputToDev
    .global aOutputToDev
aOutputToDev:
    push af
    push bc
    push de
    push hl
    ld   c, 0x11        ; API 0x11
    rst  0x30           ;  = Output to specified device
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x12: Poll idle events
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aPollEvents
    .global aPollEvents
aPollEvents:
    push af
    push bc
    push de
    push hl
    ld   c, 0x12        ; API 0x12
    rst  0x30           ;  = Poll idle events
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x13: Configure idle events
    ;;   On entry: A = Configuration:
    ;;                 0 = Off (just execute RET instruction)
    ;;                 1 = Software generated timer events
    ;;                 2+ = Future expansion
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aConfigEvents
    .global aConfigEvents
aConfigEvents:
    push af
    push bc
    push de
    push hl
    ld   c, 0x13        ; API 0x13
    rst  0x30           ;  = Configure idle events
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x14: Set up 1 ms timer (timer 1)
    ;;   On entry: A = Time period in units of 1 ms
    ;;             DE = Address of timer event handler
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aSet1msTimer
    .global aSet1msTimer
aSet1msTimer:
    push af
    push bc
    push de
    push hl
    ld   c, 0x14        ; API 0x14
    rst  0x30           ;  = Set up 1 ms timer 1
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x15: Set up 10 ms timer (timer 2)
    ;;   On entry: A = Time period in units of 10 ms
    ;;             DE = Address of timer event handler
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aSet10msTimer
    .global aSet10msTimer
aSet10msTimer:
    push af
    push bc
    push de
    push hl
    ld   c, 0x15        ; API 0x15
    rst  0x30           ;  = Set up 10 ms timer 2
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x16: Set up 100 ms timer (timer 3)
    ;;   On entry: A = Time period in units of 100 ms
    ;;             DE = Address of timer event handler
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aSet100msTimer
    .global aSet100msTimer
aSet100msTimer:
    push af
    push bc
    push de
    push hl
    ld   c, 0x16        ; API 0x16
    rst  0x30           ;  = Set up 100 ms timer 3
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x17: Initialise output port
    ;;   On entry: A = Output port address
    ;;   On exit:  A = Output port data byte (which will be zero)
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aInitOutPort
    .global aInitOutPort
aInitOutPort:
    push bc
    push de
    push hl
    ld   c, 0x17        ; API 0x17
    rst  0x30           ;  = Initialise output port
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x18: Write output port data
    ;;   On entry: A = Output data byte
    ;;   On exit:  A = Output port data
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aWriteOutPort
    .global aWriteOutPort
aWriteOutPort:
    push bc
    push de
    push hl
    ld   c, 0x18        ; API 0x18
    rst  0x30           ;  = Write output port data
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x19: Read output port data
    ;;   On entry: no parameters required
    ;;   On exit:  A = Output port data
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved

    .pushsection .text.aReadOutPort
    .global aReadOutPort
aReadOutPort:
    push bc
    push de
    push hl
    ld   c, 0x19        ; API 0x19
    rst  0x30           ;  = Read output port data
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x1A: Test output port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = 0 and Z flagged if bit low
    ;;             A !=0 and NZ flagged if bit high
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aTestOutBit
    .global aTestOutBit
aTestOutBit:
    push bc
    push de
    push hl
    ld   c, 0x1a        ; API 0x1A
    rst  0x30           ;  = Test output port bit
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x1B: Set output port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = Output port data
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aSetOutputPortBit
    .global aSetOutputPortBit
aSetOutBit:
    push bc
    push de
    push hl
    ld   c, 0x1b        ; API 0x1B
    rst  0x30           ;  = Set output port bit
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x1C: Clear output port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = Output port data
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aClearOutputPortBit
    .global aClearOutputPortBit
aClearOutBit:
    push bc
    push de
    push hl
    ld   c, 0x1c        ; API 0x1C
    rst  0x30           ;  = Clear output port bit
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x1D: Invert output port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = Output port data
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aInvertOutBit
    .global aInvertOutBit
aInvertOutBit:
    push bc
    push de
    push hl
    ld   c, 0x1d        ; API 0x1D
    rst  0x30           ;  = Invert output port bit
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x1E: Initialise input port
    ;;   On entry: A = Input port address
    ;;   On exit:  A = Input port data byte
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aInitInPort
    .global aInitInPort
aInitInPort:
    push bc
    push de
    push hl
    ld   c, 0x1e        ; API 0x1E
    rst  0x30           ;  = Initialise input port
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x1F: Read input port data
    ;;   On entry: no parameters required
    ;;   On exit:  A = Input port data
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aReadInPort
    .global aReadInPort
aReadInPort:
    push bc
    push de
    push hl
    ld   c, 0x1f        ; API 0x1F
    rst  0x30           ;  = Read intput port data
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x20: Test input port bit
    ;;   On entry: A = Bit number 0 to 7
    ;;   On exit:  A = 0 and Z flagged if bit low
    ;;             A !=0 and NZ flagged if bit high
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aTestInBit
    .global aTestInBit
aTestInBit:
    push bc
    push de
    push hl
    ld   c, 0x20        ; API 0x20
    rst  0x30           ;  = Test input port bit
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x21: Set baud rate
    ;;  On entry:  A = Device identifier (0x01 to 0x06, or 0x0A to 0x0B)
    ;;             E = Baud rate code
    ;;   On exit:  IF successful: (ie. valid device and baud code)
    ;;               A != 0 and NZ flagged
    ;;             BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aSetBaudRate
    .global aSetBaudRate
aSetBaudRate:
    push bc
    push de
    push hl
    ld   c, 0x21        ; API 0x21
    rst  0x30           ;  = Set baud rate
    pop  hl
    pop  de
    pop  bc
    ret
    .popsection


    ;; API 0x22: Execute command line
    ;;  On entry:  DE = Start of command string terminated in Null
    ;;  On exit:   If command handled (blank line or executed command):
    ;;               A = 0x00 and Z flagged
    ;;             If command not handled:
    ;;               A = 0xFF and NZ flagged
    ;;             No register contents preserved
    ;; Offer string to command line interpreter
    ;; If found the command is executed before return. HL points to
    ;; start of parameter string when command code entered.
    .pushsection .text.aExecuteCL
    .global aExecuteCL
aExecuteCL:
    ld   c, 0x22        ; API 0x22
    rst  0x30           ;  = Execute command line
    ret
    .popsection


    ;; API 0x23: Get pointer to current position in command line string
    ;;   On entry: No parameters required
    ;;   On exit:  DE = Address of string typically in command line
    ;;             AF BC HL IX IY I AF' BC' DE' HL' preserved
    ;; Used by monitor command files to read command parameters
    .pushsection .text.aGetPtrToCL
    .global aGetPtrToCL
aGetPtrToCL:
    push af
    push bc
    push hl
    ld   c, 0x23        ; API 0x23
    rst  0x30           ;  = Get pointer to command line
    pop  hl
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x24: Skip deliminaters in command line
    ;;   On entry: DE = Start address in input line
    ;;   On exit:  If end of line (null) found:
    ;;               A = Zero and Z flagged
    ;;               DE = Address of null character
    ;;             If non-delimiter character found:
    ;;               A = Character found and NZ flagged
    ;;               DE = Address of first non-delimiter character
    ;;             BC HL IX IY preserved
    ;; Delimiters are spaces or tabs (actually any control character other
    ;;   than null)
    ;; Input line must be null terminated
    ;; The return address can be that of the null terminator
    .pushsection .text.aSkipDelim
    .global aSkipDelim
aSkipDelim:
    push bc
    push hl
    ld   c, 0x24        ; API 0x24
    rst  0x30           ;  = Skip delimiter in command line
    pop  hl
    pop  bc
    ret
    .popsection


    ;; API 0x25: Skip non-deliminaters in input line
    ;;   On entry: DE = Start address in input line
    ;;   On exit:  A = Character at returned address
    ;;             DE = Address of first non-delimiter character
    ;;             BC HL IX IY preserved
    ;; Delimiters are spaces or tabs (actually any control character other
    ;;   than null)
    ;; Input line must be null terminated
    ;; The return address can be that of the null terminator
    .pushsection .text.aSkipNonDelim
    .global aSkipNonDelim
aSkipNonDelim:
    push bc
    push hl
    ld   c, 0x25        ; API 0x25
    rst  0x30           ;  = Skip delimiter in command line
    pop  hl
    pop  bc
    ret
    .popsection


    ;; API 0x26: Get hex word/byte from input line
    ;;   On entry: A = Error reporting flags kReportXXX
    ;;             DE = Location of parameter in input line
    ;;             HL = Default value returned if no parameter found
    ;;   On exit:  If a valid hex parameter:
    ;;               A = 0x00 and Z flagged and C flagged
    ;;               DE = Location after parameter in input line
    ;;               HL = Hex byte/word from input line
    ;;               Carry flagged if no parameter found
    ;;             If no parameter if found:
    ;;               A = 0x00 and Z flagged and NC flagged
    ;;               DE = Location after parameter in input line
    ;;               HL = Hex byte/word from input line
    ;;               Carry flagged if no parameter found
    ;;               An error message is may be shown
    ;;             If an invalid hex parameter is found
    ;;               A = 0xFF and NZ flagged and NC flagged
    ;;               DE = Location after any valid characters
    ;;               HL = Unspecified
    ;;               An error message is may be shown
    ;;             BC IX IY preserved
    ;; If a non-hex character is encountered before a delimiter or null an
    ;; error is reported.
    .pushsection .text.aGetHexParam
    .global aGetHexParam
aGetHexParam:
    push bc
    ld   c, 0x26        ; API 0x26
    rst  0x30           ;  = Get hex parameter from input line
    pop  bc
    ret
    .popsection


    ;; API 0x27: Get current console device numbers
    ;;   On entry: No parameters required
    ;;   On exit:  D = Current console output device number
    ;;             E = Current console input device number
    ;;   On exit:  AF BC HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aGetConDevices
    .global aGetConDevices
aGetConDevices:
    push af
    push bc
    push hl
    ld   c, 0x27        ; API 0x27
    rst  0x30           ;  = Get current console device numbers
    pop  hl
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x28: Get top of free memory
    ;;   On entry: No parameters required
    ;;   On exit:  DE = Top of free memory
    ;;             AF BC HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aGetTopOfMem
    .global aGetTopOfMem
aGetTopOfMem:
    push af
    push bc
    push hl
    ld   c, 0x28        ; API 0x28
    rst  0x30           ;  = Get top of free memory
    pop  hl
    pop  bc
    pop  af
    ret
    .popsection


    ;; API 0x29: Set top of free memory
    ;;   On entry: DE = Top of free memory
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    .pushsection .text.aSetTopOfMem
    .global aSetTopOfMem
aSetTopOfMem:
    push af
    push bc
    push de
    push hl
    ld   c, 0x29        ; API 0x29
    rst  0x30           ;  = Set top of free memory
    pop  hl
    pop  bc
    pop  de
    pop  af
    ret
    .popsection
