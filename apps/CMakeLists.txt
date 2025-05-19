add_subdirectory(libs)

#
# cf-format
#

add_executable(cf-format cf-format.S)
target_link_libraries(cf-format PRIVATE scm-api utilities compactflash)
target_link_options(cf-format PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 -e Main)
z80_executable(cf-format)

# keep this symbol so we produce output identical to original
target_link_options(cf-format PRIVATE "SHELL:-u cfRead" "SHELL:-u cfDiagnose")

add_executable(cf-format-z280rc cf-format.S)
target_link_libraries(cf-format-z280rc PRIVATE scm-api utilities compactflash-z280rc)
target_link_options(cf-format-z280rc PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 -e Main)
z80_executable(cf-format-z280rc)

# keep this symbol so we produce output identical to original
target_link_options(cf-format-z280rc PRIVATE "SHELL:-u cfRead" "SHELL:-u cfDiagnose")

#
# cf-info
#

add_executable(cf-info cf-info.S)
target_link_libraries(cf-info PRIVATE scm-api utilities compactflash)
target_link_options(cf-info PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 -e Main)
z80_executable(cf-info)

# keep this symbol so we produce output identical to original
target_link_options(cf-info PRIVATE -u cfRead)

add_executable(cf-info-z280rc cf-info.S)
target_link_libraries(cf-info-z280rc PRIVATE scm-api utilities compactflash-z280rc)
target_link_options(cf-info-z280rc PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 -e Main)
z80_executable(cf-info-z280rc)

# keep this symbol so we produce output identical to original
target_link_options(cf-info-z280rc PRIVATE -u cfRead)

#
# cf-test
#

add_executable(cf-test cf-test.S)
target_link_libraries(cf-test PRIVATE scm-api utilities compactflash)
target_link_options(cf-test PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x8f00 -e Main)
z80_executable(cf-test)

# keep this symbol so we produce output identical to original
target_link_options(cf-test PRIVATE -u cfRead)

add_executable(cf-test-z280rc cf-test.S)
target_link_libraries(cf-test-z280rc PRIVATE scm-api utilities compactflash-z280rc)
target_link_options(cf-test-z280rc PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x8f00 -e Main)
z80_executable(cf-test-z280rc)

# keep this symbol so we produce output identical to original
target_link_options(cf-test-z280rc PRIVATE -u cfRead)

#
# memfill
#

add_executable(memfill memfill.s)
target_link_options(memfill PRIVATE -Ttext=0x8000 -e Test)
z80_executable(memfill)

#
# memtest
#

add_executable(memtest memtest.s)
target_link_options(memtest PRIVATE -Ttext=0x8000 -e Test)
z80_executable(memtest)
