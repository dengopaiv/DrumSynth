"""Build the DrumSynth envelope library from .ds preset collections.

Usage:
    python tools/make_envelope_library.py OUTPUT_DIR COLLECTION [COLLECTION ...]

Reads every .ds file under the given collection folders (identical files that
appear in several collections are counted once), finds every envelope, and
keeps the shapes used at least MIN_USES times across all envelope types.
Each kept shape is listed under every envelope type it was used in, in one
INI-style file per type, using the same "time,level time,level" syntax as
.ds files. Times are in samples at 44.1 kHz (before Stretch), levels in %.
"""
import hashlib
import os
import sys
from collections import Counter, defaultdict

FS = 44100
MIN_USES = 3
MAX_EXAMPLES = 5

# (section, key) in a .ds file -> (envelope type, output file name)
ENV_TYPES = [
    (("tone", "envelope"), "Tone", "tone.ini"),
    (("noise", "envelope"), "Noise", "noise.ini"),
    (("overtones", "envelope1"), "Overtones 1", "overtones-1.ini"),
    (("overtones", "envelope2"), "Overtones 2", "overtones-2.ini"),
    (("noiseband", "envelope"), "Noise Band 1", "noise-band-1.ini"),
    (("noiseband2", "envelope"), "Noise Band 2", "noise-band-2.ini"),
    (("general", "filterenv"), "Filter", "filter.ini"),
]
KEY_TO_TYPE = {key: name for key, name, _ in ENV_TYPES}

HOLD_TIME = 442000  # DrumSynth's "hold" time (10 s); used by the filter default


def parse_envelope(text):
    points = []
    for token in text.split():
        if "," not in token:
            continue
        t, l = token.split(",", 1)
        try:
            points.append((float(t), float(l)))
        except ValueError:
            pass
    return tuple(points)


def read_envelopes(path):
    """Yield (envelope type, points) for each envelope in a .ds file."""
    section = ""
    with open(path, "r", encoding="latin-1") as f:
        for line in f:
            line = line.strip()
            if line.startswith("[") and "]" in line:
                section = line[1:line.index("]")].strip().lower()
            elif "=" in line:
                key, value = line.split("=", 1)
                env_type = KEY_TO_TYPE.get((section, key.strip().lower()))
                if env_type:
                    points = parse_envelope(value)
                    if points:
                        yield env_type, points


def num(x):
    return str(int(x)) if x == int(x) else f"{x:g}"


def to_time(samples):
    """Samples -> ms, rounded like the original GUI's toTime()."""
    if samples == 0:
        return "0 ms"
    ms = 1000.0 * samples / FS
    if samples < FS / 100:
        return f"{ms:.3f} ms"
    if samples < FS / 10:
        return f"{ms:.1f} ms"
    return f"{ms:.0f} ms"


def describe(points):
    """A name that reads well aloud."""
    if len(points) >= 2 and points[-2][0] >= HOLD_TIME and all(l == 100 for _, l in points[:-1]):
        return (f"Hold at 100% (envelope off), "
                f"{num(points[-1][1])}% at {to_time(points[-1][0])}")
    steps = [f"{num(points[0][1])}%"]
    if len(points) <= 5:
        for t, l in points[1:]:
            steps.append(f"{num(l)}% at {to_time(t)}")
        return ", ".join(steps)
    start_l = points[0][1]
    peak_t, peak_l = max(points, key=lambda p: p[1])
    end_t, end_l = points[-1]
    parts = [f"{len(points)} points", f"starts {num(start_l)}%"]
    if peak_l > start_l:
        parts.append(f"peak {num(peak_l)}% at {to_time(peak_t)}")
    parts.append(f"ends {num(end_l)}% at {to_time(end_t)}")
    return ", ".join(parts)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    out_dir, roots = sys.argv[1], sys.argv[2:]

    seen_hashes = set()
    files = 0
    duplicates = 0
    total = Counter()                      # shape -> uses (all types)
    per_type = defaultdict(Counter)        # type -> shape -> uses
    examples = defaultdict(list)           # (type, shape) -> preset paths

    for root in roots:
        for d, _, names in sorted(os.walk(root)):
            for name in sorted(names):
                if not name.lower().endswith(".ds"):
                    continue
                path = os.path.join(d, name)
                with open(path, "rb") as f:
                    digest = hashlib.md5(f.read().replace(b"\r", b"")).hexdigest()
                if digest in seen_hashes:
                    duplicates += 1
                    continue
                seen_hashes.add(digest)
                files += 1
                rel = os.path.relpath(path, root).replace(os.sep, "/")
                for env_type, points in read_envelopes(path):
                    total[points] += 1
                    per_type[env_type][points] += 1
                    ex = examples[(env_type, points)]
                    if len(ex) < MAX_EXAMPLES:
                        ex.append(rel)

    kept = {shape for shape, n in total.items() if n >= MIN_USES}
    os.makedirs(out_dir, exist_ok=True)

    summary = []
    for _, env_type, filename in ENV_TYPES:
        shapes = [s for s in per_type[env_type] if s in kept]
        shapes.sort(key=lambda s: (-per_type[env_type][s], len(s), s))
        used_names = Counter()
        lines = [
            f"; DrumSynth envelope library: {env_type}",
            "; Generated by tools/make_envelope_library.py - see README.md.",
            "; Envelope = time,level pairs as in .ds files (samples at 44.1 kHz, %).",
            "; Uses = presets using it for this envelope; TotalUses = for any envelope.",
            "",
        ]
        for i, shape in enumerate(shapes, 1):
            name = describe(shape)
            used_names[name] += 1
            if used_names[name] > 1:
                name = f"{name} ({used_names[name]})"
            lines += [
                f"[Envelope {i}]",
                f"Name={name}",
                "Envelope=" + " ".join(f"{num(t)},{num(l)}" for t, l in shape),
                f"Uses={per_type[env_type][shape]}",
                f"TotalUses={total[shape]}",
                "Examples=" + "; ".join(examples[(env_type, shape)]),
                "",
            ]
        with open(os.path.join(out_dir, filename), "w", encoding="utf-8", newline="\r\n") as f:
            f.write("\n".join(lines))
        covered = sum(per_type[env_type][s] for s in shapes)
        all_uses = sum(per_type[env_type].values())
        summary.append((env_type, filename, len(shapes), len(per_type[env_type]),
                        covered, all_uses))

    all_uses = sum(total.values())
    covered = sum(total[s] for s in kept)
    print(f"preset files: {files} unique ({duplicates} duplicates skipped)")
    print(f"envelope uses: {all_uses}, distinct shapes: {len(total)}, "
          f"kept (>= {MIN_USES} uses): {len(kept)}, covering {covered / all_uses:.1%}")
    print("type | file | entries | distinct in type | uses covered")
    for env_type, filename, n, distinct, cov, uses in summary:
        print(f"{env_type} | {filename} | {n} | {distinct} | {cov}/{uses} ({cov / uses:.0%})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
