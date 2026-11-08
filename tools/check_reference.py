"""The C17 engine's regression test: render everything and compare checksums.

Usage:
    python tools/check_reference.py            check the c17 renderer
    python tools/check_reference.py --update   write docs/reference/checksums.csv
                                               from the ref renders (the DLL)

docs/reference/checksums.csv holds the MD5 of every WAV file the original
DLL wrote (renderer ref, reference conditions) for three sets:
  presets   the 849 unique presets (bin/library.zip, drumsynths/)
  features  the single-feature presets (tools/probes/make_presets.py features)
  fuzz      2000 random presets (make_presets.py fuzz, seed 20261108)
A preset the DLL never finishes rendering is recorded as "hang"; the
engine must flag it with DS_NOTE_HANG. A preset the DLL refuses is recorded
with its result code. The file is the frozen definition of "sounds like the original" (docs/plan.md,
phase 10): every change to the engine must keep all checksums, or explain in
docs/findings.md why not.

--update needs the ref renders in renders/ (tools/render_all.py ref for the
presets; with --collections renders/gen/features --out renders/features and
--collections renders/gen/fuzz --out renders/fuzz for the other two). A
check renders the three sets with c17 into renders/check/ and compares whole
files byte for byte. Exit code 0 when all match.
"""
import argparse
import csv
import hashlib
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dslib  # noqa: E402

REPO = dslib.REPO
CSV = os.path.join(REPO, "docs", "reference", "checksums.csv")
GEN = os.path.join(REPO, "renders", "gen")
SETS = {
    # name: (collections for render_all.py, ref render folder)
    "presets": (None, os.path.join(REPO, "renders")),
    "features": ([os.path.join(GEN, "features")], os.path.join(REPO, "renders", "features")),
    "fuzz": ([os.path.join(GEN, "fuzz")], os.path.join(REPO, "renders", "fuzz")),
}


def md5(path):
    with open(path, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def manifest(folder):
    with open(os.path.join(folder, "manifest.csv"), encoding="utf-8") as f:
        return {row["id"]: row["key"] for row in csv.DictReader(f)}


def make_generated():
    script = os.path.join(REPO, "tools", "probes", "make_presets.py")
    if not os.path.isdir(os.path.join(GEN, "features")):
        subprocess.run([sys.executable, script, "features", os.path.join(GEN, "features")], check=True)
    if not os.path.isdir(os.path.join(GEN, "fuzz")):
        subprocess.run([sys.executable, script, "fuzz", os.path.join(GEN, "fuzz"), "--count", "2000"], check=True)


def update():
    rows = []
    for name, (_, folder) in SETS.items():
        ref = os.path.join(folder, "ref")
        keys = manifest(ref)
        with open(os.path.join(ref, "failures.csv"), encoding="utf-8") as f:
            failed = {r["id"]: r["result code"] for r in csv.DictReader(f)}
        for pid, key in sorted(keys.items()):
            wav = os.path.join(ref, pid + ".wav")
            if pid in failed:
                # "no result": the DLL never finished (stopped by the timeout);
                # a number: the DLL's result code
                code = failed[pid]
                rows.append([name, key, "hang" if code in ("no result", "timeout") else "result " + code])
            else:
                rows.append([name, key, md5(wav)])
    with open(CSV, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["set", "preset", "md5"])
        w.writerows(rows)
    print(f"{len(rows)} checksums written to {os.path.relpath(CSV, REPO)}")


def check(renderer):
    make_generated()
    with open(CSV, encoding="utf-8") as f:
        want = {(r["set"], r["preset"]): r["md5"] for r in csv.DictReader(f)}
    bad = []
    total = 0
    for name, (collections, _) in SETS.items():
        out = os.path.join(REPO, "renders", "check", name)
        cmd = [sys.executable, os.path.join(REPO, "tools", "render_all.py"), renderer, "--out", out]
        if collections:
            cmd += ["--collections", *collections]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
        folder = os.path.join(out, renderer)
        with open(os.path.join(folder, "failures.csv"), encoding="utf-8") as f:
            failed = {r["id"]: r["result code"] for r in csv.DictReader(f)}
        notes = {}
        if os.path.exists(os.path.join(folder, "notes.csv")):
            with open(os.path.join(folder, "notes.csv"), encoding="utf-8") as f:
                notes = {r["id"]: r["note"] for r in csv.DictReader(f)}
        for pid, key in manifest(folder).items():
            total += 1
            exp = want.get((name, key))
            if exp == "hang":
                # The original never finishes; the engine must say so
                # (DS_NOTE_HANG, flag 4) and render something.
                flags = int(notes.get(pid, "flags 0").split()[-1], 16)
                got = "hang" if flags & 4 and pid not in failed else f"no hang note ({notes.get(pid)})"
            elif pid in failed:
                got = "result " + failed[pid]
            else:
                got = md5(os.path.join(folder, pid + ".wav"))
            if exp != got:
                bad.append((name, key, exp, got))
    print(f"{renderer}: {total} renders checked, {len(bad)} differ from docs/reference/checksums.csv")
    for row in bad[:30]:
        print("  ", *row)
    return 1 if bad or total != len(want) else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--update", action="store_true")
    ap.add_argument("--renderer", default="c17")
    args = ap.parse_args()
    if args.update:
        update()
        return 0
    return check(args.renderer)


if __name__ == "__main__":
    sys.exit(main())
