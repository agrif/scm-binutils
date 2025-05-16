#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import tempfile

TABLE = {
    'apps/memtest/memtest.hex': 'SCMonitor/Apps/Memory_test/SCMon_MemTest_code8000.hex',
}

def ihex_to_bin(ihex, binary):
    subprocess.run(['objcopy', '-I', 'ihex', '-O', 'binary', ihex, binary], check=True)
    return binary

def bin_to_hexdump(binary, hexdump):
    with open(hexdump, 'w') as f:
        subprocess.run(['hexdump', '-C', binary], check=True, stdout=f)
    return hexdump

def diff_files(a, b):
    c = subprocess.run(['diff', '-u', a, b])
    return c.returncode

def hex_diff(path_a, path_b, name_a, name_b):
    with tempfile.TemporaryDirectory(prefix='diffcheck.') as d:
        bin_a = ihex_to_bin(path_a, os.path.join(d, 'a.bin'))
        bin_b = ihex_to_bin(path_b, os.path.join(d, 'b.bin'))
        dump_a = bin_to_hexdump(bin_a, os.path.join(d, 'a.hexdump'))
        dump_b = bin_to_hexdump(bin_b, os.path.join(d, 'b.hexdump'))
        print(name_a, name_b)
        return diff_files(dump_a, dump_b)

def main():
    our_file = os.path.abspath(__file__)
    our_source = os.path.split(os.path.split(our_file)[0])[0]
    our_build_default = os.path.join(our_source, 'build')

    parser = argparse.ArgumentParser()
    parser.add_argument('scm_source', metavar='SCM-SOURCE')
    parser.add_argument('our_build', metavar='OUR-BUILD', default=our_build_default, nargs='?')

    args = parser.parse_args()

    error = False
    for ours, scm in TABLE.items():
        path_ours = os.path.join(args.our_build, ours)
        path_scm = os.path.join(args.scm_source, scm)
        if hex_diff(path_scm, path_ours, scm, ours):
            error = True

    if error:
        print('ERR: differences found..')
        sys.exit(1)
    print('no differences found.')

if __name__ == '__main__':
    main()
