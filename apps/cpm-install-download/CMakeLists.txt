# convert download2.hex to download2.bin
z80_get_alternate_gen(DOWNLOAD2_HEX download "2.hex")
set(DOWNLOAD2_BIN "${CMAKE_CURRENT_BINARY_DIR}/download2.bin")
add_custom_command(
  COMMAND ${CMAKE_OBJCOPY} -O binary -I ihex
  "${DOWNLOAD2_HEX}"
  "${DOWNLOAD2_BIN}"
  VERBATIM
  DEPENDS download
  OUTPUT "${DOWNLOAD2_BIN}"
  COMMENT "Generating download2.bin"
)

# say that compiling these sources requires download2.bin
set_source_files_properties(
  # careful: preprocessed sources get target-name.s as names
  cpm-install-download-linc80-cpm-install-download-linc80.s
  cpm-install-download-rc2014-cpm-install-download-rc2014.s
  PROPERTIES OBJECT_DEPENDS "${DOWNLOAD2_BIN}")

add_executable(cpm-install-download-linc80 cpm-install-download-linc80.S)
target_link_options(cpm-install-download-linc80 PRIVATE -Ttext=0x8000 -Tdata=0x4100 --entry=Main)
target_compile_definitions(cpm-install-download-linc80 PRIVATE DOWNLOAD2_BIN="${DOWNLOAD2_BIN}")
z80_executable(cpm-install-download-linc80)

add_executable(cpm-install-download-rc2014 cpm-install-download-rc2014.S)
target_link_options(cpm-install-download-rc2014 PRIVATE -Ttext=0x8000 --entry=Main)
target_compile_definitions(cpm-install-download-rc2014 PRIVATE DOWNLOAD2_BIN="${DOWNLOAD2_BIN}")
z80_executable(cpm-install-download-rc2014)
