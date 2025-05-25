ENTRY(COLD);

MEMORY
{
    PROGRAM (rx) : ORIGIN = kORG, LENGTH = 8K
    WORKSPC (wx) : ORIGIN = kWRKSPC, LENGTH = 512
}

SECTIONS
{
    .init :
    {
        *(.init .init.* .init.rodata .init.rodata.*)
    } > PROGRAM

    .data :
    {
        INITAB = LOADADDR(.data);

        *(.data .data.*);

        INITLE = SIZEOF(.data);
        INITBE = INITAB + INITLE;
    } > WORKSPC AT > PROGRAM

    .bss (NOLOAD) :
    {
        *(.bss .bss.*)
        *(COMMON)
    } > WORKSPC

    .text :
    {
        *(.rodata .rodata.* .text .text.*);
    } > PROGRAM
}
