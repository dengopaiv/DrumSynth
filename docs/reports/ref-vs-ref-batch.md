# ref vs ref-batch

- **A, ref:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:23)
- **B, ref-batch:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:25)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py ref ref-batch`; every preset is in `ref-vs-ref-batch.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 465 | 55% |
| within 1 step | 74 | 9% |
| small | 277 | 33% |
| large | 33 | 4% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| distortion | 415 | 246 | 5 | 138 | 26 | 0 |
| tone | 552 | 299 | 40 | 190 | 23 | 0 |
| noise band 1 | 396 | 134 | 56 | 184 | 22 | 0 |
| noise | 371 | 150 | 46 | 154 | 21 | 0 |
| noise slope | 356 | 144 | 45 | 147 | 20 | 0 |
| noise band 2 | 231 | 65 | 29 | 118 | 19 | 0 |
| filter | 401 | 202 | 34 | 148 | 17 | 0 |
| high-pass | 286 | 137 | 20 | 112 | 17 | 0 |
| bit reduction | 261 | 185 | 1 | 58 | 17 | 0 |
| tone droop | 454 | 252 | 31 | 155 | 16 | 0 |
| overtone tracking | 249 | 159 | 15 | 62 | 13 | 0 |
| downsampling | 214 | 136 | 5 | 64 | 9 | 0 |
| overtones Add | 110 | 58 | 7 | 36 | 9 | 0 |
| version DrumSynth v1.0 | 171 | 95 | 15 | 54 | 7 | 0 |
| filter (overtones only) | 35 | 20 | 2 | 8 | 5 | 0 |
| stretch | 203 | 126 | 18 | 55 | 4 | 0 |
| overtones RM | 115 | 71 | 6 | 34 | 4 | 0 |
| overtones 808 Cymbal | 130 | 68 | 19 | 40 | 3 | 0 |
| overtones FM | 149 | 99 | 7 | 40 | 3 | 0 |
| tuning | 88 | 49 | 9 | 29 | 1 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| drumsynths/original hc.ds | large | -17.8 dB | 20340 | 395.71 ms | tone; tone droop; distortion; stretch |
| library/misc electro/ringing sn.ds | large | -27.9 dB | 12830 | 44.9 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter; high-pass |
| drumsynths/Misc/Alarma.ds | large | -40.4 dB | 1264 | 432.43 ms | tone; tone droop; overtones Add; overtone tracking; distortion; bit reduction; filter (overtones only); high-pass; version DrumSynth v1.0 |
| library/misc/Simple-r.ds | large | -47.8 dB | 75 | 4.94 ms | tone; overtones Add; distortion; version DrumSynth v1.0 |
| library/Ferraro/grumpy buzzard.ds | large | -48.9 dB | 1277 | 124.81 ms | tone; tone droop; noise; noise slope; overtones FM; noise band 1; distortion; bit reduction |
| library/misc/crusty snare.ds | large | -50.1 dB | 180 | 83.65 ms | tone; tone droop; noise; noise slope; overtones Add; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; filter; high-pass |
| library/misc/verylong.ds | large | -51.0 dB | 814 | 8479.82 ms | tone; noise; overtones FM; noise band 1; noise band 2; version DrumSynth v1.0 |
| library/Ferraro/feed this.ds | large | -51.1 dB | 953 | 35.76 ms | tone; tone droop; noise; noise slope; overtones 808 Cymbal; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; filter (overtones only) |
| library/misc claps/pitch clap.ds | large | -51.8 dB | 288 | 91.7 ms | noise; noise slope; noise band 1; noise band 2; distortion; bit reduction; filter; high-pass |
| library/Linn/linn_snr.ds | large | -51.9 dB | 511 | 44.49 ms | tone; tone droop; noise; noise slope; overtones Add; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; filter |
| library/misc fx/the plot thickens.ds | large | -52.4 dB | 1821 | 96.15 ms | tone; tone droop; noise; noise slope; overtones RM; overtone tracking; distortion; bit reduction |
| library/misc perc/poppy.ds | large | -52.4 dB | 139 | 14.47 ms | tone; tone droop; distortion; downsampling; filter; high-pass |
| library/Ferraro/jaguar hats.ds | large | -52.7 dB | 478 | 34.47 ms | tone; tone droop; noise; noise slope; overtones 808 Cymbal; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; downsampling; filter (overtones only); high-pass |
| library/misc claps/clap layer.ds | large | -52.8 dB | 124 | 84.44 ms | noise; noise slope; distortion; downsampling; filter; high-pass; stretch |
| library/tr77/Tr77 hat.ds | large | -53.6 dB | 31 | 28.8 ms | noise band 1; version DrumSynth v1.0 |
| library/instrmnt/sweep.ds | large | -53.8 dB | 65 | 249.09 ms | tone; overtones Add; noise band 1; noise band 2; stretch; version DrumSynth v1.0 |
| library/misc claps/pitch clap 2.ds | large | -53.9 dB | 287 | 91.07 ms | noise; noise slope; noise band 1; noise band 2; distortion; bit reduction; filter; high-pass |
| library/Latin/one_clap.ds | large | -54.0 dB | 40 | 31.34 ms | noise band 1; noise band 2; distortion |
| library/misc synth/eno's lift.ds | large | -54.1 dB | 230 | 9316.92 ms | tone; noise; noise slope; overtones RM; overtone tracking; noise band 1; noise band 2; filter |
| library/misc/rubber '82.ds | large | -54.3 dB | 1035 | 15.15 ms | tone; tone droop; noise band 2; distortion; filter; high-pass |
| drumsynths/blip.ds | large | -55.4 dB | 111 | 33.85 ms | tone; tone droop; noise; noise slope; overtones Add; overtone tracking; noise band 1; noise band 2; filter (overtones only); stretch; tuning |
| library/Ferraro/curb meat bass.ds | large | -55.7 dB | 635 | 107.37 ms | tone; noise; noise slope; overtones 808 Cymbal; overtone tracking; noise band 1; noise band 2; distortion; bit reduction; filter (overtones only) |
| library/misc claps/classic clap.ds | large | -56.2 dB | 79 | 88.3 ms | noise; noise slope; noise band 1; noise band 2; distortion; bit reduction; filter; high-pass |
| library/Electro/K_8bit.ds | large | -56.6 dB | 510 | 142.65 ms | tone; tone droop; noise; noise slope; noise band 1; distortion; bit reduction; downsampling; version DrumSynth v1.0 |
| library/misc/it's like that snare.ds | large | -56.7 dB | 1280 | 97.01 ms | tone; tone droop; noise; noise slope; distortion; bit reduction; downsampling; filter; high-pass |
