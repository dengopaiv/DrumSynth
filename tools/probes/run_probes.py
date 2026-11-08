"""Compare the original DLL's internal routines with the C17 engine's, bit for bit.

Usage:
    python tools/probes/run_probes.py [--quick] [--report docs/reference/probes.md]

Needs build/probes-x86/Release/probe32.exe and ini_probe32.exe and
build/probes-x64/Release/probe64.exe and ini_probe.exe (see
tools/probes/CMakeLists.txt).

What is compared (inputs are generated here, with a fixed seed):
  scanf  sscanf("%f"): every number string found in the presets, every
         envelope token, and generated strings (all digit counts, exponents,
         signs, white space, malformed text, overflow and underflow, values
         next to float rounding boundaries);
  pow    _CIpow: the argument ranges of every pow() call in the DLL, swept,
         plus random and special arguments;
  wave   waveform(): every form, phases across the ranges the engine uses,
         negative and large phases;
  rand   the first 1,000,000 values after srand(1);
  ini    GetPrivateProfileStringA / GetPrivateProfileIntA against the
         engine's parser on every preset and on generated files with
         unusual layouts (tools/probes/ini_cases.py), for every key the
         original reads plus odd ones.
Each check reports how many inputs it compared and how many differed; the
first differences are listed in the report.
"""
import argparse
import math
import os
import random
import struct
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, HERE)
import dslib  # noqa: E402
import ini_cases  # noqa: E402

REPO = dslib.REPO
P32 = os.path.join(REPO, "build", "probes-x86", "Release", "probe32.exe")
P64 = os.path.join(REPO, "build", "probes-x64", "Release", "probe64.exe")
INI = os.path.join(REPO, "build", "probes-x64", "Release", "ini_probe.exe")
INI32 = os.path.join(REPO, "build", "probes-x86", "Release", "ini_probe32.exe")
DLL = os.path.join(REPO, "bin", "ds2wav.dll")


def fbits(x):
    return struct.unpack("<I", struct.pack("<f", x))[0]


def dbits(x):
    return struct.unpack("<Q", struct.pack("<d", x))[0]


def f32(x):
    return struct.unpack("<f", struct.pack("<f", x))[0]


def run(cmd, data_lines, tmp):
    path = os.path.join(tmp, "in.txt")
    with open(path, "wb") as f:
        f.write(b"\n".join(data_lines) + b"\n")
    out = subprocess.run(cmd + [path], capture_output=True, check=True).stdout
    return out.decode("latin-1").splitlines()


def compare(name, inputs, tmp, cmd32, cmd64, show=lambda s: s):
    a = run(cmd32, inputs, tmp)
    b = run(cmd64, inputs, tmp)
    if len(a) != len(inputs) or len(b) != len(inputs):
        raise SystemExit(f"{name}: wrong number of results ({len(a)}, {len(b)}, {len(inputs)})")
    diffs = [(show(i), x, y) for i, x, y in zip(inputs, a, b) if x != y]
    return {"name": name, "compared": len(inputs), "diffs": diffs}


# ---- scanf ------------------------------------------------------------------
def scanf_inputs(rng, quick):
    s = set()
    presets, _ = dslib.load_presets()
    for p in presets:
        for sec in p.ini.values():
            for k, v in sec.items():
                s.add(v)
                for tok in v.replace(",", " ").split(" "):
                    s.add(tok)
    fixed = ["", " ", "  \t", "-", "+", ".", "-.", "+.", "1e", "1e+", "1e-", "e5", "E5", ".5", "5.",
             "+5", "  7", "\t8", "1.5.3", "0x10", "inf", "-inf", "nan", "INF", "1e39", "-1e39",
             "3.4028235e38", "3.4028236e38", "3.40282357e38", "1e-38", "1e-45", "1e-46", "1.4e-45",
             "7e-46", "16777216", "16777217", "16777218", "16777219", "33554433", "33554435",
             "0.1", "0.2", "0.3", "1e10", "123456789012345678901234567890", "0.000000000000000000001",
             "1,5", "1 5", "-0", "-0.0", "00001.5000", "1e0001", "1E5", "1e+5", "+-5", "-+5", "--5",
             "5e", "5e+x", ". 5", "1.e3", ".e3", "1..2", "\x015", "\xa05", "\x855", "5\x00"]
    s.update(fixed)
    # every digit count and position of the point, signs, exponents
    n = 2000 if quick else 60000
    for _ in range(n):
        digits = "".join(rng.choice("0123456789") for _ in range(rng.randint(1, 12)))
        k = rng.randint(0, len(digits))
        txt = digits[:k] + ("." if rng.random() < 0.8 else "") + digits[k:]
        if rng.random() < 0.3:
            txt = rng.choice(["-", "+"]) + txt
        if rng.random() < 0.15:
            txt += rng.choice(["e", "E"]) + rng.choice(["", "-", "+"]) + str(rng.randint(0, 45))
        s.add(txt)
    # values next to float rounding boundaries: midpoints between floats
    for _ in range(n // 4):
        f = f32(rng.uniform(-50000, 50000) * 10 ** rng.randint(-6, 0))
        nb = struct.unpack("<f", struct.pack("<I", fbits(f) + 1))[0]
        mid = (f + nb) / 2
        for d in (9, 12, 17, 20):
            s.add(f"{mid:.{d}g}")
    out = sorted(x.encode("latin-1") for x in s if "\n" not in x and "\r" not in x)
    return out


# ---- pow --------------------------------------------------------------------
def pow_inputs(rng, quick):
    pairs = []
    k = 1 if quick else 10

    def add(x, y):
        pairs.append(f"{dbits(x):016X} {dbits(y):016X}".encode())

    # every pow() call in the DLL, with its argument ranges
    for lev in range(-200 * k, 200 * k + 1):           # DGain: pow(10, 0.05 * Level)
        add(10.0, f32(lev / (10.0 * k)) * 0.05)
    for i in range(-2400 * k, 2400 * k + 1):           # MasterTune: pow(1.0594631f, Tuning)
        add(float(f32(1.0594631)), float(f32(i / (100.0 * k))))
    for r in range(0, 1000 * k + 1):                   # MFres: pow(Resonance * 0.0101f, 0.5)
        add(float(f32(r / (10.0 * k))) * float(f32(0.0101)), 0.5)
    for dr in range(0, 1000 * k + 1):                  # droop: pow(10, (D - 20) / 30)
        add(10.0, (float(f32(dr / (10.0 * k))) - 20.0) * float(f32(1 / 30)))
    for p in range(0, 2001):                           # ODrive: pow(Param, 3)
        add(float(p), 3.0)
    add(50.0, 3.0)
    for b in range(0, 64):                             # DAtten: pow(2, 2 * Bits)
        add(2.0, 2.0 * b)
    for c in range(0, 200):                            # clipping: pow(10, 0.05 * Clipping)
        add(10.0, c * 0.05)
    for _ in range(20000 * k):                         # filter: pow(10, MFtmp - 1), MFtmp in [0.2, 1.5]
        add(10.0, float(f32(rng.uniform(0.2, 1.5))) - 1.0)
    for _ in range(20000 * k):                         # random positive arguments
        add(math.exp(rng.uniform(-20, 20)), rng.uniform(-30, 30))
    for x in (0.0, -0.0, 1.0, -1.0, -2.0, -8.0, 1e-310, 5e-324):
        for y in (0.0, 1.0, 2.0, 3.0, 0.5, -1.0, -2.0, -3.0, 1e-310):
            add(x, y)
    return pairs


# ---- waveform ---------------------------------------------------------------
def wave_inputs(rng, quick):
    lines = []
    n = 3000 if quick else 40000
    for form in range(-1, 6):
        for _ in range(n):
            r = rng.random()
            if r < 0.6:
                ph = rng.uniform(0, 2000)           # Ophi grows by OF each sample
            elif r < 0.8:
                ph = rng.uniform(-20, 20)           # FM pushes the phase below 0
            elif r < 0.95:
                ph = rng.uniform(0, 7)
            else:
                ph = rng.uniform(-1e5, 1e6)
            lines.append(f"{fbits(f32(ph)):08X} {form}".encode())
        for ph in (0.0, -0.0, 6.2831853, -6.2831853, 3.14159265, 1e-30, -1e-30, 12.566371):
            lines.append(f"{fbits(f32(ph)):08X} {form}".encode())
    return lines


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--quick", action="store_true", help="fewer generated inputs")
    ap.add_argument("--report", default=os.path.join(REPO, "docs", "reference", "probes.md"))
    args = ap.parse_args()
    for exe in (P32, P64, INI, INI32):
        if not os.path.exists(exe):
            sys.exit(f"{exe} not found; build tools/probes first")
    rng = random.Random(20261108)
    results = []
    with tempfile.TemporaryDirectory() as tmp:
        results.append(compare("sscanf %f", scanf_inputs(rng, args.quick), tmp,
                               [P32, DLL, "scanf"], [P64, "scanf"],
                               show=lambda b: repr(b.decode("latin-1"))))
        results.append(compare("pow (_CIpow)", pow_inputs(rng, args.quick), tmp,
                               [P32, DLL, "pow"], [P64, "pow"],
                               show=lambda b: b.decode()))
        results.append(compare("waveform", wave_inputs(rng, args.quick), tmp,
                               [P32, DLL, "wave"], [P64, "wave"],
                               show=lambda b: b.decode()))
        n = "100000" if args.quick else "1000000"
        a = subprocess.run([P32, DLL, "rand", n], capture_output=True, text=True).stdout.split()
        b = subprocess.run([P64, "rand", n], capture_output=True, text=True).stdout.split()
        results.append({"name": "rand after srand(1)", "compared": len(a),
                        "diffs": [(i, x, y) for i, (x, y) in enumerate(zip(a, b)) if x != y]})
        r = ini_cases.run_ini_probe(INI, tmp)
        r["name"] = "ini, 64-bit Windows functions"
        results.append(r)
        r = ini_cases.run_ini_probe(INI32, tmp)
        r["name"] = "ini, 32-bit Windows functions (as the DLL calls them)"
        results.append(r)

    lines = ["# Probe results: the DLL's internal routines against the C17 engine", "",
             "Made by `python tools/probes/run_probes.py`" + (" --quick" if args.quick else "") + ".",
             "Each row calls the routine in the original `bin/ds2wav.dll` by address "
             "(`tools/probes/probe32.c`) and the engine's version (`tools/probes/probe64.c`), "
             "or for `ini` the Windows profile functions and the engine's parser "
             "(`tools/probes/ini_probe.c`), on the same inputs, and compares the results bit for bit "
             "(the 80-bit register value for `waveform`; for `pow`, the DLL's 80-bit result against the "
             "engine's double, since the DLL's result is always a double value).", "",
             f"CPU: {dslib.cpu_name()}", "",
             "| Routine | Inputs compared | Different |", "|---|---:|---:|"]
    for r in results:
        lines.append(f"| {r['name']} | {r['compared']:,} | {len(r['diffs']):,} |")
    for r in results:
        if r["diffs"]:
            lines += ["", f"## {r['name']}: first differences", "", "| Input | DLL / Windows | Engine |", "|---|---|---|"]
            for i, x, y in r["diffs"][:40]:
                lines.append(f"| `{i}` | `{x}` | `{y}` |")
    os.makedirs(os.path.dirname(args.report), exist_ok=True)
    with open(args.report, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    for r in results:
        print(f"{r['name']}: {r['compared']} compared, {len(r['diffs'])} different")
    print("report:", os.path.relpath(args.report, REPO))
    return 1 if any(r["diffs"] for r in results) else 0


if __name__ == "__main__":
    sys.exit(main())
