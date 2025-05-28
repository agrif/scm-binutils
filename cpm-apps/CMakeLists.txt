add_executable(download download.S)
z80_executable(download)

# download2.hex is moved up from 0 to 0x4000 and padded out (for some reason)
z80_generate_objcopy(download "2.hex" -O ihex --adjust-vma 0x4000 --pad-to 0x42c0 --gap-fill 0xff)
z80_generate_objcopy(download "2.bin" -O binary --adjust-vma 0x4000 --pad-to 0x42c0 --gap-fill 0xff)
