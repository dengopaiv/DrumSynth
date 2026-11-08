"""Compare two sets of renders made by render_all.py, sample by sample.

Usage:
    python tools/compare_wavs.py A B [--renders DIR] [--report PATH] [--csv PATH]

A is the reference (normally "ref", the original DLL), B the renders to check.
Writes a markdown report (default docs/reports/A-vs-B.md) and a CSV with
every preset (same name, .csv).

Categories, from best to worst:
    identical      every sample the same, same length
    within 1 step  no sample differs by more than 1 (of 32768): rounding
    small          difference at least 60 dB below the sound itself
    large          anything else: a real difference, worth investigating
    length differs the two renders have a different number of samples
                   (the other figures are then for the common part)
Presets that only one side has are listed separately (B = "original" only has
the few WAVs the original program saved).
"""
import argparse
import csv
import math
import os
import sys
from collections import Counter, defaultdict

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dslib  # noqa: E402

FS = 44100
CLIP = 32700  # DrumSynth's clip point
TIERS = ["identical", "within 1 step", "small", "large", "length differs"]
SMALL_DB = -60.0
MAX_LAG = 64


def read_manifest(path):
    with open(path, newline="", encoding="utf-8") as f:
        return {row["id"]: row for row in csv.DictReader(f)}


def read_info(path):
    info = {}
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            for line in f:
                k, _, v = line.partition(":")
                info[k.strip()] = v.strip()
    return info


def samples(path):
    rate, channels, data, _ = dslib.read_wav(path)
    if rate != FS or channels != 1:
        raise ValueError(f"{rate} Hz, {channels} channels")
    return np.frombuffer(data[:len(data) // 2 * 2], "<i2").astype(np.int64)


def db(x):
    return -math.inf if x <= 0 else 20.0 * math.log10(x)


def rms(x):
    return float(np.sqrt(np.mean(x.astype(np.float64) ** 2))) if len(x) else 0.0


def best_lag(a, b):
    """Shift of b (in samples) that matches a best, and the RMS difference then."""
    best = (0, rms(a - b))
    for lag in range(-MAX_LAG, MAX_LAG + 1):
        if lag == 0:
            continue
        if lag > 0:
            d = a[lag:] - b[:-lag]
        else:
            d = a[:lag] - b[-lag:]
        r = rms(d)
        if r < best[1]:
            best = (lag, r)
    return best


def compare(a, b):
    n = min(len(a), len(b))
    d = a[:n] - b[:n]
    nz = np.flatnonzero(d)
    max_diff = int(np.abs(d).max()) if n else 0
    diff_rms = rms(d)
    sig_rms = rms(a[:n])
    rel = db(diff_rms) - db(sig_rms) if sig_rms > 0 else (-math.inf if diff_rms == 0 else math.inf)
    if len(a) != len(b):
        tier = "length differs"
    elif not len(nz):
        tier = "identical"
    elif max_diff <= 1:
        tier = "within 1 step"
    elif rel <= SMALL_DB:
        tier = "small"
    else:
        tier = "large"
    lag = ""
    if tier in ("large", "length differs") and n > 2 * MAX_LAG:
        l, r = best_lag(a[:n], b[:n])
        if l and sig_rms > 0 and db(r) - db(sig_rms) <= SMALL_DB:
            lag = l
    return {
        "tier": tier,
        "length a": len(a),
        "length b": len(b),
        "differing samples": len(nz),
        "max diff": max_diff,
        "diff dBFS": round(db(diff_rms / 32768.0), 1) if diff_rms > 0 else "",
        "diff vs sound dB": round(rel, 1) if math.isfinite(rel) else ("" if rel < 0 else "inf"),
        "first diff ms": round(1000.0 * nz[0] / FS, 2) if len(nz) else "",
        "peak a": int(np.abs(a).max()) if len(a) else 0,
        "peak b": int(np.abs(b).max()) if len(b) else 0,
        "rms a dBFS": round(db(rms(a) / 32768.0), 1) if rms(a) > 0 else "",
        "clipped a": int(np.count_nonzero(np.abs(a) >= CLIP)),
        "clipped b": int(np.count_nonzero(np.abs(b) >= CLIP)),
        "lag": lag,
    }


def fmt_db(v):
    return "–" if v == "" else f"{v} dB"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("a")
    ap.add_argument("b")
    ap.add_argument("--renders", default=os.path.join(dslib.REPO, "renders"))
    ap.add_argument("--report")
    ap.add_argument("--csv")
    ap.add_argument("--worst", type=int, default=25)
    args = ap.parse_args()

    dir_a, dir_b = (os.path.join(args.renders, x) for x in (args.a, args.b))
    man_a = read_manifest(os.path.join(dir_a, "manifest.csv"))
    man_b = read_manifest(os.path.join(dir_b, "manifest.csv"))
    mismatched = [i for i in man_a if i in man_b and man_a[i]["md5"] != man_b[i]["md5"]]
    if mismatched or set(man_a) != set(man_b):
        sys.exit("the two render sets were made from different preset lists; render both again")
    info_a, info_b = read_info(os.path.join(dir_a, "info.txt")), read_info(os.path.join(dir_b, "info.txt"))

    rows, only = [], []
    for pid, m in man_a.items():
        pa, pb = os.path.join(dir_a, pid + ".wav"), os.path.join(dir_b, pid + ".wav")
        if not os.path.exists(pa) or not os.path.exists(pb):
            if os.path.exists(pa) != os.path.exists(pb) and args.b != "original":
                only.append((m["key"], args.a if os.path.exists(pa) else args.b))
            continue
        try:
            r = compare(samples(pa), samples(pb))
        except ValueError as e:
            only.append((m["key"], f"unreadable: {e}"))
            continue
        rows.append({"id": pid, "key": m["key"], **r, "features": m["features"]})

    report = args.report or os.path.join(dslib.REPO, "docs", "reports", f"{args.a}-vs-{args.b}.md")
    csv_path = args.csv or os.path.splitext(report)[0] + ".csv"
    os.makedirs(os.path.dirname(report), exist_ok=True)
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()) if rows else ["id"])
        w.writeheader()
        w.writerows(rows)

    tiers = Counter(r["tier"] for r in rows)
    by_feature = defaultdict(Counter)
    for r in rows:
        for feat in filter(None, (x.strip() for x in r["features"].split(";"))):
            by_feature[feat][r["tier"]] += 1
    total = len(rows)
    L = []
    L.append(f"# {args.a} vs {args.b}")
    L.append("")
    L.append(f"- **A, {args.a}:** {info_a.get('description', '')} (commit {info_a.get('commit', '?')}, rendered {info_a.get('date', '?')})")
    L.append(f"- **B, {args.b}:** {info_b.get('description', '')} (commit {info_b.get('commit', '?')}, rendered {info_b.get('date', '?')})")
    L.append(f"- **Compared:** {total} presets. Made by `tools/compare_wavs.py {args.a} {args.b}`; every preset is in `{os.path.basename(csv_path)}`.")
    L.append("")
    L.append("## Summary")
    L.append("")
    L.append("| Category | Presets | Share |")
    L.append("|---|---|---|")
    for t in TIERS:
        if tiers[t] or t in ("identical", "large"):
            L.append(f"| {t} | {tiers[t]} | {tiers[t] / total:.0%} |" if total else f"| {t} | 0 | – |")
    L.append("")
    L.append("Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. "
             f"**Small** means the difference is at least {-SMALL_DB:.0f} dB below the sound. **Large** is anything else. "
             "**Length differs** means the renders have different lengths; the other figures then cover the common part.")
    L.append("")
    if any(tiers[t] for t in TIERS if t != "identical"):
        L.append("## By feature")
        L.append("")
        L.append("Presets using each feature, by category. A feature whose presets are all identical is not a cause. "
                 "Sorted by the number of large differences.")
        L.append("")
        L.append("| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |")
        L.append("|---|---|---|---|---|---|---|")
        for feat, c in sorted(by_feature.items(), key=lambda kv: (-kv[1]["large"] - kv[1]["length differs"],
                                                                   -sum(kv[1].values()) + kv[1]["identical"], kv[0])):
            L.append(f"| {feat} | {sum(c.values())} | " + " | ".join(str(c[t]) for t in TIERS) + " |")
        L.append("")
        worst = sorted((r for r in rows if r["tier"] != "identical"),
                       key=lambda r: (TIERS.index(r["tier"]) * -1,
                                      -(r["diff vs sound dB"] if isinstance(r["diff vs sound dB"], float) else 999)))
        worst.sort(key=lambda r: -(r["diff vs sound dB"] if isinstance(r["diff vs sound dB"], float)
                                   else (999 if r["diff vs sound dB"] == "inf" else -999)))
        L.append(f"## Largest differences (up to {args.worst})")
        L.append("")
        L.append("Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.")
        L.append("")
        L.append("| Preset | Category | Difference | Max | First at | Features |")
        L.append("|---|---|---|---|---|---|")
        for r in worst[:args.worst]:
            first = "–" if r["first diff ms"] == "" else f"{r['first diff ms']} ms"
            extra = f"; best match {r['lag']:+d} samples shifted" if r["lag"] != "" else ""
            if r["tier"] == "length differs":
                extra += f"; lengths {r['length a']} and {r['length b']}"
            L.append(f"| {r['key']} | {r['tier']} | {fmt_db(r['diff vs sound dB'])} | {r['max diff']} | {first} | {r['features']}{extra} |")
        L.append("")
    if only:
        L.append("## Missing on one side")
        L.append("")
        for key, side in only:
            L.append(f"- {key}: only in {side}")
        L.append("")
    with open(report, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L))

    print(f"{args.a} vs {args.b}: {total} compared: " +
          ", ".join(f"{t} {tiers[t]}" for t in TIERS if tiers[t]) + (f"; {len(only)} on one side only" if only else ""))
    print(f"report: {os.path.relpath(report, dslib.REPO)}")


if __name__ == "__main__":
    main()
