add_subdirectory(libs)

add_subdirectory(cpm-install-download)
add_subdirectory(msbasic)

#
# alphanumeric-lcd
#

# LINC80 RC2014 Z280RC

add_executable(alphanumeric-lcd-linc80 alphanumeric-lcd.S)
target_link_libraries(alphanumeric-lcd-linc80 PRIVATE scm-api alphanumeric-lcd)
target_link_options(alphanumeric-lcd-linc80 PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9f00 --entry=Main)
target_compile_definitions(alphanumeric-lcd-linc80 PRIVATE LINC80)
z80_executable(alphanumeric-lcd-linc80)

# reorder this symbol to appear first
z80_keep_symbols(alphanumeric-lcd-linc80 aDelayInMS)

add_executable(alphanumeric-lcd-rc2014 alphanumeric-lcd.S)
target_link_libraries(alphanumeric-lcd-rc2014 PRIVATE scm-api alphanumeric-lcd)
target_link_options(alphanumeric-lcd-rc2014 PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9f00 --entry=Main)
target_compile_definitions(alphanumeric-lcd-rc2014 PRIVATE RC2014)
z80_executable(alphanumeric-lcd-rc2014)

# reorder this symbol to appear first
z80_keep_symbols(alphanumeric-lcd-rc2014 aDelayInMS)

add_executable(alphanumeric-lcd-z280rc alphanumeric-lcd.S)
target_link_libraries(alphanumeric-lcd-z280rc PRIVATE scm-api alphanumeric-lcd)
target_link_options(alphanumeric-lcd-z280rc PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9f00 --entry=Main)
target_compile_definitions(alphanumeric-lcd-z280rc PRIVATE Z280RC)
z80_executable(alphanumeric-lcd-z280rc)

# reorder this symbol to appear first
z80_keep_symbols(alphanumeric-lcd-z280rc aDelayInMS)

#
# cf-format
#

add_executable(cf-format cf-format.S)
target_link_libraries(cf-format PRIVATE scm-api utilities compactflash)
target_link_options(cf-format PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 --entry=Main)
z80_executable(cf-format)

# keep this symbol so we produce output identical to original
z80_keep_symbols(cf-format cfRead cfDiagnose)

add_executable(cf-format-z280rc cf-format.S)
target_link_libraries(cf-format-z280rc PRIVATE scm-api utilities compactflash-z280rc)
target_link_options(cf-format-z280rc PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 --entry=Main)
z80_executable(cf-format-z280rc)

# keep this symbol so we produce output identical to original
z80_keep_symbols(cf-format-z280rc cfRead cfDiagnose)

#
# cf-info
#

add_executable(cf-info cf-info.S)
target_link_libraries(cf-info PRIVATE scm-api utilities compactflash)
target_link_options(cf-info PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 --entry=Main)
z80_executable(cf-info)

# keep this symbol so we produce output identical to original
z80_keep_symbols(cf-info cfRead)

add_executable(cf-info-z280rc cf-info.S)
target_link_libraries(cf-info-z280rc PRIVATE scm-api utilities compactflash-z280rc)
target_link_options(cf-info-z280rc PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 --entry=Main)
z80_executable(cf-info-z280rc)

# keep this symbol so we produce output identical to original
z80_keep_symbols(cf-info-z280rc cfRead)

#
# cf-test
#

add_executable(cf-test cf-test.S)
target_link_libraries(cf-test PRIVATE scm-api utilities compactflash)
target_link_options(cf-test PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x8f00 --entry=Main)
z80_executable(cf-test)

# keep this symbol so we produce output identical to original
z80_keep_symbols(cf-test cfRead)

add_executable(cf-test-z280rc cf-test.S)
target_link_libraries(cf-test-z280rc PRIVATE scm-api utilities compactflash-z280rc)
target_link_options(cf-test-z280rc PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x8f00 --entry=Main)
z80_executable(cf-test-z280rc)

# keep this symbol so we produce output identical to original
z80_keep_symbols(cf-test-z280rc cfRead)

#
# cpm-loader
#

add_executable(cpm-loader cpm-loader.S)
target_link_options(cpm-loader PRIVATE -Ttext=0x8000 -Tdata=0x8800 --entry=Main)
target_include_directories(cpm-loader PRIVATE $<TARGET_PROPERTY:compactflash,INTERFACE_INCLUDE_DIRECTORIES>)
z80_executable(cpm-loader)

#
# memfill
#

add_executable(memfill memfill.s)
target_link_options(memfill PRIVATE -Ttext=0x8000 --entry=Test)
z80_executable(memfill)

#
# memtest
#

add_executable(memtest memtest.s)
target_link_options(memtest PRIVATE -Ttext=0x8000 --entry=Test)
z80_executable(memtest)
