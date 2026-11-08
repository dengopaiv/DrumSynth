# ref vs original

- **A, ref:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:23)
- **B, original:** WAVs saved by the original DrumSynth program next to their presets (commit 2dcdfbe, rendered 2026-11-08 09:25)
- **Compared:** 6 presets. Made by `tools/compare_wavs.py ref original`; every preset is in `ref-vs-original.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 2 | 33% |
| small | 1 | 17% |
| large | 3 | 50% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| noise | 4 | 0 | 0 | 1 | 3 | 0 |
| noise slope | 4 | 0 | 0 | 1 | 3 | 0 |
| stretch | 5 | 2 | 0 | 1 | 2 | 0 |
| tuning | 3 | 0 | 0 | 1 | 2 | 0 |
| filter | 2 | 0 | 0 | 0 | 2 | 0 |
| noise band 2 | 2 | 0 | 0 | 0 | 2 | 0 |
| noise band 1 | 1 | 0 | 0 | 0 | 1 | 0 |
| version DrumSynth v1.0 | 1 | 0 | 0 | 0 | 1 | 0 |
| filter (overtones only) | 1 | 0 | 0 | 1 | 0 | 0 |
| overtone tracking | 2 | 1 | 0 | 1 | 0 | 0 |
| overtones FM | 1 | 0 | 0 | 1 | 0 | 0 |
| overtones 808 Cymbal | 1 | 1 | 0 | 0 | 0 | 0 |
| overtones Add | 1 | 1 | 0 | 0 | 0 | 0 |
| tone | 2 | 2 | 0 | 0 | 0 | 0 |
| tone droop | 2 | 2 | 0 | 0 | 0 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| drumsynths/hardcore clap.ds | large | 3.1 dB | 65400 | 0.0 ms | noise; noise slope; noise band 2; filter; stretch; tuning |
| library/Latin/Shaker_1.ds | large | 3.0 dB | 10697 | 0.0 ms | noise; noise slope; version DrumSynth v1.0 |
| drumsynths/fat and dark.ds | large | 2.3 dB | 65400 | 0.0 ms | noise; noise slope; noise band 1; noise band 2; filter; stretch; tuning |
| drumsynths/bell.ds | small | -85.9 dB | 5 | 0.02 ms | noise; noise slope; overtones FM; overtone tracking; filter (overtones only); stretch; tuning |
