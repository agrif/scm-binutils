add_executable(cf-test cf-test.S)
target_link_libraries(cf-test PRIVATE scm-api utilities compactflash-generic)
target_link_options(cf-test PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x8f00 -e Main)
z80_preprocess_sources(cf-test)
z80_print_size(cf-test)
z80_generate_binary(cf-test)
z80_generate_hex(cf-test)

# gc-sections removes this as unused, but the original doesn't
# keep it so we produce byte-identical products
target_link_options(cf-test PRIVATE -u cfRead)
