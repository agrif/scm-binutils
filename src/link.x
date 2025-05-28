ENTRY(ColdStrt);

MEMORY
{
    /* These lengths *should* correspond to the max lengths given in config.h */
    CODE (rx) : ORIGIN = kCode, LENGTH = 0x1f00
    ROMFS (r) : ORIGIN = ORIGIN(CODE) + LENGTH(CODE), LENGTH = 0x100
    DATA (wx) : ORIGIN = kData, LENGTH = 0x0400
}

SECTIONS
{
    .text :
    {
        StartOfMonitor = .;
        *(.text .text.* .rodata .rodata.*);
        EndOfMonitor = .;

        /* always fill region */
        . = LENGTH(CODE);
    } > CODE

    .romfs (TYPE = SHT_PROGBITS) :
    {
        /* dummy romfs */
        BYTE(0)
        . = LENGTH(ROMFS);
    } > ROMFS

    .data :
    {
        *(.data .data.*)
    } > DATA

    .bss (NOLOAD) :
    {
        *(.bss .bss.*)
        *(COMMON)
    } > DATA
}

ASSERT((SIZEOF(.data) == 0),
"ERROR(link.x): .data is not supported");
