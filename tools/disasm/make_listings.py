"""Write the annotated disassembly listings in docs/disasm/.

Usage:
    python tools/disasm/make_listings.py [--dumpbin PATH]

Runs `dumpbin /disasm` on bin/ds2wav.dll (dumpbin comes with Visual
Studio's C++ tools; it is found with vswhere, or give --dumpbin) and writes,
with annotate.py's names for globals, constants and calls:

  docs/disasm/ds2wav-engine.asm   the code compiled from drumsynth.c
                                  (10001000-10003010)
  docs/disasm/runtime.asm         the runtime library routines the engine
                                  depends on: _ftol, rand/srand, _CIfmod,
                                  _CIpow, and sscanf's text-to-float
                                  conversion
"""
import argparse
import glob
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import annotate  # noqa: E402

REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
DLL = os.path.join(REPO, "bin", "ds2wav.dll")
OUT = os.path.join(REPO, "docs", "disasm")

ENGINE = [(0x10001000, 0x10003010, "drumsynth.c: DllMain, LongestEnv, LoudestEnv, UpdateEnv, getEnv, "
                                   "waveform, GetPrivateProfileFloat, ds2mem, ds2buf, ds2wav")]
RUNTIME = [
    (0x10003060, 0x10003087, "_ftol: float to integer (truncating fistp qword)"),
    (0x100030CA, 0x100030F2, "_CIfmod entry and the fprem loop"),
    (0x100032AA, 0x100032D9, "srand and rand (the seed is in the per-thread data, +14h)"),
    (0x10003590, 0x100037AD, "_CIpow: argument checks, fyl2x, special cases, integer test"),
    (0x10004930, 0x10004A57, "the transcendental-function dispatcher used by _CIfmod"),
    (0x10004C07, 0x10004D6A, "argument classification with fxam and the result handlers"),
    (0x100086B0, 0x10008725, "_CIpow: error report, and 2^x with f2xm1 and fscale (10008710)"),
    (0x10008725, 0x1000889C, "_CIpow: control word, argument load, result range check"),
    (0x10003A8F, 0x10003ACD, "_fassign: sscanf's %f store"),
    (0x100099F7, 0x10009A24, "_atoflt: __strgtold12, then _ld12tof"),
    (0x1000C007, 0x1000C4DC, "__strgtold12: text to a 12-byte value (state machine)"),
    (0x1000BE66, 0x1000C007, "__addl, __add_12, __shl_12, __shr_12, __mtold12"),
    (0x1000D2AA, 0x1000D546, "__ld12mul and __multtenpow12"),
    (0x10009638, 0x100099CA, "_IsZeroTail, _IncMan, _RoundMan, _CopyMan, _ZeroMan, _IsZeroMan, "
                             "_ShrMan, _ld12cvt, _ld12tod, _ld12tof"),
]


def find_dumpbin():
    vswhere = os.path.join(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"),
                           "Microsoft Visual Studio", "Installer", "vswhere.exe")
    roots = []
    if os.path.exists(vswhere):
        r = subprocess.run([vswhere, "-latest", "-products", "*", "-property", "installationPath"],
                           capture_output=True, text=True)
        roots += [line.strip() for line in r.stdout.splitlines() if line.strip()]
    roots += glob.glob(r"C:\Program Files\Microsoft Visual Studio\*\*")
    for root in roots:
        hits = sorted(glob.glob(os.path.join(root, "VC", "Tools", "MSVC", "*", "bin", "Hostx64", "x86",
                                             "dumpbin.exe")))
        if hits:
            return hits[-1]
    return None


def listing(asm_lines, ranges, title):
    out = [f"; {title}", "; Made by tools/disasm/make_listings.py from bin/ds2wav.dll (dumpbin /disasm).",
           "; Notes after ';' are added: names of globals and calls, values of constants.", ""]
    for start, end, what in ranges:
        out.append(f"; ===== {start:08X}-{end:08X}: {what}")
        out += annotate.lines(asm_lines, start, end)
        out.append("")
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dumpbin")
    args = ap.parse_args()
    dumpbin = args.dumpbin or find_dumpbin()
    if not dumpbin:
        sys.exit("dumpbin.exe not found; give --dumpbin")
    with tempfile.TemporaryDirectory() as tmp:
        raw = os.path.join(tmp, "ds2wav.asm")
        with open(raw, "w", encoding="latin-1") as f:
            subprocess.run([dumpbin, "/disasm", DLL], stdout=f, check=True)
        with open(raw, encoding="latin-1") as f:
            asm_lines = f.read().splitlines()
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "ds2wav-engine.asm"), "w", encoding="utf-8", newline="\n") as f:
        f.write(listing(asm_lines, ENGINE, "The DrumSynth engine in bin/ds2wav.dll"))
    with open(os.path.join(OUT, "runtime.asm"), "w", encoding="utf-8", newline="\n") as f:
        f.write(listing(asm_lines, RUNTIME, "Visual C++ 6 runtime routines in bin/ds2wav.dll used by the engine"))
    print("written docs/disasm/ds2wav-engine.asm, docs/disasm/runtime.asm")


if __name__ == "__main__":
    main()
