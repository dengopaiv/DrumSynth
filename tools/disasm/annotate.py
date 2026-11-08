r"""Annotate a dumpbin /disasm listing of bin/ds2wav.dll.

Usage:
    dumpbin /disasm bin\ds2wav.dll > ds2wav.asm
    python tools/disasm/annotate.py ds2wav.asm START END > out.asm

Prints the instructions between the virtual addresses START and END (hex),
without the nop padding, with:
  - global variables named after drumsynth.c (envpts[e][0|1][p],
    envData[e][MAX|ENV|PNT|dENV|NEXTT], chkOn, sliLev, ...),
  - constants in .rdata shown with their float or double value,
  - calls to known runtime routines named.
The names come from reading the code (docs/disasm/README.md).
"""
import os
import re
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import peconst  # noqa: E402

D, SECS = peconst.load()

ENVDATA = ["MAX", "ENV", "PNT", "dENV", "NEXTT", "5"]

# Scalars and arrays found by reading the code.
GLOBALS = {
    0x10012880: ("chkOn", 4, 8),
    0x10015A40: ("sliLev", 4, 8),
    0x10015B40: ("timestretch", 4, 1),
    0x100124EC: ("wave", 4, 1),
    0x100124F0: ("wavemode", 4, 1),
    0x100124F4: ('"" (empty string)', 1, 1),
    0x10015A20: ("wavewords", 4, 1),
    0x1000F030: ("mem_t", 4, 1),
    0x1000F034: ("mem_o", 4, 1),
    0x1000F038: ("mem_n", 4, 1),
    0x1000F03C: ("mem_b", 4, 1),
    0x1000F040: ("mem_tune", 4, 1),
    0x1000F044: ("mem_time", 4, 1),
    0x1000F048: ('"%f"', 1, 1),
    0x1000F04C: ('"0,0 100,0"', 1, 1),
}

IMPORTS = {
    0x1000E000: "GetPrivateProfileStringA",
    0x1000E004: "GetPrivateProfileIntA",
    0x1000E008: "lstrcmpA",
    0x1000E00C: "lstrcpyA",
    0x1000E010: "Sleep",
    0x1000E100: "SetWindowTextA",
}

CALLS = {
    0x10001010: "LongestEnv",
    0x10001110: "LoudestEnv",
    0x10001150: "UpdateEnv",
    0x10001230: "getEnv",
    0x10001350: "waveform",
    0x10001460: "GetPrivateProfileFloat",
    0x100014C0: "ds2mem",
    0x10001530: "ds2buf",
    0x10001590: "ds2wav",
    0x10003060: "_ftol",
    0x10003087: "sscanf",
    0x100030CA: "_CIfmod",
    0x100030F2: "free",
    0x100032AA: "srand",
    0x100032B7: "rand",
    0x10003590: "pow (_CIpow)",
    0x10003443: "fopen",
    0x10003456: "malloc",
    0x100032D9: "fwrite",
    0x100031DB: "fclose",
    0x10003258: "sprintf",
    0x10003DF5: "_input (sscanf's scanner)",
    0x10003A8F: "_fassign",
    0x100099F7: "_atoflt",
    0x1000C007: "__strgtold12",
    0x1000BE66: "__addl",
    0x1000BE87: "__add_12",
    0x1000BEE5: "__shl_12",
    0x1000BF13: "__shr_12",
    0x1000BF40: "__mtold12",
    0x1000D2AA: "__ld12mul",
    0x1000D4CA: "__multtenpow12",
    0x10009638: "_IsZeroTail",
    0x10009681: "_IncMan",
    0x100096D7: "_RoundMan",
    0x10009763: "_CopyMan",
    0x1000977E: "_ZeroMan",
    0x1000978A: "_IsZeroMan",
    0x100097A5: "_ShrMan",
    0x10009832: "_ld12cvt",
    0x100099B4: "_ld12tof",
    0x10004930: "_trandisp2 (fmod dispatcher)",
    0x10004C07: "_ctrandisp classification",
    0x10008710: "2^x (f2xm1, fscale)",
}


def name_of(va):
    if 0x10014E20 <= va < 0x10015A20:
        o = (va - 0x10014E20) // 4
        e, r = divmod(o, 96)
        k, p = divmod(r, 32)
        return f"envpts[{e}][{k}][{p}]"
    if 0x10015A80 <= va < 0x10015B40:
        o = (va - 0x10015A80) // 4
        e, k = divmod(o, 6)
        return f"envData[{e}][{ENVDATA[k]}]"
    for base, (n, size, count) in GLOBALS.items():
        if base <= va < base + size * count:
            return n if count == 1 else f"{n}[{(va - base) // size}]"
    if 0x1000E000 <= va < 0x1000F000:
        return None
    return None


def rdata(va, kind):
    b = peconst.read(D, SECS, va, 8)
    if kind == "dword":
        return "float %r" % struct.unpack("<f", b[:4])[0]
    if kind == "qword":
        return "double %r" % struct.unpack("<d", b)[0]
    return None


def annotate(line):
    notes = []
    m = re.search(r"call\s+([0-9A-F]{8})", line)
    if m and int(m.group(1), 16) in CALLS:
        notes.append(CALLS[int(m.group(1), 16)])
    for m in re.finditer(r"(dword|qword|word|byte) ptr (?:ds:)?\[([^\]]*)\]", line):
        kind, inner = m.groups()
        for h in re.findall(r"([0-9A-F]{8})h", inner):
            va = int(h, 16)
            n = name_of(va)
            if n:
                notes.append(n if "*" not in inner and "+" not in inner.replace(h + "h", "") else f"{n} (base)")
            elif va in IMPORTS:
                notes.append(IMPORTS[va])
            elif 0x1000E100 <= va < 0x1000F000 and inner == h + "h":
                v = rdata(va, kind)
                if v:
                    notes.append(v)
    for h in re.findall(r"(?:mov|push|lea)\s+[^,]*,?([0-9A-F]{8})h", line):
        n = name_of(int(h, 16))
        if n and n not in notes:
            notes.append("&" + n)
    return line + ("   ; " + ", ".join(notes) if notes else "")


def lines(asm_lines, start, end):
    """The annotated lines of a dumpbin listing between two addresses,
    without the nop and int 3 padding."""
    out = []
    on = False
    va = 0
    for line in asm_lines:
        m = re.match(r"\s+([0-9A-F]{8}):", line)
        if m:
            va = int(m.group(1), 16)
            on = start <= va < end
            if on and (re.search(r":\s90\s+nop", line) or re.search(r":\sCC\s+int\s+3", line)):
                continue
        if on:
            if m and va in CALLS:
                out.append(f"\n; ---- {CALLS[va]} ----")
            out.append(annotate(line.rstrip()))
    return out


def main():
    path, start, end = sys.argv[1], int(sys.argv[2], 16), int(sys.argv[3], 16)
    with open(path, encoding="latin-1") as f:
        asm_lines = f.read().splitlines()
    for line in lines(asm_lines, start, end):
        print(line)


if __name__ == "__main__":
    main()
