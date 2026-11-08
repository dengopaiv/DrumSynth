"""Generate test presets for comparing engines beyond the 849 real presets.

Usage:
    python tools/probes/make_presets.py features OUT_DIR
    python tools/probes/make_presets.py fuzz OUT_DIR [--count N] [--seed S]

features  single-feature presets: every section alone, swept across its
          parameters (tone with and without droop, noise slopes, every
          overtone method with every pair of waveforms, with and without
          tracking, noise bands across frequency and width, distortion with
          every Bits and Rate, the filter in both modes across resonance,
          high-pass, stretch, tuning, level), plus edge cases (empty and
          single-point envelopes, envelopes starting late, holding past
          442000 samples, version 1 files, missing keys, odd number formats).
          A difference then points at one section.
fuzz      random presets from a fixed seed: values from the original GUI's
          ranges (gui/DRUMSYN.FRM), sometimes beyond them, random envelopes
          of 1 to 32 points, random sections on and off, random missing keys.

Render the folder with tools/render_all.py --collections OUT_DIR --out
renders/<name>, for ref and c17, then compare with tools/compare_wavs.py
--renders renders/<name> (see docs/rendering.md). Values that make the
original DLL hang or crash (distortion Rate below 0, a noise band step of 0,
NaN phases) are left out; docs/findings.md lists them.
"""
import argparse
import os
import random

BASE = {
    "General": {"Version": "DrumSynth v2.0", "Comment": "test", "Tuning": "0.00", "Stretch": "100.0",
                "Level": "0", "Filter": "0", "HighPass": "0", "Resonance": "0",
                "FilterEnv": "0,100 442000,100 443000,0"},
    "Tone": {"On": "0", "Level": "128", "F1": "200", "F2": "50", "Droop": "0", "Phase": "90",
             "Envelope": "0,100 5250,30 16000,0"},
    "Noise": {"On": "0", "Level": "128", "Slope": "0", "Envelope": "0,100 3000,20 10000,0", "FixedSeq": "1"},
    "Overtones": {"On": "0", "Level": "128", "F1": "330", "Wave1": "0", "Track1": "0", "F2": "440",
                  "Wave2": "0", "Track2": "0", "Method": "0", "Param": "50", "Envelope1": "0,100 8000,0",
                  "Envelope2": "0,100 6000,0", "Filter": "0"},
    "NoiseBand": {"On": "0", "Level": "128", "F": "1000", "dF": "50", "Envelope": "0,100 4000,0"},
    "NoiseBand2": {"On": "0", "Level": "128", "F": "3000", "dF": "50", "Envelope": "0,100 4000,0"},
    "Distortion": {"On": "0", "Clipping": "0", "Bits": "0", "Rate": "0"},
}

ENVELOPES = [
    "0,100 5250,30 16000,0",
    "0,100 400,0",
    "0,0 100,100 2000,60 30000,0",
    "0,100 44100,100 88200,0",
    "0,50 1000,100 2000,10 3000,90 4000,0 5000,80 6000,0",
]


def preset(changes, drop=()):
    p = {s: dict(k) for s, k in BASE.items()}
    for sec, kv in changes.items():
        p.setdefault(sec, {}).update(kv)
    for sec, key in drop:
        p.get(sec, {}).pop(key, None)
    return p


def text(p):
    lines = []
    for sec, kv in p.items():
        lines.append(f"[{sec}]")
        lines += [f"{k}={v}" for k, v in kv.items()]
        lines.append("")
    return "\r\n".join(lines)


def features():
    out = []

    def add(name, changes, drop=()):
        out.append((name, preset(changes, drop)))

    on = {"On": "1"}
    # tone
    for f1 in (20, 50, 100, 200, 440, 1000, 5000, 15000):
        for f2 in (20, 120, 1000):
            add(f"tone_f{f1}_{f2}", {"Tone": {**on, "F1": f1, "F2": f2}})
    for droop in range(0, 101, 10):
        for env in ENVELOPES[:3]:
            add(f"tone_droop{droop}_{ENVELOPES.index(env)}", {"Tone": {**on, "Droop": droop, "Envelope": env}})
    for ph in (0, 45, 90, 180, 270, 360, -90):
        add(f"tone_phase{ph}", {"Tone": {**on, "Phase": ph}})
    for lev in (1, 64, 128, 181):
        add(f"tone_level{lev}", {"Tone": {**on, "Level": lev}})
    for i, env in enumerate(ENVELOPES):
        add(f"tone_env{i}", {"Tone": {**on, "Envelope": env}})
    for tune in (-24, -12, -0.5, 7, 12, 24, 36):
        add(f"tone_tune{tune}", {"Tone": on, "General": {"Tuning": tune}})
    for st in (10, 20, 50, 99.5, 200, 1000, 2000):
        add(f"tone_stretch{st}", {"Tone": on, "General": {"Stretch": st}})
    for lev in (-20, -6, 6, 20):
        add(f"tone_master{lev}", {"Tone": on, "General": {"Level": lev}})
    # noise
    for slope in range(-100, 101, 10):
        add(f"noise_slope{slope}", {"Noise": {**on, "Slope": slope}})
    for lev in (1, 64, 181):
        add(f"noise_level{lev}", {"Noise": {**on, "Level": lev}})
    # overtones
    for method in range(4):
        for w1 in range(5):
            for w2 in range(5):
                add(f"ot_m{method}_w{w1}{w2}", {"Overtones": {**on, "Method": method, "Wave1": w1, "Wave2": w2}})
        for param in (0, 25, 75, 100):
            add(f"ot_m{method}_p{param}", {"Overtones": {**on, "Method": method, "Param": param}})
        for t1, t2 in ((1, 0), (0, 1), (1, 1)):
            add(f"ot_m{method}_track{t1}{t2}", {"Tone": on, "Overtones": {**on, "Method": method,
                                                                          "Track1": t1, "Track2": t2}})
        for f1, f2 in ((100, 150), (1234.5, 5678.9), (8000, 9000), (50, 13000)):
            add(f"ot_m{method}_f{f1}_{f2}", {"Overtones": {**on, "Method": method, "F1": f1, "F2": f2}})
        add(f"ot_m{method}_filter", {"Overtones": {**on, "Method": method, "Filter": 1},
                                     "General": {"FilterEnv": "0,100 3000,10 8000,60"}})
    # noise bands
    for sec in ("NoiseBand", "NoiseBand2"):
        for f in (50, 200, 1000, 5000, 15000):
            for df in (0, 10, 25, 50, 75, 100):
                add(f"{sec.lower()}_f{f}_df{df}", {sec: {**on, "F": f, "dF": df}})
    # distortion
    for bits in range(8):
        for rate in range(8):
            add(f"dist_b{bits}_r{rate}", {"Tone": on, "Noise": on,
                                          "Distortion": {**on, "Bits": bits, "Rate": rate}})
    for clip in (0, 10, 30, 60):
        add(f"dist_clip{clip}", {"Tone": on, "Distortion": {**on, "Clipping": clip}})
    # filter
    for mode in (1, 2):
        for res in range(0, 100, 11):
            for hp in (0, 1):
                ch = {"Tone": on, "Noise": on, "General": {"Resonance": res, "HighPass": hp,
                                                            "FilterEnv": "0,100 2000,5 9000,80 16000,30"}}
                if mode == 1:
                    ch["General"]["Filter"] = 1
                else:
                    ch["Overtones"] = {**on, "Filter": 1}
                add(f"filter_m{mode}_r{res}_hp{hp}", ch)
    # edge cases
    add("edge_env_empty", {"Tone": {**on, "Envelope": ""}})
    add("edge_env_one_point", {"Tone": {**on, "Envelope": "0,100"}})
    add("edge_env_late_start", {"Tone": {**on, "Envelope": "5000,100 9000,0"}})
    add("edge_env_back_in_time", {"Tone": {**on, "Envelope": "0,100 9000,50 4000,0 12000,0"}})
    add("edge_env_32_points", {"Tone": {**on, "Envelope": " ".join(f"{i * 500},{(i * 37) % 100}" for i in range(32))}})
    add("edge_env_40_points", {"Tone": {**on, "Envelope": " ".join(f"{i * 400},{(i * 37) % 100}" for i in range(40))}})
    add("edge_env_hold_past_442000", {"Tone": on, "Noise": {**on, "Envelope": "0,100 445000,50 446000,0"},
                                      "General": {"Filter": 1}})
    add("edge_env_decimals", {"Tone": {**on, "Envelope": "0,100.5 1234.567,33.333 9999.9999,0.001"}})
    add("edge_env_double_space", {"Tone": {**on, "Envelope": "0,100  5000,20 9000,0"}})
    add("edge_env_trailing_space", {"Tone": {**on, "Envelope": "0,100 5000,20 9000,0 "}})
    add("edge_version1", {"Tone": on, "General": {"Version": "DrumSynth v1.0"}})
    add("edge_version3", {"Tone": on, "General": {"Version": "DrumSynth v3.0"}})
    add("edge_missing_keys", {"Tone": on}, drop=[("Tone", "F1"), ("Tone", "F2"), ("Tone", "Envelope"),
                                                 ("Tone", "Level"), ("General", "Stretch")])
    add("edge_long_numbers", {"Tone": {**on, "F1": "200.00000000000001", "F2": "1.5e2", "Phase": "+90"}})
    add("edge_comment_long", {"Tone": on, "General": {"Comment": "x" * 300}})
    add("edge_comment_empty", {"Tone": on, "General": {"Comment": ""}})
    add("edge_level_0", {"Tone": {**on, "Level": 0}})
    add("edge_level_200", {"Tone": {**on, "Level": 200}, "Noise": {**on, "Level": 200}})
    add("edge_freq_0", {"Tone": {**on, "F1": 0, "F2": 0}, "Overtones": {**on, "F1": 0, "Track1": 1}})
    add("edge_freq_negative", {"Tone": {**on, "F1": -200, "F2": -50}})
    add("edge_freq_22050", {"Tone": {**on, "F1": 22050, "F2": 44100}})
    add("edge_method_4", {"Overtones": {**on, "Method": 4}})
    add("edge_wave_7", {"Overtones": {**on, "Wave1": 7, "Wave2": -1}})
    add("edge_slope_200", {"Noise": {**on, "Slope": 200}})
    add("edge_dist_rate8", {"Tone": on, "Distortion": {**on, "Rate": 8}})
    add("edge_dist_rate11", {"Tone": on, "Noise": on, "Distortion": {**on, "Rate": 11}})
    add("edge_hex_int", {"Tone": {**on, "Level": "0x40"}})
    add("edge_quoted", {"Tone": {**on, "F1": '"300"', "Envelope": '"0,100 3000,0"'}})
    add("edge_all_on", {s: on for s in ("Tone", "Noise", "Overtones", "NoiseBand", "NoiseBand2", "Distortion")})
    return out


def rand_env(rng, max_time):
    n = rng.choice([1, 2, 2, 3, 3, 4, 5, 6, 8, 12, 20, 32])
    times = sorted(rng.uniform(0, max_time) for _ in range(n - 1))
    pts = [(0, rng.uniform(0, 100))] + [(t, rng.uniform(0, 100)) for t in times]
    if rng.random() < 0.7:
        pts[-1] = (pts[-1][0], 0)
    fmt = rng.choice(["{:.0f}", "{:.1f}", "{:.2f}", "{:g}"])
    return " ".join(f"{fmt.format(t)},{fmt.format(v)}" for t, v in pts)


def fuzz(rng, count):
    out = []
    for i in range(count):
        def pick(lo, hi, wide=None, digits=0):
            if wide and rng.random() < 0.05:
                lo, hi = wide
            v = rng.uniform(lo, hi)
            return f"{v:.{digits}f}" if digits else str(int(round(v)))

        def freq():
            v = 10 ** rng.uniform(1, 4.3)
            return rng.choice([f"{v:.0f}", f"{v:.2f}", f"{v:g}"])

        maxt = rng.choice([5000, 20000, 60000, 150000, 450000])
        p = {
            "General": {"Version": rng.choice(["DrumSynth v2.0"] * 9 + ["DrumSynth v1.0"]),
                        "Comment": f"fuzz {i}", "Tuning": pick(-24, 24, (-48, 48), 2),
                        "Stretch": pick(10, 400, (1, 2000), 1), "Level": pick(-20, 20, (-40, 40)),
                        "Filter": str(rng.choice([0, 0, 0, 1])), "HighPass": str(rng.choice([0, 0, 1])),
                        "Resonance": pick(0, 99), "FilterEnv": rand_env(rng, maxt * 1.5)},
            "Tone": {"On": str(rng.choice([0, 1, 1])), "Level": pick(1, 181, (0, 255)), "F1": freq(), "F2": freq(),
                     "Droop": pick(0, 100) if rng.random() < 0.5 else "0", "Phase": pick(0, 360),
                     "Envelope": rand_env(rng, maxt)},
            "Noise": {"On": str(rng.choice([0, 1])), "Level": pick(1, 181, (0, 255)), "Slope": pick(-100, 100),
                      "Envelope": rand_env(rng, maxt), "FixedSeq": "1"},
            "Overtones": {"On": str(rng.choice([0, 1])), "Level": pick(1, 181, (0, 255)), "F1": freq(),
                          "Wave1": str(rng.randint(0, 4)), "Track1": str(rng.choice([0, 0, 1])), "F2": freq(),
                          "Wave2": str(rng.randint(0, 4)), "Track2": str(rng.choice([0, 0, 1])),
                          "Method": str(rng.randint(0, 3)), "Param": pick(0, 100),
                          "Envelope1": rand_env(rng, maxt), "Envelope2": rand_env(rng, maxt),
                          "Filter": str(rng.choice([0, 0, 0, 1]))},
            "NoiseBand": {"On": str(rng.choice([0, 1])), "Level": pick(1, 181, (0, 255)), "F": freq(),
                          "dF": pick(0, 100), "Envelope": rand_env(rng, maxt)},
            "NoiseBand2": {"On": str(rng.choice([0, 1])), "Level": pick(1, 181, (0, 255)), "F": freq(),
                           "dF": pick(0, 100), "Envelope": rand_env(rng, maxt)},
            "Distortion": {"On": str(rng.choice([0, 0, 1])), "Clipping": pick(0, 60), "Bits": str(rng.randint(0, 7)),
                           "Rate": str(rng.randint(0, 7))},
        }
        for sec in list(p):
            for key in list(p[sec]):
                if key != "Version" and rng.random() < 0.02:
                    del p[sec][key]
        out.append((f"fuzz_{i:05d}", p))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("kind", choices=["features", "fuzz"])
    ap.add_argument("out")
    ap.add_argument("--count", type=int, default=2000)
    ap.add_argument("--seed", type=int, default=20261108)
    args = ap.parse_args()
    items = features() if args.kind == "features" else fuzz(random.Random(args.seed), args.count)
    os.makedirs(args.out, exist_ok=True)
    for name, p in items:
        with open(os.path.join(args.out, name + ".ds"), "w", encoding="latin-1", newline="") as f:
            f.write(text(p))
    print(f"{len(items)} presets written to {args.out}")


if __name__ == "__main__":
    main()
