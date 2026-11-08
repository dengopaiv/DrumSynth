# ref-fpu24 vs src

- **A, ref-fpu24:** original ds2wav.dll with the x87 unit set to 24-bit (float) precision; a diagnostic, not how the original program ran (commit 2dcdfbe, rendered 2026-11-08 09:23)
- **B, src:** original drumsynth.c (repository root) compiled with today's MSVC, 32-bit (commit 2dcdfbe, rendered 2026-11-08 09:24)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py ref-fpu24 src`; every preset is in `ref-fpu24-vs-src.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 167 | 20% |
| within 1 step | 305 | 36% |
| small | 272 | 32% |
| large | 105 | 12% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| filter | 401 | 60 | 110 | 165 | 66 | 0 |
| tone | 552 | 100 | 194 | 193 | 65 | 0 |
| noise | 371 | 62 | 124 | 128 | 57 | 0 |
| high-pass | 286 | 53 | 62 | 114 | 57 | 0 |
| noise band 1 | 396 | 36 | 137 | 168 | 55 | 0 |
| noise slope | 356 | 61 | 120 | 120 | 55 | 0 |
| distortion | 415 | 126 | 24 | 210 | 55 | 0 |
| overtones 808 Cymbal | 130 | 24 | 19 | 33 | 54 | 0 |
| tone droop | 454 | 83 | 152 | 168 | 51 | 0 |
| overtone tracking | 249 | 48 | 62 | 92 | 47 | 0 |
| bit reduction | 261 | 104 | 4 | 107 | 46 | 0 |
| noise band 2 | 231 | 28 | 50 | 117 | 36 | 0 |
| downsampling | 214 | 71 | 9 | 100 | 34 | 0 |
| stretch | 203 | 44 | 47 | 80 | 32 | 0 |
| overtones RM | 115 | 25 | 30 | 45 | 15 | 0 |
| overtones FM | 149 | 32 | 45 | 60 | 12 | 0 |
| filter (overtones only) | 35 | 9 | 5 | 13 | 8 | 0 |
| overtones Add | 110 | 20 | 53 | 30 | 7 | 0 |
| tuning | 88 | 21 | 28 | 33 | 6 | 0 |
| version DrumSynth v1.0 | 171 | 38 | 103 | 25 | 5 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| library/misc fx/wipeout.ds | large | -2.0 dB | 22250 | 9.98 ms | overtones 808 Cymbal; overtone tracking; distortion; bit reduction; downsampling; filter; high-pass; stretch |
| library/misc hats/threshold noise open.ds | large | -8.5 dB | 65400 | 10.0 ms | overtones 808 Cymbal; distortion; bit reduction; filter (overtones only); high-pass |
| library/misc electro/spaceness.ds | large | -8.9 dB | 17853 | 19.98 ms | overtones 808 Cymbal |
| library/misc hats/threshold noise.ds | large | -9.0 dB | 32700 | 9.98 ms | overtones 808 Cymbal; distortion; bit reduction; filter (overtones only); high-pass |
| drumsynths/buzz-fuzz.ds | large | -11.2 dB | 20313 | 249.25 ms | tone; tone droop; overtones 808 Cymbal; overtone tracking; stretch |
| library/misc hats/squeeze me hat.ds | large | -14.3 dB | 7998 | 3.33 ms | overtones 808 Cymbal; filter; high-pass |
| library/misc hats/squeeze  me open hat.ds | large | -14.6 dB | 7939 | 3.33 ms | overtones 808 Cymbal; filter; high-pass |
| library/misc hats/lighthat.ds | large | -15.1 dB | 11213 | 1.72 ms | noise; noise slope; overtones 808 Cymbal; noise band 1; noise band 2; filter; high-pass |
| library/magnetboy/Tone3.ds | large | -16.0 dB | 20726 | 19.98 ms | tone; tone droop; overtones 808 Cymbal |
| library/misc/tone snare.ds | large | -18.4 dB | 19644 | 9.98 ms | tone; tone droop; noise; noise slope; overtones 808 Cymbal; noise band 2; distortion; filter; high-pass |
| library/misc electro/bottle bill fx.ds | large | -19.7 dB | 6774 | 9.98 ms | tone; tone droop; overtones 808 Cymbal; overtone tracking; distortion; bit reduction; downsampling; filter; high-pass |
| library/misc hats/hardhat.ds | large | -20.3 dB | 30646 | 9.98 ms | noise; noise slope; overtones 808 Cymbal; distortion; bit reduction; filter; high-pass |
| library/misc hats/hardhat 2.ds | large | -20.9 dB | 30276 | 9.98 ms | noise; noise slope; overtones 808 Cymbal; noise band 1; distortion; bit reduction; filter; high-pass |
| library/misc hats/sleepy 2.ds | large | -21.8 dB | 5869 | 2.18 ms | noise; noise slope; overtones 808 Cymbal; noise band 1; filter; high-pass; stretch |
| library/misc hats/q ride 2.ds | large | -23.0 dB | 9038 | 2.36 ms | noise; noise slope; overtones 808 Cymbal; noise band 2; filter; high-pass; stretch |
| library/misc/laughter and jellybeans snare.ds | large | -23.0 dB | 26846 | 6.1 ms | tone; noise; noise slope; overtones 808 Cymbal; noise band 1; noise band 2; filter; high-pass |
| library/misc hats/bring me out.ds | large | -23.2 dB | 21368 | 2.06 ms | noise; noise slope; overtones 808 Cymbal; noise band 1; noise band 2; filter; high-pass |
| library/misc fx/electric intro to a.ds | large | -23.3 dB | 1053 | 0.41 ms | tone; tone droop; filter |
| library/misc electro/wee dog.ds | large | -23.4 dB | 4661 | 0.82 ms | tone; tone droop; overtones RM; overtone tracking; distortion; downsampling; filter |
| library/misc hats/heavy electrihat.ds | large | -23.7 dB | 23248 | 20.43 ms | overtones 808 Cymbal; overtone tracking; distortion; filter; high-pass; stretch |
| library/misc fx/hip-hop stop.ds | large | -24.2 dB | 6400 | 42.45 ms | tone; tone droop; overtones 808 Cymbal; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter; high-pass |
| library/misc hats/live hat.ds | large | -24.4 dB | 9421 | 1.97 ms | noise; noise slope; overtones 808 Cymbal; noise band 1; filter; high-pass; stretch |
| library/misc/pop 1 off snare.ds | large | -25.2 dB | 30413 | 9.98 ms | tone; noise; overtones 808 Cymbal; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter; high-pass; stretch |
| library/misc hats/q ride.ds | large | -25.6 dB | 3235 | 1.0 ms | noise; noise slope; overtones 808 Cymbal; noise band 2; filter; high-pass; stretch |
| library/misc/rimshot 1.ds | large | -25.8 dB | 7094 | 3.4 ms | tone; tone droop; noise; noise slope; overtones 808 Cymbal; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter; high-pass |
