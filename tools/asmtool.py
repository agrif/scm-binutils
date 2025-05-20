#!/usr/bin/env python3

import argparse
import contextlib
import dataclasses
import sys

@dataclasses.dataclass
class AsmInstr:
    op: str
    arg_align: int | None
    args: list[str]

    @classmethod
    def parse(cls, instr):
        parts = instr.split(maxsplit=1)
        op = parts[0]
        arg_align = None
        args = []

        if len(parts) > 1:
            strip_args = parts[1].strip()
            raw_args = instr[len(op):].rstrip()
            arg_align = len(op) + (len(raw_args) - len(strip_args))
            args = strip_args.split(',')

        return cls(
            op=op,
            arg_align=arg_align,
            args=args,
        )

    def unparse(self):
        l = self.op
        if self.args:
            if self.arg_align is not None and self.arg_align > len(l):
                l += ' ' * (self.arg_align - len(l))
            else:
                # align can't be met or is None
                l += ' '
        l += ','.join(self.args)
        return l

@dataclasses.dataclass
class AsmLine:
    label_column: int | None = dataclasses.field(repr=False)
    label: str | None

    instr_column: int | None = dataclasses.field(repr=False)
    instr: str | None

    comment_column: int | None = dataclasses.field(repr=False)
    comment: str | None

    def fix(self):
        if self.label is None:
            self.label_column = None
        if self.instr is None:
            self.instr_column = None
        if self.comment is None:
            self.comment_column = None

    def replace(self, **kwargs):
        line = dataclasses.replace(self, **kwargs)
        line.fix()
        return line

    @classmethod
    def _parse_columns(cls, part, offset):
        end_column = len(part)
        part_lstrip = part.lstrip()
        start_column = len(part) - len(part_lstrip)
        return (start_column + offset, part_lstrip.strip(), end_column + offset)

    @classmethod
    def parse(cls, line):
        if '\t' in line:
            raise NotImplementedError(f'tabs in {line!r}')
        line_column = 0

        label_column = None
        label = None
        # careful: trim off comment first, and only look before first string
        if ':' in line.split(';', 1)[0].split('"', 1)[0].split("'", 1)[0]:
            label, line = line.split(':', 1)
            label_column, label, line_column = cls._parse_columns(label, line_column)
            line_column += 1 # for the :

        instr_column = None
        instr = None
        comment = None
        comment_column = None
        if ';' in line:
            instr, comment = line.split(';', 1)
            instr_column, instr, comment_column = cls._parse_columns(instr, line_column)
            comment = comment.rstrip()

            if not instr:
                instr_column = None
                instr = None
        else:
            if line.strip():
                instr_column, instr, _ = cls._parse_columns(line, line_column)

        return cls(
            label_column=label_column,
            label=label,
            instr_column=instr_column,
            instr=instr,
            comment_column=comment_column,
            comment=comment,
        )

    def _unparse_column(self, l, part, part_column, prefix='', suffix=''):
        if part is not None:
            if part_column is not None and part_column > len(l):
                l += ' ' * (part_column - len(l))
            else:
                # column can't be met or is None
                if l:
                    l += ' '
            l += prefix + part + suffix
        return l
    def unparse(self):
        l = ''
        l = self._unparse_column(l, self.label, self.label_column, suffix=':')
        l = self._unparse_column(l, self.instr, self.instr_column)
        l = self._unparse_column(l, self.comment, self.comment_column, prefix=';')
        return l

class AsmFile:
    def __init__(self, contents):
        self.lines = []
        for l in contents.splitlines():
            self.lines.append(AsmLine.parse(l))

    @classmethod
    def from_file(cls, f):
        return cls(f.read())

class Subcommand:
    name = None

    def __init__(self, args):
        self.args = args

    @classmethod
    def options(cls, parser):
        pass

    def run(self):
        pass

class Format(Subcommand):
    name = 'format'

    @classmethod
    def options(cls, parser):
        parser.add_argument('input')
        parser.add_argument('--in-place', action='store_true')
        parser.add_argument('-o', '--output', type=str, default='-')

        # original source is 12/32, emacs default is 4/24
        parser.add_argument('-i', '--instruction-column', type=int, default=4)
        parser.add_argument('-c', '--comment-column', type=int, default=24)

        # original source is 5, I'm leaning towards 0
        parser.add_argument('-a', '--argument-align', type=int, default=5)

    def run(self):
        with open(self.args.input) as f:
            asm = AsmFile.from_file(f)

        lines = list(self.fixup(asm))
        with self.open_output() as f:
            for line in lines:
                print(line.unparse(), file=f)

    @contextlib.contextmanager
    def open_output(self):
        if self.args.in_place:
            with open(self.args.input, 'w') as f:
                yield f
        elif self.args.output == '-':
            yield sys.stdout
        else:
            with open(self.args.output, 'w') as f:
                yield f

    def fixup(self, asm):
        for line in asm.lines:
            yield from self.fixup_line(line)

    def fixup_line(self, line):
        line = self.fixup_columns(line)
        line = self.fixup_comments(line)
        line = self.fixup_instructions(line)
        yield from self.fixup_line_splits(line)

    def fixup_columns(self, line):
        # fixup columns
        if line.label is not None:
            line.label_column = 0
        if line.instr is not None:
            line.instr_column = self.args.instruction_column
        if line.comment is not None and line.instr is None:
            # this is a standalone comment, make sure it's ;;
            if not line.comment.startswith(';'):
                line.comment = ';' + line.comment
            line.comment_column = self.args.instruction_column
        elif line.comment is not None:
            line.comment_column = self.args.comment_column

        return line

    def fixup_comments(self, line):
        # make sure comments have whitespace after ;
        if line.comment is not None:
            non_semicolon = 0
            for c in line.comment:
                if c != ';':
                    break
                non_semicolon += 1
            if non_semicolon < len(line.comment):
                if line.comment[non_semicolon] not in ' ':
                    line.comment = line.comment[:non_semicolon] + ' ' + line.comment[non_semicolon:]

        return line

    # these are ok to lower
    known_tokens = ['af', 'bc', 'de', 'hl'] \
        + ['ix' + s for s in ['', 'h', 'l']] \
        + ['iy' + s for s in ['', 'h', 'l']] \
        + ['(hl)', '(c)', '(bc)'] \
        + list('afbcdehl') \
        + ['c', 'nc', 'z', 'nz', 'm', 'p', 'pe', 'po']

    def fixup_instructions(self, line):
        # clean up instructions
        if line.instr is not None:
            instr = AsmInstr.parse(line.instr)

            # align arguments
            if instr.args:
                instr.arg_align = self.args.argument_align

            # op is lower
            instr.op = instr.op.lower()

            # clean up args
            new_args = []
            for i, arg in enumerate(instr.args):
                # everything is stripped
                arg = arg.strip()

                # if we recognize it, lower it
                lower_arg = arg.lower()
                if lower_arg in self.known_tokens:
                    arg = lower_arg
                # if it parses as a number, lower it
                try:
                    int(arg, base=0)
                    arg = lower_arg
                except ValueError:
                    pass

                # add spaces after commas in argument lists
                if i:
                    arg = ' ' + arg
                new_args.append(arg)
            instr.args = new_args

            line.instr = instr.unparse()

        return line

    def fixup_line_splits(self, line):
        # check if line needs to be split
        if line.label is not None and line.instr is not None and line.instr_column:
            if len(line.label) + 2 > line.instr_column:
                yield from self.fixup_line(line.replace(
                    instr=None,
                    comment=None,
                ))
                yield from self.fixup_line(line.replace(label=None))
                return

        if line.label is not None and line.comment is not None and line.comment_column:
            if len(line.label) + 2 > line.comment_column:
                yield from self.fixup_line(line.replace(
                    label=None,
                    instr=None,
                ))
                yield from self.fixup_line(line.replace(comment=None))
                return

        yield line

class Convert(Subcommand):
    name = 'convert'

    @classmethod
    def options(cls, parser):
        parser.add_argument('input')
        parser.add_argument('--in-place', action='store_true')
        parser.add_argument('-o', '--output', type=str, default='-')

    def run(self):
        with open(self.args.input) as f:
            asm = AsmFile.from_file(f)

        # scan for local labels
        local_labels = {}
        last_label = ''
        for line in asm.lines:
            if line.label:
                if line.label.startswith('@'):
                    local_labels[(last_label, line.label)] = last_label + '.' + line.label[1:]
                else:
                    last_label = line.label

        # replace local labels
        last_label = ''
        for line in asm.lines:
            # in the label part
            if line.label:
                if line.label.startswith('@'):
                    line.label = local_labels[(last_label, line.label)]
                else:
                    last_label = line.label

            # in the instruction
            if line.instr:
                instr = AsmInstr.parse(line.instr)
                new_args = []
                for arg in instr.args:
                    # somewhat bad, but usually works
                    for (within, k), v in local_labels.items():
                        if within != last_label:
                            continue
                        arg = arg.replace(k, v)
                    new_args.append(arg)
                instr.args = new_args
                line.instr = instr.unparse()

            # in the comment
            if line.comment:
                for (within, k), v in local_labels.items():
                    if within != last_label:
                        continue
                    line.comment = line.comment.replace(k, v)

        with self.open_output() as f:
            for line in asm.lines:
                print(line.unparse(), file=f)

    @contextlib.contextmanager
    def open_output(self):
        if self.args.in_place:
            with open(self.args.input, 'w') as f:
                yield f
        elif self.args.output == '-':
            yield sys.stdout
        else:
            with open(self.args.output, 'w') as f:
                yield f

subcommands = [Format, Convert]

def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers()

    for cls in subcommands:
        subparser = subparsers.add_parser(cls.name)
        subparser.set_defaults(cls=cls)
        cls.options(subparser)

    args = parser.parse_args()
    try:
        cmd = args.cls(args)
    except AttributeError:
        parser.print_help()
        return
    cmd.run()

if __name__ == '__main__':
    main()
