"""Turn the envelope library (docs/envelopes/*.ini) into envelope files (.dse)
that the program's Load envelope... command opens.

Usage:
    python tools/make_envelope_files.py OUT_FOLDER

Writes one folder per envelope type, in the order of the envelope selector,
with one .dse file per library entry:

    OUT_FOLDER/1 Tone/01 100%, 20% at 39.7 ms, 0% at 119 ms.dse
    OUT_FOLDER/2 Noise/...
    ...
    OUT_FOLDER/7 Filter/...

The number in front of a file name is the entry's rank in its library file
(most used first), so a file list reads the common shapes first. The rest of
the name is the entry's Name, which describes the shape in words.

Each file is in the format of docs/reference/file-formats.md ("Envelope files"),
the same as a file saved with Save envelope...:

    [DrumSynth Envelope]
    Version=1
    Envelope=0,100 1750,20 5250,0
    From=Tone (envelope library, used by 86 presets)

make_release.py ships the result in the release's Envelopes folder, which is
where the program looks first. Nothing here changes the library itself; to
change it, see docs/envelopes/README.md.
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIBRARY = os.path.join(REPO, "docs", "envelopes")

# (library file, folder name, envelope name for From=), in the selector's order
TYPES = [
    ("tone.ini", "1 Tone", "Tone"),
    ("noise.ini", "2 Noise", "Noise"),
    ("overtones-1.ini", "3 Overtones 1", "Overtones 1"),
    ("overtones-2.ini", "4 Overtones 2", "Overtones 2"),
    ("noise-band-1.ini", "5 Noise Band 1", "Noise Band 1"),
    ("noise-band-2.ini", "6 Noise Band 2", "Noise Band 2"),
    ("filter.ini", "7 Filter", "Filter"),
]

# The program's limit: an envelope has at most 31 points (envelope_editor.h).
MAX_POINTS = 31


def read_library(path):
    """The entries of one library file, in order: dicts of their keys."""
    entries = []
    cur = None
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith(";"):
                continue
            if line.startswith("["):
                cur = {}
                entries.append(cur)
            elif cur is not None and "=" in line:
                key, value = line.split("=", 1)
                cur[key.strip()] = value.strip()
    return entries


def safe_name(name):
    """A file name Windows accepts: no reserved characters, no trailing dot
    or space. The library's names have none today; this keeps it so."""
    name = re.sub(r'[\\/:*?"<>|\x00-\x1f]', "-", name)
    return name.rstrip(". ")


def write_files(out):
    total = 0
    for ini, folder, label in TYPES:
        entries = read_library(os.path.join(LIBRARY, ini))
        width = max(2, len(str(len(entries))))
        dest = os.path.join(out, folder)
        os.makedirs(dest, exist_ok=True)
        seen = set()
        for rank, e in enumerate(entries, 1):
            env, name = e.get("Envelope"), e.get("Name")
            if not env or not name:
                sys.exit(f"{ini}: entry {rank} has no Envelope or Name")
            if len(env.split()) > MAX_POINTS:
                sys.exit(f"{ini}: entry {rank} has more than {MAX_POINTS} points")
            fname = f"{rank:0{width}d} {safe_name(name)}.dse"
            if fname.lower() in seen:
                sys.exit(f"{ini}: two entries give the file name {fname}")
            seen.add(fname.lower())
            uses = e.get("Uses", "?")
            text = ("[DrumSynth Envelope]\r\nVersion=1\r\n"
                    f"Envelope={env}\r\n"
                    f"From={label} (envelope library, used by {uses} presets)\r\n")
            with open(os.path.join(dest, fname), "w", encoding="ascii", newline="") as f:
                f.write(text)
            total += 1
    return total


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("out", help="folder to write the type folders into")
    args = ap.parse_args()
    n = write_files(args.out)
    print(f"{n} envelope files written to {args.out}")


if __name__ == "__main__":
    main()
