# ref vs ref-fpu24

- **A, ref:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:23)
- **B, ref-fpu24:** original ds2wav.dll with the x87 unit set to 24-bit (float) precision; a diagnostic, not how the original program ran (commit 2dcdfbe, rendered 2026-11-08 09:23)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py ref ref-fpu24`; every preset is in `ref-vs-ref-fpu24.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 91 | 11% |
| within 1 step | 196 | 23% |
| small | 207 | 24% |
| large | 355 | 42% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| noise band 1 | 396 | 9 | 19 | 78 | 290 | 0 |
| filter | 401 | 33 | 66 | 94 | 208 | 0 |
| noise | 371 | 39 | 67 | 62 | 203 | 0 |
| tone | 552 | 48 | 138 | 168 | 198 | 0 |
| noise slope | 356 | 39 | 63 | 60 | 194 | 0 |
| distortion | 415 | 64 | 19 | 146 | 186 | 0 |
| noise band 2 | 231 | 6 | 8 | 44 | 173 | 0 |
| high-pass | 286 | 33 | 37 | 55 | 161 | 0 |
| tone droop | 454 | 43 | 102 | 151 | 158 | 0 |
| bit reduction | 261 | 57 | 6 | 78 | 120 | 0 |
| downsampling | 214 | 39 | 10 | 66 | 99 | 0 |
| stretch | 203 | 26 | 34 | 48 | 95 | 0 |
| overtone tracking | 249 | 24 | 50 | 82 | 93 | 0 |
| overtones 808 Cymbal | 130 | 11 | 28 | 13 | 78 | 0 |
| version DrumSynth v1.0 | 171 | 21 | 65 | 35 | 50 | 0 |
| overtones RM | 115 | 13 | 18 | 36 | 48 | 0 |
| overtones FM | 149 | 22 | 30 | 52 | 45 | 0 |
| overtones Add | 110 | 10 | 33 | 28 | 39 | 0 |
| tuning | 88 | 11 | 14 | 27 | 36 | 0 |
| filter (overtones only) | 35 | 8 | 5 | 8 | 14 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| library/misc fx/q zone drone.ds | large | 5.4 dB | 53608 | 1.75 ms | overtones RM; overtone tracking; noise band 1; noise band 2; filter; high-pass |
| drumsynths/sea2.ds | large | 1.8 dB | 41655 | 9.46 ms | noise band 1; noise band 2; filter; high-pass; stretch |
| library/misc synth/eno's lift.ds | large | 1.7 dB | 12106 | 0.2 ms | tone; noise; noise slope; overtones RM; overtone tracking; noise band 1; noise band 2; filter |
| drumsynths/shuffled hats.ds | large | 1.7 dB | 65400 | 0.36 ms | overtones FM; overtone tracking; noise band 1; stretch |
| library/misc fx/electric waves out my window.ds | large | 1.4 dB | 20650 | 1.77 ms | noise; noise slope; noise band 1; noise band 2; filter; high-pass |
| drumsynths/soft hoo.ds | large | -0.2 dB | 6924 | 15.35 ms | noise band 1; stretch |
| library/misc fx/2-bit zone drone.ds | large | -0.8 dB | 16384 | 78.91 ms | noise; noise slope; overtones RM; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; downsampling |
| drumsynths/fat and dark.ds | large | -0.8 dB | 55612 | 0.07 ms | noise; noise slope; noise band 1; noise band 2; filter; stretch; tuning |
| library/misc/verylong.ds | large | -1.0 dB | 20063 | 10.45 ms | tone; noise; overtones FM; noise band 1; noise band 2; version DrumSynth v1.0 |
| library/misc/flat tire.ds | large | -1.2 dB | 16856 | 0.25 ms | tone; tone droop; noise; noise slope; noise band 1; stretch |
| drumsynths/dark/fat and dark.ds | large | -3.6 dB | 37269 | 0.07 ms | noise; noise slope; noise band 1; noise band 2; filter; stretch; tuning |
| library/misc fx/noise filtering.ds | large | -3.9 dB | 12077 | 0.45 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; noise band 1; filter; high-pass |
| library/misc synth/eno's ride.ds | large | -4.0 dB | 3871 | 0.98 ms | tone; noise; noise slope; overtones FM; overtone tracking; noise band 1; noise band 2; distortion; filter |
| library/misc/end transmission.ds | large | -4.1 dB | 35378 | 116.96 ms | tone; noise; noise slope; noise band 1; distortion; bit reduction; filter |
| drumsynths/Effects/z-drum.ds | large | -4.4 dB | 65400 | 0.57 ms | overtones 808 Cymbal; overtone tracking |
| library/misc hats/softie lo-fi open hat 2.ds | large | -4.5 dB | 5638 | 4.99 ms | noise band 1; distortion; bit reduction; downsampling; filter; high-pass; stretch |
| drumsynths/BUZZER.DS | large | -4.6 dB | 16107 | 0.25 ms | noise; noise slope; noise band 1; noise band 2; stretch |
| drumsynths/SEA.DS | large | -4.9 dB | 5734 | 4.01 ms | noise band 1; noise band 2 |
| drumsynths/noisetrain.ds | large | -5.8 dB | 5675 | 0.52 ms | noise; noise slope; noise band 1; noise band 2; filter; stretch |
| library/misc synth/eno's pad.ds | large | -6.3 dB | 3574 | 3.61 ms | tone; noise; noise slope; overtones FM; overtone tracking; noise band 1; noise band 2; distortion; filter; stretch |
| library/Effects/Sonar.ds | large | -6.5 dB | 5058 | 0.93 ms | noise band 1; noise band 2; version DrumSynth v1.0 |
| library/R&B/x_backwd.ds | large | -6.6 dB | 12572 | 1.0 ms | noise; noise slope; overtones FM; overtone tracking; noise band 1; filter; version DrumSynth v1.0 |
| drumsynths/WOOSH.DS | large | -6.6 dB | 20556 | 7.69 ms | noise band 1; noise band 2; filter; high-pass |
| library/misc electro/lo-fi metal.ds | large | -6.7 dB | 20784 | 1.59 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; noise band 2; distortion; downsampling; filter; high-pass; stretch |
| library/JürgenSohn/hihatopclo.ds | large | -8.2 dB | 4669 | 2.24 ms | tone; tone droop; overtones FM; noise band 1; noise band 2; filter (overtones only) |
