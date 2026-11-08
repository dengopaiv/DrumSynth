# src vs new-x86

- **A, src:** original drumsynth.c (repository root) compiled with today's MSVC, 32-bit (commit 2dcdfbe, rendered 2026-11-08 09:24)
- **B, new-x86:** modern engine src/DrumSynth.Core compiled with today's MSVC, 32-bit (commit 2dcdfbe, rendered 2026-11-08 09:24)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py src new-x86`; every preset is in `src-vs-new-x86.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 843 | 99% |
| within 1 step | 1 | 0% |
| large | 5 | 1% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| tone | 552 | 547 | 0 | 0 | 5 | 0 |
| tone droop | 454 | 449 | 0 | 0 | 5 | 0 |
| noise | 371 | 367 | 1 | 0 | 3 | 0 |
| noise slope | 356 | 352 | 1 | 0 | 3 | 0 |
| distortion | 415 | 412 | 0 | 0 | 3 | 0 |
| stretch | 203 | 200 | 0 | 0 | 3 | 0 |
| filter | 401 | 398 | 1 | 0 | 2 | 0 |
| noise band 1 | 396 | 393 | 1 | 0 | 2 | 0 |
| high-pass | 286 | 284 | 1 | 0 | 1 | 0 |
| bit reduction | 261 | 260 | 0 | 0 | 1 | 0 |
| downsampling | 214 | 213 | 0 | 0 | 1 | 0 |
| tuning | 88 | 87 | 0 | 0 | 1 | 0 |
| noise band 2 | 231 | 230 | 1 | 0 | 0 | 0 |
| filter (overtones only) | 35 | 35 | 0 | 0 | 0 | 0 |
| overtone tracking | 249 | 249 | 0 | 0 | 0 | 0 |
| overtones 808 Cymbal | 130 | 130 | 0 | 0 | 0 | 0 |
| overtones Add | 110 | 110 | 0 | 0 | 0 | 0 |
| overtones FM | 149 | 149 | 0 | 0 | 0 | 0 |
| overtones RM | 115 | 115 | 0 | 0 | 0 | 0 |
| version DrumSynth v1.0 | 171 | 171 | 0 | 0 | 0 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| library/misc/yr 808 hummer.ds | large | 14.5 dB | 65281 | 0.0 ms | tone; tone droop; filter; stretch |
| library/misc/neo808.ds | large | 14.3 dB | 43926 | 0.11 ms | tone; tone droop; noise; noise slope; distortion; filter; high-pass; stretch; tuning |
| library/misc/very basic snare.ds | large | 13.4 dB | 65400 | 0.0 ms | tone; tone droop; noise; noise slope; noise band 1 |
| library/misc/clappy snare.ds | large | 7.3 dB | 61658 | 0.0 ms | tone; tone droop; noise; noise slope; noise band 1; distortion; bit reduction; downsampling |
| drumsynths/original hc.ds | large | 3.3 dB | 40680 | 0.0 ms | tone; tone droop; distortion; stretch |
| library/misc claps/bright clap.ds | within 1 step | -114.6 dB | 1 | 135.24 ms | noise; noise slope; noise band 1; noise band 2; filter; high-pass |
