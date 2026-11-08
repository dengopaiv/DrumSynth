# ref vs c17-libm

- **A, ref:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:23)
- **B, c17-libm:** diagnostic: the C17 rewrite with today's C library for sin, cos, pow, exp, fmod and text-to-float instead of the original's x87 sequences and VC6 routines (commit bd5f30d (with uncommitted changes), rendered 2026-11-08 10:47)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py ref c17-libm`; every preset is in `ref-vs-c17-libm.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 684 | 81% |
| within 1 step | 67 | 8% |
| small | 81 | 10% |
| large | 17 | 2% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| tone | 552 | 387 | 67 | 81 | 17 | 0 |
| tone droop | 454 | 289 | 67 | 81 | 17 | 0 |
| distortion | 415 | 312 | 13 | 75 | 15 | 0 |
| overtone tracking | 249 | 169 | 24 | 44 | 12 | 0 |
| bit reduction | 261 | 209 | 2 | 38 | 12 | 0 |
| downsampling | 214 | 162 | 10 | 33 | 9 | 0 |
| filter | 401 | 325 | 25 | 44 | 7 | 0 |
| noise | 371 | 326 | 17 | 21 | 7 | 0 |
| noise slope | 356 | 314 | 14 | 21 | 7 | 0 |
| overtones RM | 115 | 85 | 9 | 15 | 6 | 0 |
| high-pass | 286 | 246 | 15 | 20 | 5 | 0 |
| overtones FM | 149 | 106 | 17 | 22 | 4 | 0 |
| noise band 2 | 231 | 205 | 9 | 14 | 3 | 0 |
| noise band 1 | 396 | 341 | 27 | 26 | 2 | 0 |
| stretch | 203 | 158 | 14 | 29 | 2 | 0 |
| overtones Add | 110 | 94 | 7 | 8 | 1 | 0 |
| overtones 808 Cymbal | 130 | 117 | 6 | 6 | 1 | 0 |
| filter (overtones only) | 35 | 28 | 2 | 4 | 1 | 0 |
| tuning | 88 | 73 | 5 | 10 | 0 | 0 |
| version DrumSynth v1.0 | 171 | 160 | 6 | 5 | 0 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| library/misc fx/electric intro to a.ds | large | -23.4 dB | 933 | 0.95 ms | tone; tone droop; filter |
| library/misc electro/applied engineering.ds | large | -27.5 dB | 30191 | 11.68 ms | tone; tone droop; overtones FM; overtone tracking; distortion; bit reduction; filter; high-pass |
| library/magnetboy/Tone18.ds | large | -33.7 dB | 512 | 41.18 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; distortion; bit reduction; downsampling |
| library/magnetboy/Tone float1.ds | large | -34.4 dB | 507 | 76.87 ms | tone; tone droop; overtones RM; overtone tracking; distortion; bit reduction; downsampling |
| library/misc fx/what time is it.ds | large | -39.3 dB | 645 | 207.44 ms | tone; tone droop; noise; noise slope; overtones FM; overtone tracking; distortion; bit reduction; downsampling |
| library/magnetboy/Mist1.ds | large | -42.3 dB | 248 | 363.06 ms | tone; tone droop; noise band 1; distortion; bit reduction; downsampling |
| library/misc electro/lo-finess.ds | large | -42.5 dB | 14633 | 553.29 ms | tone; tone droop; noise band 2; distortion; bit reduction |
| library/misc electro/zappy bells.ds | large | -45.9 dB | 4041 | 14.06 ms | tone; tone droop; noise; noise slope; overtones FM; overtone tracking; noise band 1; distortion; downsampling; filter; high-pass |
| library/magnetboy/Tone6.ds | large | -46.9 dB | 1798 | 28.91 ms | tone; tone droop; noise; noise slope; overtones Add; overtone tracking; distortion; bit reduction; downsampling |
| drumsynths/dirt bd.ds | large | -48.4 dB | 12700 | 146.98 ms | tone; tone droop; noise; noise slope; overtones 808 Cymbal; overtone tracking; noise band 2; distortion; bit reduction; downsampling; filter (overtones only); high-pass; stretch |
| library/misc fx/experiment 1.ds | large | -49.6 dB | 255 | 24.42 ms | tone; tone droop; overtones RM; overtone tracking; distortion; bit reduction; filter |
| library/misc fx/experiment 2 - turn off the tv.ds | large | -49.6 dB | 255 | 2.13 ms | tone; tone droop; distortion; bit reduction; filter |
| library/magnetboy/Squelb.ds | large | -49.7 dB | 104 | 154.83 ms | tone; tone droop; overtones RM; overtone tracking; distortion; bit reduction; downsampling |
| library/misc fx/frequency revolution.ds | large | -54.4 dB | 200 | 267.3 ms | tone; tone droop; overtones FM; overtone tracking; distortion; filter; high-pass |
| library/misc fx/multi-ping.ds | large | -54.8 dB | 63 | 2.18 ms | tone; tone droop |
| library/misc fx/the plot thickens.ds | large | -55.5 dB | 1821 | 506.51 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; distortion; bit reduction |
| library/misc fx/the tweek.ds | large | -59.0 dB | 106 | 137.51 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; noise band 2; distortion; downsampling; filter; high-pass; stretch |
| library/misc electro/a round thing.ds | small | -63.3 dB | 255 | 73.38 ms | tone; tone droop; distortion; bit reduction; filter |
| library/misc perc/q tom.ds | small | -64.9 dB | 32 | 45.9 ms | tone; tone droop; overtones RM; overtone tracking; distortion; bit reduction; downsampling; tuning |
| library/misc fx/my atari memory.ds | small | -65.7 dB | 255 | 3217.35 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; distortion; bit reduction; filter; tuning |
| library/misc electro/fuzzy q bd.ds | small | -66.4 dB | 11 | 5.12 ms | tone; tone droop; noise band 1; noise band 2; distortion; bit reduction |
| library/misc electro/shocking kiss.ds | small | -68.8 dB | 46 | 8.96 ms | tone; tone droop; distortion; bit reduction |
| library/misc/ring fray kick.ds | small | -69.1 dB | 135 | 37.62 ms | tone; tone droop; noise; noise slope; overtones Add; noise band 1; distortion; bit reduction; downsampling; filter; high-pass; tuning |
| drumsynths/Techno/crr2.ds | small | -69.9 dB | 26 | 41.72 ms | tone; tone droop; distortion; bit reduction; downsampling; version DrumSynth v1.0 |
| library/Linn/linn_tom4.ds | small | -72.9 dB | 181 | 65.22 ms | tone; tone droop; noise; noise slope; overtones Add; overtone tracking; distortion; bit reduction; filter; stretch; tuning; version DrumSynth v1.0 |
