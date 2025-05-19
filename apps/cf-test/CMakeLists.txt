add_executable(cf-test cf-test.S)
target_link_libraries(cf-test PRIVATE scm-api utilities compactflash)
target_link_options(cf-test PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x8f00 -e Main)
z80_preprocess_sources(cf-test)
z80_print_size(cf-test)
z80_generate_binary(cf-test)
z80_generate_hex(cf-test)

# gc-sections removes this as unused, but the original doesn't
# keep it so we produce byte-identical products
target_link_options(cf-test PRIVATE -u cfRead)

add_executable(cf-test-z280rc cf-test.S)
target_link_libraries(cf-test-z280rc PRIVATE scm-api utilities compactflash-z280rc)
target_link_options(cf-test-z280rc PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x8f00 -e Main)
z80_preprocess_sources(cf-test-z280rc)
z80_print_size(cf-test-z280rc)
z80_generate_binary(cf-test-z280rc)
z80_generate_hex(cf-test-z280rc)

# gc-sections removes this as unused, but the original doesn't
# keep it so we produce byte-identical products
target_link_options(cf-test-z280rc PRIVATE -u cfRead)
