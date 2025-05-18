// **********************************************************************
// **  Small Computer Monitor API                by Stephen C Cousins  **
// **********************************************************************
// converted to GNU binutils by agrif
//
// **  Written as a module to be included in Small Computer Monitor Apps
// **  Version 0.2 SCC 2018-05-15
// **  www.scc.me.uk

// **********************************************************************
// **  Constants
// **********************************************************************

// Character constants
#define kNull       0              // Null character/byte (0x00)
#define kNewLine    5              // New line character (0x05)
#define kBackspace  8              // Backspace character (0x08)
#define kLinefeed   10             // Line feed character (0x0A)
#define kLF         10             // Line feed character (0x0A)
#define kReturn     13             // Return character (0x0D)
#define kCR         13             // Return character (0x0D)
#define kEscape     27             // Escape character (0x1B)
#define kSpace      32             // Space character (0x20)
#define kQuote      34             // Quotation mark (0x22)
#define kApostroph  39             // Apostrophe character (0x27)
#define kComma      44             // Comma character (0x2C)
#define kPeriod     46             // Period character (0x2E)
#define kColon      58             // Colon character (0x3A)
#define kSemicolon  59             // Semicolon character (0x3B)
#define kDelete     127            // Delete character (0x7F)

// aClaimJumpTab: Jump table entry numbers
#define kFnNMI      0x00           // Fn 0x00: non-maskable interrupt handler
#define kFnRST08    0x01           // Fn 0x01: restart 08 handler
#define kFnRST10    0x02           // Fn 0x02: restart 10 handler
#define kFnRST18    0x03           // Fn 0x03: restart 18 handler
#define kFnRST20    0x04           // Fn 0x04: restart 20 handler
#define kFnRST28    0x05           // Fn 0x05: restart 18 breakpoint
#define kFnRST30    0x06           // Fn 0x06: restart 30 API handler
#define kFnINT      0x07           // Fn 0x07: restart 38 interrupt handler
#define kFnConIn    0x08           // Fn 0x08: console input character
#define kFnConOut   0x09           // Fn 0x09: console output character
//#define FnConISta  0x0A          // Fn 0x0A: console get input status
//#define FnConOSta  0x0B          // Fn 0x0B: console get output status
#define kFnIdle     0x0C           // Fn 0x0C: Jump to idle handler
#define kFnTimer1   0x0D           // Fn 0x0D: Jump to timer 1 handler
#define kFnTimer2   0x0E           // Fn 0x0E: Jump to timer 2 handler
#define kFnTimer3   0x0F           // Fn 0x0F: Jump to timer 3 handler
#define kFnDev1In   0x10           // Fn 0x10: device 1 input
#define kFnDev1Out  0x11           // Fn 0x11: device 1 output
#define kFnDev2In   0x12           // Fn 0x12: device 2 input
#define FnDev2Out   0x13           // Fn 0x13: device 2 output
#define kFnDev3In   0x14           // Fn 0x14: device 3 input
#define FnDev3Out   0x15           // Fn 0x15: device 3 output
#define FnDev4In    0x16           // Fn 0x16: device 4 input
#define FnDev4Out   0x17           // Fn 0x17: device 4 output
#define FnDev5In    0x18           // Fn 0x18: device 5 input
#define FnDev5Out   0x19           // Fn 0x19: device 5 output
#define FnDev6In    0x1A           // Fn 0x1A: device 6 input
#define FnDev6Out   0x1B           // Fn 0x1B: device 6 output

// aOutputSysMsg: Message numbers
#define kMsgNull    0x00           // Null message
#define kMsgProdID  0x01           // "Small Computer Monitor "
#define kMsgDevice  0x02           // "Devices detected:"
#define kMsgAbout   0x03           // About SCMonitor inc version
#define kMsgDevLst  0x04           // Device list
#define kMsgMonFst  0x20           // First monitor message
#define kMsgBadCmd  (kMsgMonFst+0) // "Bad command"
#define kMsgBadPar  (kMsgMonFst+1) // "Bad parameter"
#define kMsgSyntax  (kMsgMonFst+2) // "Syntax error"
#define kMsgBPSet   (kMsgMonFst+3) // "Breakpoint set"
#define kMsgBPClr   (kMsgMonFst+4) // "Breakpoint cleared"
#define kMsgBPFail  (kMsgMonFst+5) // "Unable to set breakpoint here"
#define kMsgHelp    (kMsgMonFst+6) // Help text
#define kMsgNotAv   (kMsgMonFst+7) // "Feature not included"
#define kMsgReady   (kMsgMonFst+8) // "Ready"
#define kMsgFileEr  (kMsgMonFst+9) // "File error"
