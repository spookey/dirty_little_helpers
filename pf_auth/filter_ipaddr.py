#!/usr/bin/env python

from __future__ import unicode_literals

import argparse
import ipaddress
import re
import string
import sys

ALL_ZERO = [
    '::',
    '0.0.0.0',
]


def arguments():
    def _help(txt):
        return '{} (default: "%(default)s")'.format(txt)

    parser = argparse.ArgumentParser(__file__)
    parser.add_argument(
        '-a', dest='amount', action='count', default=0,
        help=_help('output addresses with min. occurrences')
    )
    parser.add_argument(
        '-v', dest='verbosity', action='count', default=0,
        help=_help('increase debug output level')
    )
    return parser.parse_args()


class Filter:
    POOL = re.compile('[^{}\\.:]'.format(string.hexdigits))

    def __init__(self, args):
        self.args = args
        self.store = {}

    def clear(self):
        self.store.clear()

    def _message(self, text, level, **fmt):
        if self.args.verbosity > 0 and self.args.verbosity >= level:
            sys.stderr.write('{} {}\n'.format(
                '#' * level, str(text).format(**fmt)
            ))

    def _get_addr(self, text):
        addr = None
        try:
            addr = ipaddress.ip_address(text)
        except ValueError as ex:
            self._message('could not parse "{ex}"', level=3, ex=ex)
        return addr

    def _parse(self, lines):
        for line in lines:
            line = line.strip()
            self._message('got line "{ln}"', level=1, ln=line)
            line = self.POOL.sub(' ', line)
            self._message('filtered line "{ln}"', level=2, ln=line)
            for part in line.split():
                addr = self._get_addr(part)
                addr = addr.compressed if addr else None
                if addr is not None and addr not in ALL_ZERO:
                    yield addr

    def _retrieve(self):
        for addr, amnt in self.store.items():
            if amnt >= self.args.amount:
                yield addr

    def __call__(self, lines):
        self.clear()

        for addr in self._parse(lines):
            self.store[addr] = 1 + self.store.get(addr, 0)

        for addr in self._retrieve():
            sys.stdout.write('{}\n'.format(addr))

        sys.stdout.flush()
        return 0


if __name__ == '__main__':
    exit(Filter(arguments())(sys.stdin))
