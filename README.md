# Small Computer Monitor for GNU Binutils

This is a version of the [Small Computer Monitor][scm] for z80 by Stephen C. Cousins,
modified to build with the GNU assembler and linker.

 [SCM]: https://smallcomputercentral.com/small-computer-monitor/

It also includes code originally by [Grant Searle][searle] and others. Attribution is
included in the sources as appropriate.

 [searle]: http://www.searle.wales/

## Building

You must have a version of [GNU Binutils][binutils] built for z80 ELF somewhere in
your PATH, with names like `z80-unknown-elf-as`. If these are not on your PATH, you
can set the `Z80_TOOLCHAIN_PATH` CMake variable to point their prefix.

 [binutils]: https://www.gnu.org/software/binutils/

~~~~{.sh}
mkdir build
cd build
cmake ..
make
~~~~

----

~~~~
**************************************************************
**                     Copyright notice                     **
**                                                          **
**  This software is very nearly 100% my own work so I am   **
**  entitled to  claim copyright and to grant licences to   **
**  others.                                                 **
**                                                          **
**  You are free to use this software for non-commercial    **
**  purposes provided it retains this copyright notice and  **
**  is clearly credited to me where appropriate.            **
**                                                          **
**  You are free to modify this software as you see fit     **
**  for your own use. You may also distribute derived       **
**  works provided they remain free of charge, are          **
**  appropriately credited and grant the same freedoms.     **
**                                                          **
**                    Stephen C Cousins                     **
**************************************************************
~~~~
