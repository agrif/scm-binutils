    ;; **********************************************************************
    ;; **  Idle events                               by Stephen C Cousins  **
    ;; **********************************************************************
    ;; converted to GNU binutils by agrif

    #include "scm.h"

    ;; This module handles the idle events.
    ;;
    ;; When the processor is not busy it repeatedly calls the idle handler.
    ;; By default this is just a return instruction, but the system can be
    ;; configured to call IdlePoll instead. See API function 0x13.
    ;;
    ;; IdlePoll tries to emulate a timer interrupt and issues timer events
    ;; at specified multiples 1 ms, 10 ms or 100 ms. Due to the lack of
    ;; hardware timer as standard in a typical small computer system (such
    ;; as RC2014) this function does not produce accurately timed events.
    ;; Systems with a hardware timer, such as LiNC80, sync the idle events
    ;; to the timer for better accuracy.
    ;;
    ;; Timer events are issued via the jump table to allow them to be
    ;; directed anywhere required. Events are NOT issued from within an
    ;; interrupt routine, but are simply subroutine calls made from within
    ;; system functions like Console Input.
    ;;
    ;; Timer event handlers must preserve all registers except AF and HL,
    ;; which are already preserved on the stack.
    ;;
    ;;
    ;; Public functions provided
    ;;   IdleConfig            Configure idle event handler
    ;;   IdlePoll              Poll idle events
    ;;   IdleTimer1            Set up Timer 1 event in multiples of 1 ms
    ;;   IdleTimer2            Set up Timer 1 event in multiples of 10 ms
    ;;   IdleTimer3            Set up Timer 1 event in multiples of 100 ms


    ;; **********************************************************************
    ;; **  Public functions                                                **
    ;; **********************************************************************

    ;; Idle: Configure idle events
    ;;   On entry: A = Configuration:
    ;;                 0 = Off (just execute RET instruction)
    ;;                 1 = Software generated timer events
    ;;                 2+ = Future expansion
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
IdleConfig:
    ld   de, .IdleConfigReturn ; Idle mode 0 routine
    or   a              ; A=0?
    jr   z, .IdleConfigIdleSet ; Yes, so skip
    ld   de, IdlePoll   ; Idle mode 1 routine
    ;; Set up event handler by writing to jump table
.IdleConfigIdleSet:
    ld   a, kFnIdle     ; Jump table 0x0C = idle handler
    jp   ClaimJump      ; Write jump table entry A
.IdleConfigReturn:
    ret                 ; Idle mode zero routine


    ;; Idle: Poll idle events
    ;;   On entry: No parameters required
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
    ;; Registers must be preserved by this function
IdlePoll:
    push af
    call Hardware_PollTimer
    jr   nz, .IdlePollEvent1ms ; Skip if 1ms event to process
    pop  af             ;  otherwise exit now
    ret
    ;; 1 ms tick (we arrive here approximately 1000 times each second)
.IdlePollEvent1ms:
    push bc             ; Preserve BC
    push de             ; Preserve DE
    push hl             ; Preserve HL
    ld   hl, iIdleT1    ; Point to timer 1
    dec  (hl)           ; Decrement timer 1
    jr   nz, .IdlePollIdleT1end ; Skip if not zero
    ld   a, (iIdleP1)   ; Get period for timer 1
    ld   (hl), a        ; Reset timer 1
    call JpTimer1       ; Call n x 1 ms timer event handler
.IdlePollIdleT1end:
    ld   hl, iIdleMS    ; Point to millisecond counter
    dec  (hl)           ; Decrement millisecond counter
    jr   nz, .IdlePollIdleExit ; Not zero so exit
    ;; 10 ms tick (we arrive here approximately 100 times each second)
    ld   (hl), 10       ; Reset millisecond counter to 10
    ld   hl, iIdleT2    ; Point to timer 2
    dec  (hl)           ; Decrement timer 2
    jr   nz, .IdlePollIdleT2end ; Skip if not zero
    ld   a, (iIdleP2)   ; Get period for timer 2
    ld   (hl), a        ; Reset timer 2
    call JpTimer2       ; Call n x 10 ms timer event handler
.IdlePollIdleT2end:
    ld   hl, iIdleCS    ; Point to centisecond counter
    dec  (hl)           ; Decrement centisecond counter
    jr   nz, .IdlePollIdleExit ; Not zero so exit
    ;; 100 ms tick (we arrive here approximately 10 times each second)
    ld   (hl), 10       ; Reset centisecond counter to 10
    ld   hl, iIdleT3    ; Point to timer 3
    dec  (hl)           ; Decrement timer 3
    jr   nz, .IdlePollIdleExit ; Skip if not zero
    ld   a, (iIdleP3)   ; Get period for timer 3
    ld   (hl), a        ; Reset timer 3
    call JpTimer3       ; Call n x 100 ms timer event handler
.IdlePollIdleExit:
    pop  hl             ; Restore HL
    pop  de             ; Restore DE
    pop  bc             ; Restore BC
    pop  af
    ret


    ;; Idle: Set up timer 1 / 2 / 3
    ;;   On entry: A = Time period in units of 1 ms / 10 ms / 100 ms
    ;;             DE = Address of timer event handler
    ;;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
IdleTimer1:
    ld   c, 1           ; Timer 1 (resolution 1 ms)
    jr   IdleSetUp
IdleTimer2:
    ld   c, 2           ; Timer 2 (resolution 10 ms)
    jr   IdleSetUp
IdleTimer3:
    ld   c, 3           ; Timer 3 (resolution 100 ms)
    ;; Set up timer number C (1 to 3)
IdleSetUp:
    ld   b, 0
    ld   hl, iIdleT1-2  ; Start of timer and period data
    add  hl, bc         ; Calculate address of timer data
    add  hl, bc         ;  which take two bytes each
    ld   (hl), a        ; Store timer value
    inc  hl             ; Point to period value
    ld   (hl), a        ; Store period value
    ld   a, c           ; Get timer number
    add  a, kFnTimer1-1 ; Calculate jump table entry number
    jp   ClaimJump      ; Write handler address to jump table


    ;; **********************************************************************
    ;; **  Private functions                                               **
    ;; **********************************************************************


    ;; **********************************************************************
    ;; **  Private workspace (in RAM)                                      **
    ;; **********************************************************************

    .bss

    ;; Cycle counting variables
iIdleMS:
    .db  0              ; Millisecond counter
iIdleCS:
    .db  0              ; Centisecond counter

    ;; Periods and timers
    ;; Each timer has a period value and a count down timer value
    ;; WARNING: Do not change order as hard coded (above)
iIdleT1:
    .db  0              ; Timer 1 (resolution = 1 ms)
iIdleP1:
    .db  0              ; Period 1 (resolution = 1 ms)
iIdleT2:
    .db  0              ; Timer 2 (resolution = 10 ms)
iIdleP2:
    .db  0              ; Period 2 (resolution = 10 ms)
iIdleT3:
    .db  0              ; Timer 3 (resolution = 100 ms)
iIdleP3:
    .db  0              ; Period 3 (resolution = 100 ms)


    ;; **********************************************************************
    ;; **  End of Idle events module                                       **
    ;; **********************************************************************
