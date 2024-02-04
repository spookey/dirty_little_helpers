#!/usr/bin/env python3

import argparse
import ipaddress
import re
import string
import sys

ALL_ZERO = [
    "::",
    "0.0.0.0",
]


def arguments():
    parser = argparse.ArgumentParser(__file__)

    def _help(txt):
        return f'{txt} (default: "%(default)s")'

    def _abs_num(val):
        try:
            val = int(val)
        except ValueError as ex:
            parser.error(ex)
        return abs(val)

    parser.add_argument(
        "-a",
        dest="amount",
        type=_abs_num,
        default=0,
        help=_help("output addresses with min. occurrences"),
    )
    parser.add_argument(
        "-v",
        dest="verbosity",
        type=_abs_num,
        default=0,
        help=_help('increase debug output level (max: "3")'),
    )

    return parser.parse_args()


class Filter:
    POOL = re.compile(f"[^{string.hexdigits}\\.:]")

    def __init__(self, args):
        self.args = args

    def message(self, text, *, level):
        if self.args.verbosity > 0 and self.args.verbosity >= level:
            prefix = "#" * level
            sys.stderr.write(f"{prefix} {text}\n")

    def _get_addr(self, text):
        addr = None
        try:
            addr = ipaddress.ip_address(text)
        except ValueError as ex:
            self.message(f"could not parse [{ex}]", level=3)
        return addr

    def _parse(self, lines):
        for line in lines:
            line = line.strip()
            self.message(f"got line [{line}]", level=1)
            line = self.POOL.sub(" ", line)
            self.message(f"filtered line [{line}]", level=2)
            for part in line.split():
                addr = self._get_addr(part)
                addr = addr.compressed if addr else None
                if addr is not None and addr not in ALL_ZERO:
                    yield addr

    def _retrieve(self, store):
        for addr, amnt in store.items():
            if amnt >= self.args.amount:
                yield addr

    def __call__(self, lines):
        store = {}

        for addr in self._parse(lines):
            store[addr] = 1 + store.get(addr, 0)

        for addr in self._retrieve(store):
            sys.stdout.write(f"{addr}\n")

        return 0


if __name__ == "__main__":
    sys.exit(Filter(arguments())(sys.stdin))
