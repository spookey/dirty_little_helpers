#!/usr/bin/env python

from __future__ import unicode_literals

import argparse
import ipaddress
import re
import string
import sys


def arguments():
    parser = argparse.ArgumentParser(__file__)
    parser.add_argument(
        '-a', dest='amount', action='count', default=0,
        help='output addresses with min. occurrences (default: "%(default)s")'
    )
    parser.add_argument(
        '-v', dest='verbosity', action='count', default=0,
        help='increase debug output level (default: "%(default)s")'
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
            self._message('could not parse "{e}"', level=3, e=ex)
        return addr

    def _parse(self, lines):
        for line in lines:
            line = line.strip()
            self._message('got line "{l}"', level=1, l=line)
            line = self.POOL.sub(' ', line)
            self._message('filtered line "{l}"', level=2, l=line)
            for part in line.split():
                addr = self._get_addr(part)
                if addr is not None:
                    yield addr.compressed

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

        return 0


if __name__ == '__main__':
    exit(Filter(arguments())(sys.stdin))
