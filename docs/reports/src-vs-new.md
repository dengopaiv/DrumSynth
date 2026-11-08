# src vs new

- **A, src:** original drumsynth.c (repository root) compiled with today's MSVC, 32-bit (commit 2dcdfbe, rendered 2026-11-08 09:24)
- **B, new:** modern engine src/DrumSynth.Core compiled with today's MSVC, 64-bit (commit 2dcdfbe, rendered 2026-11-08 09:24)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py src new`; every preset is in `src-vs-new.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 820 | 97% |
| within 1 step | 19 | 2% |
| small | 9 | 1% |
| large | 1 | 0% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| overtones RM | 115 | 86 | 19 | 9 | 1 | 0 |
| tone | 552 | 530 | 14 | 7 | 1 | 0 |
| overtone tracking | 249 | 229 | 13 | 6 | 1 | 0 |
| filter | 401 | 383 | 9 | 8 | 1 | 0 |
| tone droop | 454 | 436 | 10 | 7 | 1 | 0 |
| high-pass | 286 | 271 | 6 | 8 | 1 | 0 |
| distortion | 415 | 402 | 3 | 9 | 1 | 0 |
| stretch | 203 | 194 | 5 | 3 | 1 | 0 |
| downsampling | 214 | 207 | 1 | 5 | 1 | 0 |
| bit reduction | 261 | 257 | 0 | 3 | 1 | 0 |
| noise band 1 | 396 | 385 | 7 | 4 | 0 | 0 |
| noise band 2 | 231 | 224 | 2 | 5 | 0 | 0 |
| noise | 371 | 365 | 3 | 3 | 0 | 0 |
| noise slope | 356 | 350 | 3 | 3 | 0 | 0 |
| tuning | 88 | 84 | 1 | 3 | 0 | 0 |
| filter (overtones only) | 35 | 32 | 3 | 0 | 0 | 0 |
| version DrumSynth v1.0 | 171 | 169 | 2 | 0 | 0 | 0 |
| overtones 808 Cymbal | 130 | 130 | 0 | 0 | 0 | 0 |
| overtones Add | 110 | 110 | 0 | 0 | 0 | 0 |
| overtones FM | 149 | 149 | 0 | 0 | 0 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| drumsynths/spicy bd.ds | large | -56.8 dB | 3170 | 19.91 ms | tone; tone droop; overtones RM; overtone tracking; distortion; bit reduction; downsampling; filter; high-pass; stretch |
| library/misc perc/tone tom.ds | small | -84.6 dB | 32 | 11.13 ms | tone; tone droop; overtones RM; overtone tracking; distortion; filter; high-pass; tuning |
| library/misc electro/lo-fi metal.ds | small | -89.9 dB | 6 | 100.91 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; noise band 2; distortion; downsampling; filter; high-pass; stretch |
| library/misc synth/average rock.ds | small | -90.4 dB | 5 | 8.8 ms | overtones RM; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter; high-pass |
| library/misc fx/the tweek.ds | small | -91.4 dB | 7 | 47.89 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; noise band 2; distortion; downsampling; filter; high-pass; stretch |
| library/misc perc/deep cowbell.ds | small | -98.1 dB | 7 | 7.01 ms | overtones RM; noise band 1; noise band 2; distortion; bit reduction; filter; high-pass |
| library/misc perc/funkay timbale.ds | within 1 step | -99.7 dB | 1 | 21.7 ms | noise; noise slope; overtones RM; overtone tracking; filter; high-pass |
| library/misc fx/modular.ds | within 1 step | -99.9 dB | 1 | 10.05 ms | tone; overtones RM; overtone tracking; filter |
| library/misc/reverb please snare.ds | small | -100.0 dB | 6 | 55.74 ms | tone; tone droop; overtones RM; overtone tracking; noise band 1; noise band 2; distortion; filter; high-pass; tuning |
| library/misc fx/q zone drone.ds | within 1 step | -100.2 dB | 1 | 2.02 ms | overtones RM; overtone tracking; noise band 1; noise band 2; filter; high-pass |
| library/misc synth/eno's lift.ds | within 1 step | -101.4 dB | 1 | 156.17 ms | tone; noise; noise slope; overtones RM; overtone tracking; noise band 1; noise band 2; filter |
| library/misc electro/pleasant combo.ds | small | -105.3 dB | 6 | 63.06 ms | tone; tone droop; overtones RM; overtone tracking; distortion; bit reduction; downsampling; filter; high-pass; stretch |
| library/misc perc/hollow wood 2.ds | within 1 step | -105.6 dB | 1 | 0.73 ms | overtones RM; noise band 1; filter; high-pass; tuning |
| library/misc/another example snare.ds | small | -105.7 dB | 5 | 12.97 ms | tone; tone droop; noise; noise slope; overtones RM; noise band 1; distortion; downsampling; filter; high-pass; tuning |
| drumsynths/stomp.ds | within 1 step | -107.4 dB | 1 | 87.19 ms | tone; tone droop; overtones RM; overtone tracking; filter (overtones only); stretch |
| drumsynths/dark/stomp.ds | within 1 step | -108.8 dB | 1 | 35.53 ms | tone; tone droop; overtones RM; overtone tracking; filter (overtones only); stretch |
| library/magnetboy/Tone11.ds | within 1 step | -109.0 dB | 1 | 209.8 ms | tone; tone droop; overtones RM; overtone tracking; noise band 1 |
| library/misc electro/yr tv will be next.ds | within 1 step | -109.7 dB | 1 | 10.61 ms | tone; overtones RM; overtone tracking; filter; high-pass; stretch |
| library/Latin/Gamelan.ds | within 1 step | -111.0 dB | 1 | 11.72 ms | overtones RM; version DrumSynth v1.0 |
| library/misc electro/electro squeek.ds | within 1 step | -111.7 dB | 1 | 17.85 ms | tone; tone droop; overtones RM; overtone tracking; filter; stretch |
| library/magnetboy/Tone12.ds | within 1 step | -114.0 dB | 1 | 342.0 ms | tone; tone droop; overtones RM; overtone tracking; noise band 1; filter (overtones only) |
| library/misc synth/raver organ.ds | within 1 step | -114.5 dB | 1 | 150.25 ms | tone; tone droop; overtones RM; overtone tracking |
| library/misc synth/dark and sweet fm.ds | within 1 step | -116.7 dB | 1 | 132.49 ms | tone; tone droop; overtones RM; overtone tracking; distortion |
| library/tr909/Hat-o2.ds | within 1 step | -116.8 dB | 1 | 314.42 ms | noise; noise slope; overtones RM; noise band 1; filter; high-pass; version DrumSynth v1.0 |
| library/misc/ring mod drone bd.ds | within 1 step | -118.7 dB | 1 | 3603.45 ms | tone; tone droop; overtones RM; overtone tracking; distortion; downsampling |
