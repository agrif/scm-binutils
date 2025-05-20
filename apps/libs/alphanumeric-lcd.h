// **********************************************************************
// **  Alphanumeric LCD support                  by Stephen C Cousins  **
// **********************************************************************
// converted to GNU binutils by agrif
//
// **  Written as a Small Computer Monitor App
// **  Version 0.1 SCC 2018-05-16
// **  www.scc.me.uk

// **********************************************************************
// **  Constants
// **********************************************************************

// These used to be defined as symbols, but relocations can't handle it
#define kLCDBitRS   2              // Port bit for LCD RS signal
#define kLCDBitE    3              // Port bit for LCD E signal
#define kLCDWidth   20             // Width in characters

// Cursor position values for the start of each line
#define kLCD_Line1  0x00
#define kLCD_Line2  0x40
#define kLCD_Line3  +(kLCD_Line1+kLCDWidth)
#define kLCD_Line4  +(kLCD_Line1+kLCDWidth)

// Instructions to send as A register to fLCD_Inst
#define kLCD_Clear  0b00000001     // LCD clear
#define kLCD_Off    0b00001000     // LCD off
#define kLCD_On     0b00001100     // LCD on, no cursor or blink
#define kLCD_Under  0b00001110     // LCD on, cursor = underscore
#define kLCD_Blink  0b00001101     // LCD on, cursor = blink block
#define kLCD_Both   0b00001111     // LCD on, cursor = under+blink

// Constants used by this code module
//#define kLCD_Clr  0b00000001     // LCD command: Clear display
#define kLCD_Pos    0b10000000     // LCD command: Position cursor
#define kLCD_Def    0b01000000     // LCD command: Define character
