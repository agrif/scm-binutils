ENTRY(ColdStrt);

MEMORY
{
    /* These lengths *should* correspond to the max lengths given in config.h
       however, some ports don't fit.
       Use 0x1f00 so at least 0x100 remains for the ROMFS
     */
    CODE    (rx) : ORIGIN = kCode, LENGTH = 0x1f00
    ROMINFO (r)  : ORIGIN = ORIGIN(CODE) + LENGTH(CODE), LENGTH = kROMLimit - ORIGIN(ROMINFO)
    DATA    (wx) : ORIGIN = kData, LENGTH = 0x0400
}

SECTIONS
{
    .text :
    {
        *(.text .text.* .rodata .rodata.*);
        EndOfMonitor = .;
    } > CODE

    .data :
    {
        *(.data .data.*)
    } > DATA

    .bss (NOLOAD) :
    {
        *(.bss .bss.*)
        *(COMMON)
    } > DATA

    .rominfo (TYPE = SHT_PROGBITS) :
    {
        *(.rominfo .rominfo.*)

        /* fill to 0x10 boundary */
        . = ALIGN(0x10);
    } > ROMINFO =0xff

    RomFilesStart = ORIGIN(ROMINFO) + LENGTH(ROMINFO) - SIZEOF(.romfiles);

    .romfiles RomFilesStart (TYPE = SHT_PROGBITS) :
    {
        *(.romfiles .romfiles.*)
    } > ROMINFO
}

ASSERT((SIZEOF(.data) == 0),
"ERROR(link.x): .data is not supported");

ASSERT((SIZEOF(.romfiles) % 0x10 == 0),
"ERROR(link.x): .romfiles size not a multiple of the file entry size");
