ENTRY(ColdStrt);

MEMORY
{
    /* These lengths correspond to the max lengths given in config.h */
    CODE (rx) : ORIGIN = kCode, LENGTH = 0x1e00
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
