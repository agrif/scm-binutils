// **********************************************************************
// **  Compact Flash support                     by Stephen C Cousins  **
// **********************************************************************
// converted to GNU binutils by agrif
//
// **  Written as a module to be included in Small Computer Monitor Apps
// **  Version 0.4 SCC 2018-05-20
// **  www.scc.me.uk

// **********************************************************************
// **  Constants
// **********************************************************************

// CF registers
#define CF_BASE     0x10
#define CF_DATA     (CF_BASE+0)
#define CF_FEATURE  (CF_BASE+1)
#define CF_ERROR    (CF_BASE+1)
#define CF_SEC_CNT  (CF_BASE+2)
#define CF_SECTOR   (CF_BASE+3)
#define CF_CYL_LOW  (CF_BASE+4)
#define CF_CYL_HI   (CF_BASE+5)
#define CF_HEAD     (CF_BASE+6)
#define CF_STATUS   (CF_BASE+7)
#define CF_COMMAND  (CF_BASE+7)
#define CF_LBA0     (CF_BASE+3)
#define CF_LBA1     (CF_BASE+4)
#define CF_LBA2     (CF_BASE+5)
#define CF_LBA3     (CF_BASE+6)

// CF Features
#define CF_8BIT     1
#define CF_NOCACHE  0x82           // ???

// CF Commands
#define CF_RD_SEC   0x20
#define CF_WR_SEC   0x30
#define CF_DIAGNOSE 0x90
#define CF_IDENTIFY 0xEC
#define CF_SET_FEAT 0xEF

// CF Error numbers
#define CF_NoErr    0              // No error
#define CF_NotPres  1              // Compact flash card not present
#define CF_Timeout  2              // Compact flash time out error
#define CF_ErrFlag  3              // Compact flash set its error flag
#define CF_Verify   4              // Compact flash verify error
#define CF_Correct  5              // Compact flash reports correctable error
#define CF_Write    6              // Compact flash reports a write fault
