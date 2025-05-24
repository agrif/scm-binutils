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
        *(.init .init.*)
    } > PROGRAM

    .data :
    {
        *(.data .data.*)
    } > PROGRAM AT > WORKSPC

    .bss (NOLOAD) :
    {
        *(.bss .bss.*)
        *(COMMON)
    } > WORKSPC

    .text :
    {
        *(.text .text.*)
    } > PROGRAM
}
