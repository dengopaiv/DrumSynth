# ref vs c17

- **A, ref:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit bd5f30d (with uncommitted changes), rendered 2026-11-08 10:33)
- **B, c17:** C17 rewrite engine/ (64-bit), its own .ds parser (commit bd5f30d (with uncommitted changes), rendered 2026-11-08 10:55)
- **Compared:** 454 presets. Made by `tools/compare_wavs.py ref c17`; every preset is in `features-ref-vs-c17.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 454 | 100% |
| large | 0 | 0% |

Whole files byte for byte identical (header, samples, INFO chunk): **454 of 454**.

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.
