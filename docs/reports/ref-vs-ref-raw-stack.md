# ref vs ref-raw-stack

- **A, ref:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:23)
- **B, ref-raw-stack:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:25)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py ref ref-raw-stack`; every preset is in `ref-vs-ref-raw-stack.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 661 | 78% |
| large | 188 | 22% |

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## By feature

Presets using each feature, by category. A feature whose presets are all identical is not a cause. Sorted by the number of large differences.

| Feature | Presets | Identical | Within 1 step | Small | Large | Length differs |
|---|---|---|---|---|---|---|
| tone | 552 | 429 | 0 | 0 | 123 | 0 |
| tone droop | 454 | 356 | 0 | 0 | 98 | 0 |
| noise band 1 | 396 | 301 | 0 | 0 | 95 | 0 |
| noise | 371 | 286 | 0 | 0 | 85 | 0 |
| noise slope | 356 | 273 | 0 | 0 | 83 | 0 |
| distortion | 415 | 333 | 0 | 0 | 82 | 0 |
| filter | 401 | 322 | 0 | 0 | 79 | 0 |
| version DrumSynth v1.0 | 171 | 118 | 0 | 0 | 53 | 0 |
| bit reduction | 261 | 209 | 0 | 0 | 52 | 0 |
| noise band 2 | 231 | 180 | 0 | 0 | 51 | 0 |
| high-pass | 286 | 236 | 0 | 0 | 50 | 0 |
| downsampling | 214 | 172 | 0 | 0 | 42 | 0 |
| stretch | 203 | 167 | 0 | 0 | 36 | 0 |
| tuning | 88 | 73 | 0 | 0 | 15 | 0 |
| filter (overtones only) | 35 | 35 | 0 | 0 | 0 | 0 |
| overtone tracking | 249 | 249 | 0 | 0 | 0 | 0 |
| overtones 808 Cymbal | 130 | 130 | 0 | 0 | 0 | 0 |
| overtones Add | 110 | 110 | 0 | 0 | 0 | 0 |
| overtones FM | 149 | 149 | 0 | 0 | 0 | 0 |
| overtones RM | 115 | 115 | 0 | 0 | 0 | 0 |

## Largest differences (up to 25)

Difference is the RMS of B minus A, relative to the sound (A). Max is the largest single-sample difference, of 32768.

| Preset | Category | Difference | Max | First at | Features |
|---|---|---|---|---|---|
| library/misc/N_vlow.ds | large | 32.8 dB | 34800 | 0.0 ms | noise; noise slope; filter; version DrumSynth v1.0 |
| drumsynths/Effects/Scissors.ds | large | 31.0 dB | 55003 | 0.0 ms | tone; noise; noise slope; version DrumSynth v1.0 |
| library/R&B/hat rattle.ds | large | 29.3 dB | 42177 | 0.0 ms | noise; noise slope; noise band 1; noise band 2 |
| drumsynths/noisetrain.ds | large | 27.5 dB | 41457 | 0.0 ms | noise; noise slope; noise band 1; noise band 2; filter; stretch |
| library/Farfisa/Fisa Hat.ds | large | 26.8 dB | 41990 | 0.0 ms | noise band 1; noise band 2 |
| library/misc perc/layered sleigh bell.ds | large | 26.3 dB | 39512 | 0.0 ms | noise; noise slope; noise band 1; noise band 2; filter; high-pass; stretch |
| drumsynths/Misc/Snaree2.ds | large | 26.2 dB | 48147 | 0.0 ms | tone; tone droop; noise; noise slope; version DrumSynth v1.0 |
| library/Effects/Scissors.ds | large | 25.4 dB | 55003 | 0.0 ms | noise; noise slope |
| library/Acoustic/Brush1.ds | large | 24.8 dB | 44640 | 0.0 ms | tone; noise; noise slope; version DrumSynth v1.0 |
| library/misc perc/limited shaker.ds | large | 24.2 dB | 46136 | 0.0 ms | noise; noise slope; filter; high-pass |
| library/Latin/Triangle.ds | large | 22.4 dB | 42256 | 0.0 ms | tone; version DrumSynth v1.0 |
| library/tr77/Tr77 cui1.ds | large | 22.2 dB | 53828 | 0.0 ms | tone; noise; noise slope; noise band 1; filter; high-pass; stretch |
| library/misc hats/default hi-hat.ds | large | 22.0 dB | 51076 | 0.0 ms | noise |
| library/misc perc/sweetness shaker.ds | large | 21.7 dB | 51685 | 0.0 ms | noise; noise slope |
| library/tr808/Handclap.ds | large | 21.7 dB | 65400 | 0.0 ms | noise; noise slope; noise band 1; filter; high-pass |
| library/R&B/snare&hat.ds | large | 21.6 dB | 58420 | 0.0 ms | tone; tone droop; noise; noise slope; noise band 1; noise band 2; version DrumSynth v1.0 |
| library/Effects/Glass.ds | large | 21.5 dB | 52515 | 0.0 ms | tone; noise band 1; version DrumSynth v1.0 |
| library/Latin/Clave_we.ds | large | 21.2 dB | 64984 | 0.0 ms | tone; noise band 1 |
| library/misc hats/flat cymbal.ds | large | 21.1 dB | 62907 | 0.0 ms | noise; noise slope; stretch |
| library/Effects/Bubble.ds | large | 20.8 dB | 41369 | 0.0 ms | tone; version DrumSynth v1.0 |
| library/misc/ambient noise snare.ds | large | 20.6 dB | 49881 | 0.0 ms | tone; tone droop; noise; noise slope; noise band 1; noise band 2 |
| library/misc/simple-h.ds | large | 20.6 dB | 52340 | 0.0 ms | noise; noise slope; version DrumSynth v1.0 |
| library/Latin/Bongo_m2.ds | large | 20.5 dB | 47650 | 0.0 ms | noise band 2; version DrumSynth v1.0 |
| library/cr78/Clave.ds | large | 20.5 dB | 48134 | 0.0 ms | tone; version DrumSynth v1.0 |
| library/Latin/taiko.ds | large | 20.1 dB | 52586 | 0.0 ms | tone; noise band 2; version DrumSynth v1.0 |
