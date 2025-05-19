add_executable(cf-info cf-info.S)
target_link_libraries(cf-info PRIVATE scm-api utilities compactflash)
target_link_options(cf-info PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 -e Main)
z80_preprocess_sources(cf-info)
z80_print_size(cf-info)
z80_generate_binary(cf-info)
z80_generate_hex(cf-info)

# gc-sections removes this as unused, but the original doesn't
# keep it so we produce byte-identical products
target_link_options(cf-info PRIVATE -u cfRead)

add_executable(cf-info-z280rc cf-info.S)
target_link_libraries(cf-info-z280rc PRIVATE scm-api utilities compactflash-z280rc)
target_link_options(cf-info-z280rc PRIVATE --gc-sections -Ttext=0x8000 -Tdata=0x9000 -e Main)
z80_preprocess_sources(cf-info-z280rc)
z80_print_size(cf-info-z280rc)
z80_generate_binary(cf-info-z280rc)
z80_generate_hex(cf-info-z280rc)

# gc-sections removes this as unused, but the original doesn't
# keep it so we produce byte-identical products
target_link_options(cf-info-z280rc PRIVATE -u cfRead)
