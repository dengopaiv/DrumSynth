"""Files and queries for checking the engine's .ds parser against Windows.

Used by run_probes.py. The original engine reads every value with
GetPrivateProfileStringA (sizes 16, 32 and 256) and GetPrivateProfileIntA;
the engine's parser (engine/src/ds_ini.c) must return exactly the same.

Files: every preset (unique ones, written to a temporary folder) and
generated files covering layouts the presets do not use: CR, LF and CRLF
line ends, white space around names, values and brackets, quotes, missing
'=', empty values, repeated sections and keys, keys before any section,
case differences, comments, long values (truncation at 16, 32, 256),
control and non-ASCII bytes, hex/octal/binary and signed integers, integer
overflow, and a file that does not exist.
"""
import os
import random
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
import dslib  # noqa: E402

# Every (section, key, default, kind/size) the original engine reads.
ENGINE_READS = [
    ("General", "Version", "", 32), ("General", "Comment", "", 256),
    ("General", "Stretch", "", 16), ("General", "Level", "", 16), ("General", "Tuning", "", 16),
    ("General", "Filter", 0, "I"), ("General", "Resonance", "", 16), ("General", "HighPass", 0, "I"),
    ("General", "FilterEnv", "0,0 100,0", 256),
    ("Noise", "On", 0, "I"), ("Noise", "Level", 0, "I"), ("Noise", "Slope", 0, "I"),
    ("Noise", "Envelope", "0,0 100,0", 256),
    ("Tone", "On", 0, "I"), ("Tone", "Level", 128, "I"), ("Tone", "Envelope", "0,0 100,0", 256),
    ("Tone", "F1", "", 16), ("Tone", "F2", "", 16), ("Tone", "Droop", "", 16), ("Tone", "Phase", "", 16),
    ("Overtones", "On", 0, "I"), ("Overtones", "Level", 128, "I"),
    ("Overtones", "Envelope1", "0,0 100,0", 256), ("Overtones", "Envelope2", "0,0 100,0", 256),
    ("Overtones", "Method", 2, "I"), ("Overtones", "F1", "", 16), ("Overtones", "F2", "", 16),
    ("Overtones", "Wave1", 0, "I"), ("Overtones", "Wave2", 0, "I"), ("Overtones", "Param", 50, "I"),
    ("Overtones", "Filter", 0, "I"), ("Overtones", "Track1", 0, "I"), ("Overtones", "Track2", 0, "I"),
    ("NoiseBand", "On", 0, "I"), ("NoiseBand", "Level", 128, "I"), ("NoiseBand", "F", "", 16),
    ("NoiseBand", "Envelope", "0,0 100,0", 256), ("NoiseBand", "dF", 50, "I"),
    ("NoiseBand2", "On", 0, "I"), ("NoiseBand2", "Level", 128, "I"), ("NoiseBand2", "F", "", 16),
    ("NoiseBand2", "Envelope", "0,0 100,0", 256), ("NoiseBand2", "dF", 50, "I"),
    ("Distortion", "On", 0, "I"), ("Distortion", "Rate", 0, "I"), ("Distortion", "Bits", 0, "I"),
    ("Distortion", "Clipping", 0, "I"),
]

EXTRA_QUERIES = [
    ("General", "Version", "", 4), ("General", "Version", "", 256), ("General", "Comment", "", 16),
    ("general", "version", "", 32), (" General ", " Version ", "", 32), ("GENERAL", "VERSION", "", 32),
    ("Test", "a", "", 256), ("Test", "a", "", 16), ("Test", "a", 7, "I"), ("Test", "b", "", 256),
    ("Test", "b", 7, "I"), ("Test", "c", "", 256), ("Test", "c", 7, "I"), ("Test", "d", "", 256),
    ("Test", "d", 7, "I"), ("Test", "missing", "def   ", 256), ("Test", "missing", "  def", 256),
    ("Test", "missing", 7, "I"), ("Test", "", "", 256), ("", "a", "", 256), ("", "top", "", 256),
    ("Test", "q1", "", 256), ("Test", "q2", "", 256), ("Test", "q3", "", 256), ("Test", "q4", "", 256),
    ("Test", "q1", "", 3), ("Test", "q2", "", 4), ("Test", "long", "", 16), ("Test", "long", "", 32),
    ("Test", "long", "", 256), ("Test", "long", 7, "I"), ("Test", "dup", "", 256), ("Test2", "x", "", 256),
    ("Test", "sp ace", "", 256), ("Test", ";comment", "", 256), ("Test", "#hash", "", 256),
    ("[Test]", "a", "", 256), ("Test", "nb", "", 256), ("Test", "nb", 7, "I"),
]

INT_TEXTS = ["0", "1", "-1", "+5", " 7", "\t8", "12abc", "abc", "0x10", "0X10", "0x", "0xFFFFFFFF",
             "0o17", "0b101", "0B101", "4294967295", "4294967296", "4294967297", "-4294967296",
             "2147483647", "2147483648", "-2147483648", "-2147483649", "99999999999999999999",
             "1.5", "-1.5", "1e3", "--1", "+-1", "- 1", "0x1G", "0b2", "0o8", "007", "-0", "١٢",
             "  -  3", "\x01" + "5", "\x1a5", "5\x1a", '"5"', "'5'", '"5', "50%"]


def generated_files(rng):
    files = {}
    files["layout_crlf.ds"] = b"[Test]\r\na=1\r\nb = 2 \r\n  c=  3\r\nd\r\n"
    files["layout_lf.ds"] = b"[Test]\na=1\nb = 2 \n  c=  3\nd\n"
    files["layout_cr.ds"] = b"[Test]\ra=1\rb = 2 \r  c=  3\rd\r"
    files["layout_mixed.ds"] = b"top=t\n[ Test ]\na=1\n[Test]\nb=2\n[test]\na=9\n[Test2]\nx=1\n"
    files["layout_brackets.ds"] = b"[Test] trailing\na=1\n[[Test]]\nb=2\n[Test\nc=3\n[Te]st]\nd=4\n"
    files["layout_ws.ds"] = b"\t[Test]\t\n\ta\t=\t1\t\n b\x0b= \x0c2\x0c\n c =3 ; note\n;comment=x\n#hash=y\n"
    files["layout_quotes.ds"] = (b"[Test]\nq1=\"abc\"\nq2='abc'\nq3=\"abc'\nq4=\"\"\na=\"\nb=' x '\n"
                                 b"c=\"a\"b\"\nd= \"  spaced  \" \n")
    files["layout_dup.ds"] = b"[Test]\ndup=first\nDUP=second\na=1\na=2\n[Test]\nb=3\n"
    files["layout_empty.ds"] = b"[Test]\na=\nb= \nc\n=nokey\nd==2\n"
    files["layout_spacekey.ds"] = b"[Test]\nsp ace=1\n sp ace =2\n"
    files["layout_long.ds"] = b"[Test]\nlong=" + b"1234567890" * 40 + b"\n"
    files["layout_ctrl.ds"] = b"[Test]\na=\x01\x02x\x7f\nb=\x00x\nc=\x1az\n\x1ad=1\n"
    files["layout_nbsp.ds"] = b"[Test]\nnb=\xa05\xa0\n\xa0a\xa0=\xa01\na2=\xe9\xe8\x85\x81\x8d\n"
    files["layout_eof.ds"] = b"[Test]\na=1"
    files["layout_bom.ds"] = b"\xef\xbb\xbf[Test]\na=1\n"
    files["layout_nosection.ds"] = b"a=1\nb=2\n"
    files["empty.ds"] = b""
    for i, t in enumerate(INT_TEXTS):
        files[f"int_{i:02d}.ds"] = b"[Test]\na=" + t.encode("cp1252", "replace") + b"\nb=" + \
            t.encode("cp1252", "replace") + b" \n"
    # random small files from a set of fragments
    frags = [b"[Test]", b"[General]", b"[test]", b" [Test] ", b"a=1", b"a = 2", b"b=x", b"c=\"q\"",
             b"Version=DrumSynth v2.0", b"version = drumsynth v2.0 ", b"Level=5", b"d", b"=", b";a=3",
             b"Comment=hello world", b"\t", b"", b"a", b"Stretch=  50 ", b"FilterEnv=0,0 1,1"]
    for i in range(150):
        lines = [rng.choice(frags) for _ in range(rng.randint(1, 10))]
        sep = rng.choice([b"\n", b"\r\n", b"\r"])
        files[f"random_{i:03d}.ds"] = sep.join(lines) + (sep if rng.random() < 0.5 else b"")
    return files


def write_queries(path):
    rows = []
    for sec, key, default, kind in ENGINE_READS + EXTRA_QUERIES:
        if kind == "I":
            rows.append(f"I\t{sec}\t{key}\t{default}")
        else:
            rows.append(f"S\t{sec}\t{key}\t{default}\t{kind}")
    with open(path, "w", encoding="latin-1", newline="\n") as f:
        f.write("\n".join(rows) + "\n")


def run_ini_probe(exe, tmp):
    rng = random.Random(1108)
    folder = os.path.join(tmp, "ini")
    os.makedirs(folder, exist_ok=True)
    paths = []
    presets, _ = dslib.load_presets()
    for i, p in enumerate(presets):
        path = os.path.join(folder, f"preset_{i:04d}.ds")
        with open(path, "wb") as f:
            f.write(p.data)
        paths.append(path)
    for name, data in generated_files(rng).items():
        path = os.path.join(folder, name)
        with open(path, "wb") as f:
            f.write(data)
        paths.append(path)
    paths.append(os.path.join(folder, "does_not_exist.ds"))
    qpath = os.path.join(tmp, "queries.txt")
    write_queries(qpath)
    lpath = os.path.join(tmp, "files.txt")
    with open(lpath, "w", encoding="latin-1", newline="\n") as f:
        f.write("\n".join(paths) + "\n")
    out = subprocess.run([exe, qpath, lpath], capture_output=True).stdout.decode("latin-1")
    diffs = []
    compared = 0
    for line in out.splitlines():
        if line.startswith("DIFF ") or line.startswith("UNREADABLE "):
            parts = line.split(" | ")
            head = parts[0].replace(folder + os.sep, "")
            diffs.append((head, parts[1] if len(parts) > 1 else "", parts[2] if len(parts) > 2 else ""))
        elif line.startswith("compared "):
            compared = int(line.split()[1].rstrip(","))
    return {"name": "ini (profile functions)", "compared": compared, "diffs": diffs}
