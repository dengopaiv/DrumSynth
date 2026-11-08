# ref-batch vs ref-batch-reverse

- **A, ref-batch:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:25)
- **B, ref-batch-reverse:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:25)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py ref-batch ref-batch-reverse`; every preset is in `ref-batch-vs-ref-batch-reverse.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 360 | 42% |
| within 1 step | 85 | 10% |
| small | 358 | 42% |
| large | 46 | 5% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| noise band 1 | 396 | 89 | 47 | 226 | 34 | 0 |
| distortion | 415 | 208 | 8 | 166 | 33 | 0 |
| noise | 371 | 92 | 48 | 200 | 31 | 0 |
| tone | 552 | 230 | 42 | 250 | 30 | 0 |
| noise slope | 356 | 88 | 47 | 191 | 30 | 0 |
| filter | 401 | 157 | 37 | 182 | 25 | 0 |
| tone droop | 454 | 197 | 32 | 201 | 24 | 0 |
| noise band 2 | 231 | 43 | 24 | 142 | 22 | 0 |
| bit reduction | 261 | 164 | 2 | 74 | 21 | 0 |
| high-pass | 286 | 112 | 25 | 129 | 20 | 0 |
| downsampling | 214 | 116 | 4 | 79 | 15 | 0 |
| overtone tracking | 249 | 142 | 15 | 80 | 12 | 0 |
| overtones Add | 110 | 38 | 10 | 53 | 9 | 0 |
| version DrumSynth v1.0 | 171 | 72 | 22 | 69 | 8 | 0 |
| overtones 808 Cymbal | 130 | 56 | 18 | 48 | 8 | 0 |
| stretch | 203 | 113 | 20 | 63 | 7 | 0 |
| overtones RM | 115 | 62 | 11 | 38 | 4 | 0 |
| filter (overtones only) | 35 | 19 | 2 | 10 | 4 | 0 |
| overtones FM | 149 | 87 | 7 | 52 | 3 | 0 |
| tuning | 88 | 41 | 7 | 37 | 3 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| drumsynths/original hc.ds | large | -22.5 dB | 15538 | 395.71 ms | tone; tone droop; distortion; stretch |
| library/Latin/one_clap.ds | large | -45.6 dB | 104 | 31.41 ms | noise band 1; noise band 2; distortion |
| library/misc fx/a blast.ds | large | -47.8 dB | 412 | 901.68 ms | noise band 1; distortion; filter; high-pass |
| library/misc/Simple-r.ds | large | -47.8 dB | 75 | 4.94 ms | tone; overtones Add; distortion; version DrumSynth v1.0 |
| library/misc/crusty snare.ds | large | -50.2 dB | 180 | 83.65 ms | tone; tone droop; noise; noise slope; overtones Add; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; filter; high-pass |
| library/misc/verylong.ds | large | -51.0 dB | 814 | 8480.16 ms | tone; noise; overtones FM; noise band 1; noise band 2; version DrumSynth v1.0 |
| library/Ferraro/grumpy buzzard.ds | large | -51.1 dB | 1277 | 124.81 ms | tone; tone droop; noise; noise slope; overtones FM; noise band 1; distortion; bit reduction |
| library/Linn/linn_cgam.ds | large | -51.3 dB | 89 | 0.75 ms | tone; tone droop; noise; noise slope; overtones Add; noise band 1; stretch; tuning; version DrumSynth v1.0 |
| library/Linn/linn_snr.ds | large | -51.6 dB | 511 | 44.49 ms | tone; tone droop; noise; noise slope; overtones Add; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; filter |
| library/misc claps/pitch clap.ds | large | -51.8 dB | 288 | 91.7 ms | noise; noise slope; noise band 1; noise band 2; distortion; bit reduction; filter; high-pass |
| library/misc fx/the plot thickens.ds | large | -52.4 dB | 1821 | 96.15 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; distortion; bit reduction |
| library/misc perc/poppy.ds | large | -52.4 dB | 139 | 14.47 ms | tone; tone droop; distortion; downsampling; filter; high-pass |
| library/misc/rimshot 2.ds | large | -52.9 dB | 64 | 4.81 ms | tone; tone droop; noise; noise slope; overtones 808 Cymbal; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter; high-pass |
| library/misc bass/the funk.ds | large | -53.0 dB | 282 | 837.73 ms | noise band 1; distortion; downsampling; filter |
| library/misc hats/sleepy 1.ds | large | -53.2 dB | 73 | 75.78 ms | noise; noise slope; overtones 808 Cymbal; noise band 1; filter; high-pass; stretch |
| library/Ferraro/jaguar hats.ds | large | -53.5 dB | 428 | 34.47 ms | tone; tone droop; noise; noise slope; overtones 808 Cymbal; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter (overtones only); high-pass |
| library/instrmnt/sweep.ds | large | -53.5 dB | 63 | 249.09 ms | tone; overtones Add; noise band 1; noise band 2; stretch; version DrumSynth v1.0 |
| library/misc electro/ringing sn.ds | large | -53.8 dB | 649 | 44.9 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter; high-pass |
| library/misc claps/pitch clap 2.ds | large | -53.9 dB | 287 | 91.07 ms | noise; noise slope; noise band 1; noise band 2; distortion; bit reduction; filter; high-pass |
| library/misc synth/eno's lift.ds | large | -54.1 dB | 230 | 8922.27 ms | tone; noise; noise slope; overtones RM; overtone tracking; noise band 1; noise band 2; filter |
| library/misc/rimshot 1.ds | large | -54.2 dB | 64 | 5.03 ms | tone; tone droop; noise; noise slope; overtones 808 Cymbal; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter; high-pass |
| library/misc perc/shaaka.ds | large | -54.3 dB | 114 | 118.1 ms | noise; noise slope |
| library/tr77/Tr77 hat.ds | large | -54.7 dB | 27 | 28.8 ms | noise band 1; version DrumSynth v1.0 |
| library/cr8000/Clap.ds | large | -55.2 dB | 85 | 163.83 ms | noise; noise slope; noise band 1; version DrumSynth v1.0 |
| library/misc/rubber '82.ds | large | -55.6 dB | 876 | 517.01 ms | tone; tone droop; noise band 2; distortion; filter; high-pass |
