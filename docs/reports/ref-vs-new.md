# ref vs new

- **A, ref:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:23)
- **B, new:** modern engine src/DrumSynth.Core compiled with today's MSVC, 64-bit (commit 2dcdfbe, rendered 2026-11-08 09:24)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py ref new`; every preset is in `ref-vs-new.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 75 | 9% |
| within 1 step | 188 | 22% |
| small | 213 | 25% |
| large | 373 | 44% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| noise band 1 | 396 | 6 | 20 | 80 | 290 | 0 |
| filter | 401 | 29 | 59 | 93 | 220 | 0 |
| noise | 371 | 33 | 64 | 62 | 212 | 0 |
| tone | 552 | 45 | 132 | 172 | 203 | 0 |
| noise slope | 356 | 33 | 60 | 60 | 203 | 0 |
| distortion | 415 | 56 | 14 | 150 | 195 | 0 |
| high-pass | 286 | 28 | 31 | 53 | 174 | 0 |
| noise band 2 | 231 | 5 | 7 | 45 | 174 | 0 |
| tone droop | 454 | 40 | 97 | 155 | 162 | 0 |
| bit reduction | 261 | 48 | 5 | 81 | 127 | 0 |
| downsampling | 214 | 34 | 8 | 69 | 103 | 0 |
| overtone tracking | 249 | 19 | 43 | 85 | 102 | 0 |
| stretch | 203 | 26 | 31 | 48 | 98 | 0 |
| overtones 808 Cymbal | 130 | 8 | 16 | 14 | 92 | 0 |
| version DrumSynth v1.0 | 171 | 13 | 69 | 38 | 51 | 0 |
| overtones RM | 115 | 12 | 16 | 39 | 48 | 0 |
| overtones FM | 149 | 15 | 35 | 52 | 47 | 0 |
| overtones Add | 110 | 7 | 33 | 28 | 42 | 0 |
| tuning | 88 | 13 | 11 | 28 | 36 | 0 |
| filter (overtones only) | 35 | 5 | 5 | 9 | 16 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| library/misc fx/q zone drone.ds | large | 5.4 dB | 53608 | 1.75 ms | overtones RM; overtone tracking; noise band 1; noise band 2; filter; high-pass |
| drumsynths/sea2.ds | large | 1.8 dB | 41651 | 9.46 ms | noise band 1; noise band 2; filter; high-pass; stretch |
| library/misc synth/eno's lift.ds | large | 1.7 dB | 12108 | 0.2 ms | tone; noise; noise slope; overtones RM; overtone tracking; noise band 1; noise band 2; filter |
| drumsynths/shuffled hats.ds | large | 1.7 dB | 65400 | 0.07 ms | overtones FM; overtone tracking; noise band 1; stretch |
| library/misc fx/electric waves out my window.ds | large | 1.4 dB | 20650 | 1.77 ms | noise; noise slope; noise band 1; noise band 2; filter; high-pass |
| drumsynths/soft hoo.ds | large | -0.2 dB | 6924 | 15.35 ms | noise band 1; stretch |
| drumsynths/fat and dark.ds | large | -0.7 dB | 55623 | 0.23 ms | noise; noise slope; noise band 1; noise band 2; filter; stretch; tuning |
| library/misc fx/2-bit zone drone.ds | large | -0.8 dB | 16384 | 78.91 ms | noise; noise slope; overtones RM; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; downsampling |
| library/misc/verylong.ds | large | -1.0 dB | 20063 | 10.45 ms | tone; noise; overtones FM; noise band 1; noise band 2; version DrumSynth v1.0 |
| library/misc/flat tire.ds | large | -1.2 dB | 16856 | 0.25 ms | tone; tone droop; noise; noise slope; noise band 1; stretch |
| library/misc fx/wipeout.ds | large | -2.0 dB | 22250 | 9.98 ms | overtones 808 Cymbal; overtone tracking; distortion; bit reduction; downsampling; filter; high-pass; stretch |
| drumsynths/dark/fat and dark.ds | large | -3.6 dB | 37307 | 0.07 ms | noise; noise slope; noise band 1; noise band 2; filter; stretch; tuning |
| library/misc fx/noise filtering.ds | large | -3.9 dB | 12077 | 0.45 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; noise band 1; filter; high-pass |
| library/misc synth/eno's ride.ds | large | -4.0 dB | 3871 | 0.98 ms | tone; noise; noise slope; overtones FM; overtone tracking; noise band 1; noise band 2; distortion; filter |
| library/misc/end transmission.ds | large | -4.1 dB | 35378 | 116.96 ms | tone; noise; noise slope; noise band 1; distortion; bit reduction; filter |
| drumsynths/Effects/z-drum.ds | large | -4.4 dB | 65400 | 0.57 ms | overtones 808 Cymbal; overtone tracking |
| library/misc hats/softie lo-fi open hat 2.ds | large | -4.5 dB | 5638 | 2.77 ms | noise band 1; distortion; bit reduction; downsampling; filter; high-pass; stretch |
| drumsynths/BUZZER.DS | large | -4.6 dB | 16107 | 0.25 ms | noise; noise slope; noise band 1; noise band 2; stretch |
| drumsynths/SEA.DS | large | -4.9 dB | 5736 | 4.01 ms | noise band 1; noise band 2 |
| drumsynths/noisetrain.ds | large | -5.8 dB | 5669 | 0.61 ms | noise; noise slope; noise band 1; noise band 2; filter; stretch |
| library/misc synth/eno's pad.ds | large | -6.3 dB | 3574 | 3.61 ms | tone; noise; noise slope; overtones FM; overtone tracking; noise band 1; noise band 2; distortion; filter; stretch |
| library/Effects/Sonar.ds | large | -6.5 dB | 5058 | 0.93 ms | noise band 1; noise band 2; version DrumSynth v1.0 |
| library/R&B/x_backwd.ds | large | -6.6 dB | 12572 | 1.0 ms | noise; noise slope; overtones FM; overtone tracking; noise band 1; filter; version DrumSynth v1.0 |
| drumsynths/WOOSH.DS | large | -6.6 dB | 20556 | 7.69 ms | noise band 1; noise band 2; filter; high-pass |
| library/misc electro/lo-fi metal.ds | large | -6.7 dB | 20784 | 1.59 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; noise band 2; distortion; downsampling; filter; high-pass; stretch |
