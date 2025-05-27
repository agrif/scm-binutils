// **********************************************************************
// **  Small Computer Monitor (SCMonitor)        by Stephen C Cousins  **
// **                                                                  **
// **  Developed with Small Computer Workshop (IDE)     www.scc.me.uk  **
// **********************************************************************
// converted to GNU binutils by agrif

// Source code version number: Major.Minor.Revision (.Touch)
// This is the version number of the core code and does not include
// the hardware drivers.
// This version number is only changed when the source code no longer
// produces the same binary code for all existing builds.
// Cosmetic changes to the source and changes only affecting new
// hardware do not require the version number to change, only the
// 'Touch' date (which is an invisible part of the version number).
// Hardware drivers have their own configuration code and revision
// numbers: kConfMajor, kConfMinor and kConfRevis
#define kVersMajor 1
#define kVersMinor 0
#define kVersRevis 0
//#define kVersTouch 20181027 // Last date core code touched

// **********************************************************************
// **  Include configuration file                                      **
// **********************************************************************

#include "config.h"

// set kHardID based on hardware defined in config.h
#if defined(Custom)
#define kHardID 0
#elif defined(Simulated_Z80)
#define kHardID 1
#elif defined(SCDevKit01_Z80)
#define kHardID 2
#elif defined(RC2014_Z80)
#define kHardID 3
#elif defined(SC101_Z80)
#define kHardID 4
#elif defined(LiNC80_Z80)
#define kHardID 5
#elif defined(TomsSBC_Z80)
#define kHardID 6
#elif defined(Z280RC_Z280)
#define kHardID 7
#elif defined(SC114_Z80)
#define kHardID 8
#elif defined(Z80SBCRC_Z80)
#define kHardID 9
#else
#error "no hardware define found, kHardID left undefined"
#endif

// (alpha) Size of shared buffers
#define kInputSize 0x80         // Size of kInputBuf
#define kStrSize   0x80         // Size of kStrBuf

// (alpha) Common constants
#define kNull      0x00         // Null character/byte (0x00)
#define kNewLine   0x05         // New line character (0x05)
#define kBackspace 0x08         // Backspace character (0x08)
#define kLinefeed  0x0a         // Line feed character (0x0A)
#define kReturn    0x0d         // Return character (0x0D)
#define kEscape    0x1b         // Escape character (0x1B)
#define kSpace     0x20         // Space character (0x20)
#define kQuote     0x22         // Quote character (0x22)
#define kApostroph 0x27         // Apostrophe character (0x27)
#define kComma     0x2c         // Comma character (0x2C)
#define kPeriod    0x2e         // Period character (0x2E)
#define kColon     0x3a         // Colon character (0x3A)
#define kSemicolon 0x3b         // Semicolon character (0x3B)
#define kDelete    0x7f         // Delete character (0x7F)

// The jump table contains a number of "JP nn" instructions which are
// used to redirect functions. Each entry in the table takes 3 bytes.
// The jump table is created in RAM on cold start of the monitor.
// (alpha) Jump table constants - jump number (0 to n)
#define kFnNMI     0x00         // Fn 0x00: non-maskable interrupt handler
#define kFnRST08   0x01         // Fn 0x01: restart 08 handler
#define kFnRST10   0x02         // Fn 0x02: restart 10 handler
#define kFnRST18   0x03         // Fn 0x03: restart 18 handler
#define kFnRST20   0x04         // Fn 0x04: restart 20 handler
#define kFnRST28   0x05         // Fn 0x05: restart 18 breakpoint
#define kFnRST30   0x06         // Fn 0x06: restart 30 API handler
#define kFnINT     0x07         // Fn 0x07: restart 38 interrupt handler
#define kFnConIn   0x08         // Fn 0x08: console input character
#define kFnConOut  0x09         // Fn 0x09: console output character
//#define FnConISta 0x0A        // Fn 0x0A: console get input status
//#define FnConOSta 0x0B        // Fn 0x0B: console get output status
#define kFnIdle    0x0C         // Fn 0x0C: jump to idle handler
#define kFnTimer1  0x0D         // Fn 0x0D: jump to timer 1 handler
#define kFnTimer2  0x0E         // Fn 0x0E: jump to timer 2 handler
#define kFnTimer3  0x0F         // Fn 0x0F: jump to timer 3 handler
//#define FnDevN    0x10        // Fn 0x10: device 1 to n input & output
#define kFnDev1In  0x10         // Fn 0x10: device 1 input
#define kFnDev1Out 0x11         // Fn 0x11: device 1 output
//#define kFnDev2In 0x12        // Fn 0x12: device 2 input
//#define FnDev2Out 0x13        // Fn 0x13: device 2 output
#define kFnDev3In  0x14         // Fn 0x14: device 3 input
//#define FnDev3Out 0x15        // Fn 0x15: device 3 output
//#define FnDev4In  0x16        // Fn 0x16: device 4 input
//#define FnDev4Out 0x17        // Fn 0x17: device 4 output
//#define FnDev5In  0x18        // Fn 0x18: device 5 input
//#define FnDev5Out 0x19        // Fn 0x19: device 5 output
#define kFnDev6In  0x1A         // Fn 0x1A: device 6 input
//#define FnDev6Out 0x1B        // Fn 0x1B: device 6 output

// (alpha) Message numbers
#define kMsgNull   0            // Null message
#define kMsgProdID 1            // Product identifier
#define kMsgDevice 2            // ="Devices:"
#define kMsgAbout  3            // About SCMonitor inc version
#define kMsgDevLst 4            // Device list
#define kMsgLstSys 4            // Last system message number

// (monitor) Message numbers
#define kMsgMonFst 0x20         // First monitor message
#define kMsgBadCmd +(kMsgMonFst+0) // Bad command
#define kMsgBadPar +(kMsgMonFst+1) // Bad parameter
#define kMsgSyntax +(kMsgMonFst+2) // Syntax error
#define kMsgBPSet  +(kMsgMonFst+3) // Breakpoint set
#define kMsgBPClr  +(kMsgMonFst+4) // Breakpoint cleared
#define kMsgBPFail +(kMsgMonFst+5) // Unable to set breakpoint here
#define kMsgHelp   +(kMsgMonFst+6) // Help text
#define kMsgNotAv  +(kMsgMonFst+7) // Feature not included
#define kMsgReady  +(kMsgMonFst+8) // Ready
#define kMsgFileEr +(kMsgMonFst+9) // File error
#define kMsgMonLst kMsgFileEr   // Last monitor message

//     **************************************************************
//     **                     Copyright notice                     **
//     **                                                          **
//     **  This software is very nearly 100% my own work so I am   **
//     **  entitled to  claim copyright and to grant licences to   **
//     **  others.                                                 **
//     **                                                          **
//     **  You are free to use this software for non-commercial    **
//     **  purposes provided it retains this copyright notice and  **
//     **  is clearly credited to me where appropriate.            **
//     **                                                          **
//     **  You are free to modify this software as you see fit     **
//     **  for your own use. You may also distribute derived       **
//     **  works provided they remain free of charge, are          **
//     **  appropriately credited and grant the same freedoms.     **
//     **                                                          **
//     **                    Stephen C Cousins                     **
//     **************************************************************
//
// Thanks to all those who have contributed to this software,
// particularly:
//
// Jon Langseth for all the input, testing and encouragement during
// the conversion and extension for the LiNC80 SBC1.
//
// Bill Shen for porting to his Z280RC system.
//
