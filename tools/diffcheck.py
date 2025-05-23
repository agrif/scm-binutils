#!/usr/bin/env python3

import argparse
import dataclasses
import hashlib
import json
import os
import subprocess
import sys
import tempfile

OBJCOPY = ['z80-unknown-elf-objcopy']
OBJDUMP = ['z80-unknown-elf-objdump', '-m', 'z80']
DIFF = ['diff']

DEFAULT_BASES = {
    'build': 'build',
    'scm': 'local/scm-1.0.0',
}

@dataclasses.dataclass
class Tools:
    objcopy: list[str] = dataclasses.field(default_factory= lambda: OBJCOPY[:])
    objdump: list[str] = dataclasses.field(default_factory= lambda: OBJDUMP[:])
    diff: list[str] = dataclasses.field(default_factory= lambda: DIFF[:])

    def ihex_to_bin(self, ihex, binary):
        subprocess.run(
            self.objcopy + ['-I', 'ihex', '-O', 'binary', ihex, binary],
            check=True)
        return binary

    def bin_to_objdump(self, binary, output, flags, start=0x8000):
        s = subprocess.run(
            self.objdump + ['-b', 'binary', '--adjust-vma', str(start)] + flags + [binary],
            check=True, stdout=subprocess.PIPE, encoding='utf-8')
        with open(output, 'w') as f:
            for line in s.stdout.splitlines():
                if line.startswith(binary + ':'):
                    line = 'image.bin:' + line[len(binary) + 1:]
                print(line, file=f)
        return output

    def bin_to_hexdump(self, binary, hexdump, start=0x8000):
        return self.bin_to_objdump(binary, hexdump, ['-s'], start=start)

    def bin_to_asm(self, binary, asm, start=0x8000):
        return self.bin_to_objdump(binary, asm, ['-D'], start=start)

    def diff_files(self, a, b):
        c = subprocess.run(self.diff + ['-u', a, b],
                           stdout=subprocess.PIPE, encoding='utf-8')
        if c.returncode:
            return c.stdout
        return None

    def find_start_address(self, ihex):
        s = subprocess.run(self.objdump + ['-b', 'ihex', '-s', ihex],
                           check=True, stdout=subprocess.PIPE, encoding='utf-8')

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

    def sha1sum(self, path, mode='b'):
        with open(path, mode='r' + mode) as f:
            return hashlib.sha1(f.read()).hexdigest()

class MissingInformation(Exception):
    pass

@dataclasses.dataclass
class FileCheck:
    a_leaf: str
    a_base: str
    b_leaf: str
    b_base: str

    # flag for source files that are out-of-date in the package
    needs_rebuild: bool = False

    # info filled in by --index
    start: int = None
    a_sha1: str = None
    bin_sha1: str = None

    @property
    def a(self):
        return f'[{self.a_base}]/{self.a_leaf}'

    @property
    def b(self):
        return f'[{self.b_base}]/{self.b_leaf}'

    @property
    def a_basename(self):
        return os.path.basename(self.a_leaf)

    @property
    def b_basename(self):
        return os.path.basename(self.b_leaf)

    @classmethod
    def parse_base_path(cls, path):
        try:
            base, leaf = path.split('/', 1)
            if not base or not (base[0] == '[' and base[-1] == ']'):
                raise ValueError()
            base = base[1:-1]
        except ValueError:
            raise RuntimeError(f'bad format for path: {path!r}')

        if not base in DEFAULT_BASES:
            raise RuntimeError(f'bad base for path: {base!r}')

        return (base, leaf)

    @classmethod
    def parse_one(cls, row):
        args = {}

        args['a_base'], args['a_leaf'] = cls.parse_base_path(row['a'])
        args['b_base'], args['b_leaf'] = cls.parse_base_path(row['b'])

        args['needs_rebuild'] = row.get('needs_rebuild', False)

        args['start'] = row.get('start')
        if args['start'] is not None and not isinstance(args['start'], int):
            args['start'] = int(args['start'], base=0)
        args['a_sha1'] = row.get('a_sha1')
        args['bin_sha1'] = row.get('bin_sha1')

        return cls(**args)

    @classmethod
    def parse_file(cls, f):
        rows = []
        for row in json.load(f):
            rows.append(cls.parse_one(row))
        return rows

    def unparse_one(self):
        data = {
            'a': self.a,
            'b': self.b,
        }

        if self.needs_rebuild:
            data['needs_rebuild'] = self.needs_rebuild

        if self.start:
            data['start'] = hex(self.start)
        if self.a_sha1:
            data['a_sha1'] = self.a_sha1
        if self.bin_sha1:
            data['bin_sha1'] = self.bin_sha1

        return data

    @classmethod
    def unparse_file(cls, table, f):
        json.dump([row.unparse_one() for row in table], f, indent=4)
        f.write('\n')

    def paths(self, bases):
        path_a = os.path.join(bases[self.a_base], self.a_leaf)
        path_b = os.path.join(bases[self.b_base], self.b_leaf)
        return (path_a, path_b)

    def index(self, bases, tools):
        path_a, _ = self.paths(bases)
        if not os.path.exists(path_a):
            raise MissingInformation(f'file not found: {self.a!r}')

        a_sha1 = tools.sha1sum(path_a)
        with tempfile.TemporaryDirectory(prefix='diffcheck.') as d:
            bin_a = tools.ihex_to_bin(path_a, os.path.join(d, 'a.bin'))
            start_a = tools.find_start_address(path_a)
            a_bin_sha1 = tools.sha1sum(bin_a)

        self.start = start_a
        self.a_sha1 = a_sha1
        self.bin_sha1 = a_bin_sha1

    def check_exists(self, bases):
        _, path_b = self.paths(bases)
        return os.path.exists(path_b)

    def diff_fast(self, bases, tools):
        if self.start is None:
            raise MissingInformation('missing start')
        if self.bin_sha1 is None:
            raise MissingInformation('missing bin_sha1')

        _, path_b = self.paths(bases)

        with tempfile.TemporaryDirectory(prefix='diffcheck.') as d:
            bin_b = tools.ihex_to_bin(path_b, os.path.join(d, 'b.bin'))
            start_b = tools.find_start_address(path_b)
            b_bin_sha1 = tools.sha1sum(bin_b)

        return start_b != self.start or b_bin_sha1 != self.bin_sha1

    def diff_full(self, bases, tools, disassemble=False):
        path_a, path_b = self.paths(bases)

        if not os.path.exists(path_a):
            raise MissingInformation(f'file not found: {self.a!r}')
        if not os.path.exists(path_b):
            raise MissingInformation(f'file not found: {self.b!r}')

        a_sha1 = tools.sha1sum(path_a)
        if self.a_sha1 is not None and a_sha1 != self.a_sha1:
            raise MissingInformation(f'file does not match stored sha1: {self.a!r}')

        with tempfile.TemporaryDirectory(prefix='diffcheck.') as d:
            bin_a = tools.ihex_to_bin(path_a, os.path.join(d, 'a.bin'))
            bin_b = tools.ihex_to_bin(path_b, os.path.join(d, 'b.bin'))

            start_a = tools.find_start_address(path_a)
            start_b = tools.find_start_address(path_b)

            if self.start is not None and start_a != self.start:
                raise MissingInformation(f'file does not match stored start: {self.a!r}')

            if disassemble:
                asm_a = tools.bin_to_asm(bin_a, os.path.join(d, 'a.lst'), start=start_a)
                asm_b = tools.bin_to_asm(bin_b, os.path.join(d, 'b.lst'), start=start_b)
                return tools.diff_files(asm_a, asm_b)
            else:
                dump_a = tools.bin_to_hexdump(bin_a, os.path.join(d, 'a.hexdump'), start=start_a)
                dump_b = tools.bin_to_hexdump(bin_b, os.path.join(d, 'b.hexdump'), start=start_b)
                return tools.diff_files(dump_a, dump_b)

def main():
    our_file = os.path.abspath(__file__)
    our_tools = os.path.split(our_file)[0]
    our_source = os.path.split(our_tools)[0]
    table_default = os.path.join(our_tools, 'difftable.json')

    parser = argparse.ArgumentParser()
    parser.add_argument('--index', action='store_true')
    parser.add_argument('--verbose', '-v', action='store_true')
    parser.add_argument('--full', '-f', action='store_true')
    parser.add_argument('--disassemble', '-d', action='store_true')
    parser.add_argument('--table', '-t', metavar='TABLE.json', default=table_default)

    for k, v in DEFAULT_BASES.items():
        parser.add_argument('--' + k, metavar=k.upper(), default=os.path.join(our_source, v))

    args = parser.parse_args()
    tools = Tools()

    bases = {}
    for k in DEFAULT_BASES:
        bases[k] = getattr(args, k)

    with open(args.table) as f:
        table = FileCheck.parse_file(f)

    if args.index:
        for row in table:
            if args.verbose:
                print('#', row.a)
            row.index(bases, tools)

        with open(args.table, 'w') as f:
            FileCheck.unparse_file(table, f)

        return

    differences = []
    missing = []
    rebuild_files = []
    missing_info_files = []
    for row in table:
        if args.verbose:
            print('#', row.b_basename, row.a_basename)

        if not row.check_exists(bases):
            missing.append(row)
            continue

        try:
            diff_fast = row.diff_fast(bases, tools)
            if not diff_fast and not args.full:
                continue
        except MissingInformation:
            missing_info_files.append(row)
            diff_fast = False

        try:
            diff = row.diff_full(bases, tools, disassemble=args.disassemble)
        except MissingInformation as e:
            if row in missing_info_files:
                diff = 'info missing and ' + str(e)
            else:
                diff = 'info mismatch and ' + str(e)

        if diff_fast and not diff:
            diff = 'info mismatch but files compare fine -- index out of date?'

        if diff:
            print()
            print('---', row.a)
            print('+++', row.b)
            print(diff)
            print()
            differences.append(row)
            if row.needs_rebuild:
                rebuild_files.append(row)

    if missing_info_files:
        print('WARN: the following original files need their info indexed (--index):')
        for row in missing_info_files:
            print(' ', row.a)

    if differences or missing:
        if differences:
            print('ERR: differences found:')
            for row in differences:
                print(' ', row.a)
        if missing:
            print('ERR: missing files:')
            for row in missing:
                print(' ', row.b)
    else:
        if args.verbose:
            print()
        print('no differences found.')

    if rebuild_files:
        print('WARN: the following original files may need rebuilt:')
        for row in rebuild_files:
            print(' ', row.a)

    if differences or missing:
        sys.exit(1)

if __name__ == '__main__':
    main()
