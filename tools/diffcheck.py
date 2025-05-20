#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import tempfile

TABLE = {
    'apps/alphanumeric-lcd-linc80.hex': 'SCMonitor/Apps/Alphanumeric_LCD/SCMon_LiNC80_alphanumeric_LCD_code8000.hex',
    'apps/alphanumeric-lcd-rc2014.hex': 'SCMonitor/Apps/Alphanumeric_LCD/SCMon_RC2014_alphanumeric_LCD_code8000.hex',
    'apps/alphanumeric-lcd-z280rc.hex': 'SCMonitor/Apps/Alphanumeric_LCD/SCMon_Z280RC_alphanumeric_LCD_code8000.hex',
    'apps/cf-format.hex': 'SCMonitor/Apps/Compact_flash_format/SCMon_CF_Format_code8000.hex',
    'apps/cf-format-z280rc.hex': 'SCMonitor/Apps/Compact_flash_format/SCMon_CF_Format_Z280RC_code8000.hex',
    'apps/cf-info.hex': 'SCMonitor/Apps/Compact_flash_information/SCMon_CF_Info_code8000.hex',
    'apps/cf-info-z280rc.hex': 'SCMonitor/Apps/Compact_flash_information/SCMon_CF_Info_Z280RC_code8000.hex',
    'apps/cf-test.hex': 'SCMonitor/Apps/Compact_flash_test/SCMon_CF_Test_code8000.hex',
    'apps/cf-test-z280rc.hex': 'SCMonitor/Apps/Compact_flash_test/SCMon_CF_Test_Z280RC_code8000.hex',
    'apps/cpm-install-download/cpm-install-download-linc80.hex': 'SCMonitor/Apps/CPM_install_Download.com/SCMon_LiNC80_Download_code8000.hex',
    'apps/cpm-install-download/cpm-install-download-rc2014.hex': 'SCMonitor/Apps/CPM_install_Download.com/SCMon_RC2014_Download_code8000.hex',
    'apps/cpm-loader.hex': 'SCMonitor/Apps/CPM_load_from_compact_flash/SCMon_CPM_loader_code8000.hex',
    'apps/memfill.hex': 'SCMonitor/Apps/Memory_fill/SCMon_MemFill_code8000.hex',
    'apps/memtest.hex': 'SCMonitor/Apps/Memory_test/SCMon_MemTest_code8000.hex',
    'cpm-apps/download2.hex': 'SCMonitor/Apps/CPM_install_Download.com/Includes/DOWNLOAD2.hex',
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

def find_start_address(ihex):
    s = subprocess.run(objdump + ['-b', 'ihex', '-s', ihex], check=True, stdout=subprocess.PIPE, encoding='utf-8')

    start_addr = None
    for line in s.stdout.splitlines():
        line = line.strip()
        try:
            addr = line.split(maxsplit=1)[0]
        except IndexError:
            continue
        try:
            addr = int(addr, 16)
        except ValueError:
            continue
        if start_addr is None or addr < start_addr:
            start_addr = addr

    if start_addr is None:
        raise RuntimeError('start address not found')

    return start_addr

def hex_diff(path_a, path_b, name_a, name_b, disassemble=False):
    with tempfile.TemporaryDirectory(prefix='diffcheck.') as d:
        print(name_a, name_b)

        bin_a = ihex_to_bin(path_a, os.path.join(d, 'a.bin'))
        bin_b = ihex_to_bin(path_b, os.path.join(d, 'b.bin'))

        start_a = find_start_address(path_a)
        start_b = find_start_address(path_b)

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
