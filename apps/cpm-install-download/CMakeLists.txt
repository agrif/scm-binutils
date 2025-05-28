add_executable(cpm-install-download-linc80 cpm-install-download-linc80.S)
target_link_options(cpm-install-download-linc80 PRIVATE -Ttext=0x8000 -Tdata=0x4100 --entry=Main)
z80_embed_alternate(cpm-install-download-linc80 cpm-install-download-linc80.S
  DOWNLOAD2_BIN download "2.bin")
z80_executable(cpm-install-download-linc80)

add_executable(cpm-install-download-rc2014 cpm-install-download-rc2014.S)
target_link_options(cpm-install-download-rc2014 PRIVATE -Ttext=0x8000 --entry=Main)
z80_embed_alternate(cpm-install-download-rc2014 cpm-install-download-rc2014.S
  DOWNLOAD2_BIN download "2.bin")
z80_executable(cpm-install-download-rc2014)
