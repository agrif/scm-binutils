#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import tempfile

TABLE = {
    'apps/cf-format.hex': 'SCMonitor/Apps/Compact_flash_format/SCMon_CF_Format_code8000.hex',
    'apps/cf-format-z280rc.hex': 'SCMonitor/Apps/Compact_flash_format/SCMon_CF_Format_Z280RC_code8000.hex',
    'apps/cf-info.hex': 'SCMonitor/Apps/Compact_flash_information/SCMon_CF_Info_code8000.hex',
    'apps/cf-info-z280rc.hex': 'SCMonitor/Apps/Compact_flash_information/SCMon_CF_Info_Z280RC_code8000.hex',
    'apps/cf-test.hex': 'SCMonitor/Apps/Compact_flash_test/SCMon_CF_Test_code8000.hex',
    'apps/cf-test-z280rc.hex': 'SCMonitor/Apps/Compact_flash_test/SCMon_CF_Test_Z280RC_code8000.hex',
    'apps/memfill.hex': 'SCMonitor/Apps/Memory_fill/SCMon_MemFill_code8000.hex',
    'apps/memtest.hex': 'SCMonitor/Apps/Memory_test/SCMon_MemTest_code8000.hex',
}

# some of the packaged hex files aren't up to date
# you must rebuild them for these diffs to work
# open the file in SCWorkshop.exe, configure it, build it, then
# copy Output/IntelHex.hex to the correct location
FILES_NEEDING_REBUILD = [
    'SCMonitor/Apps/Compact_flash_test/SCMon_CF_Test_Z280RC_code8000.hex',
]

objcopy = ['z80-unknown-elf-objcopy']
objdump = ['z80-unknown-elf-objdump', '-m', 'z80']
diff = ['diff']

def ihex_to_bin(ihex, binary):
    subprocess.run(objcopy + ['-I', 'ihex', '-O', 'binary', ihex, binary], check=True)
    return binary

def bin_to_objdump(binary, output, flags, start=0x8000):
    s = subprocess.run(objdump + ['-b', 'binary', '--adjust-vma', str(start)] + flags + [binary], check=True, stdout=subprocess.PIPE, encoding='utf-8')
    with open(output, 'w') as f:
        for line in s.stdout.splitlines():
            if line.startswith(binary + ':'):
                line = 'image.bin:' + line[len(binary) + 1:]
            print(line, file=f)
    return output

def bin_to_hexdump(binary, hexdump, start=0x8000):
    return bin_to_objdump(binary, hexdump, ['-s'], start=start)

def bin_to_asm(binary, asm, start=0x8000):
    return bin_to_objdump(binary, asm, ['-D'], start=start)

def diff_files(a, b):
    c = subprocess.run(diff + ['-u', a, b])
    return c.returncode

def hex_diff(path_a, path_b, name_a, name_b, disassemble=False):
    with tempfile.TemporaryDirectory(prefix='diffcheck.') as d:
        print(name_a, name_b)

        bin_a = ihex_to_bin(path_a, os.path.join(d, 'a.bin'))
        bin_b = ihex_to_bin(path_b, os.path.join(d, 'b.bin'))

        start_a = 0x8000
        start_b = 0x8000

        if disassemble:
            asm_a = bin_to_asm(bin_a, os.path.join(d, 'a.lst'), start=start_a)
            asm_b = bin_to_asm(bin_b, os.path.join(d, 'b.lst'), start=start_b)
            return diff_files(asm_a, asm_b)
        else:
            dump_a = bin_to_hexdump(bin_a, os.path.join(d, 'a.hexdump'), start=start_a)
            dump_b = bin_to_hexdump(bin_b, os.path.join(d, 'b.hexdump'), start=start_b)
            return diff_files(dump_a, dump_b)

def main():
    our_file = os.path.abspath(__file__)
    our_source = os.path.split(os.path.split(our_file)[0])[0]
    our_build_default = os.path.join(our_source, 'build')

    parser = argparse.ArgumentParser()
    parser.add_argument('--disassemble', '-d', action='store_true')
    parser.add_argument('scm_source', metavar='SCM-SOURCE')
    parser.add_argument('our_build', metavar='OUR-BUILD', default=our_build_default, nargs='?')

    args = parser.parse_args()

    error = False
    rebuild_files = []
    for ours, scm in TABLE.items():
        path_ours = os.path.join(args.our_build, ours)
        path_scm = os.path.join(args.scm_source, scm)
        if hex_diff(path_scm, path_ours, scm, ours, disassemble=args.disassemble):
            if scm in FILES_NEEDING_REBUILD:
                rebuild_files.append(scm)
            error = True

    if rebuild_files:
        print('WARN: the following original files may need rebuilt:')
        for scm in rebuild_files:
            print(' ', scm)

    if error:
        print('ERR: differences found..')
        sys.exit(1)
    print('no differences found.')

if __name__ == '__main__':
    main()
