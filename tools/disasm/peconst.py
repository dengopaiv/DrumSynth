"""Read constants from bin/ds2wav.dll by virtual address.

Usage: python tools/disasm/peconst.py ADDRESS[:f|d|s|i] ...
  f = 32-bit float, d = 64-bit double, s = C string, i = 32-bit int.
Without a type letter all four interpretations are printed.
"""
import os
import struct
import sys

DLL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "bin", "ds2wav.dll")


def load(path=DLL):
    d = open(path, "rb").read()
    pe = struct.unpack_from("<I", d, 0x3C)[0]
    nsec = struct.unpack_from("<H", d, pe + 6)[0]
    opt = struct.unpack_from("<H", d, pe + 20)[0]
    base = struct.unpack_from("<I", d, pe + 24 + 28)[0]
    secs = []
    for i in range(nsec):
        name, vs, va, rs, rp = struct.unpack_from("<8sIIII", d, pe + 24 + opt + i * 40)
        secs.append((name.rstrip(b"\0").decode(), base + va, vs, rp, rs))
    return d, secs


def read(d, secs, va, n):
    for name, sva, vs, rp, rs in secs:
        if sva <= va < sva + max(vs, rs):
            o = va - sva
            if o + n <= rs:
                return d[rp + o: rp + o + n]
            return bytes(n)  # uninitialized data reads as zero
    raise ValueError(hex(va))


def main():
    d, secs = load()
    for arg in sys.argv[1:]:
        a, _, t = arg.partition(":")
        va = int(a, 16)
        out = []
        if t in ("", "f"):
            out.append("f=%r" % struct.unpack("<f", read(d, secs, va, 4))[0])
        if t in ("", "d"):
            out.append("d=%r" % struct.unpack("<d", read(d, secs, va, 8))[0])
        if t in ("", "i"):
            out.append("i=%d" % struct.unpack("<i", read(d, secs, va, 4))[0])
        if t in ("", "s"):
            out.append("s=%r" % read(d, secs, va, 32).split(b"\0")[0])
        print(hex(va), " ".join(out))


if __name__ == "__main__":
    main()
