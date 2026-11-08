# ref vs c17-winapi

- **A, ref:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit 2dcdfbe, rendered 2026-11-08 09:23)
- **B, c17-winapi:** C17 rewrite engine/ (64-bit), reading .ds files with the Windows profile functions (commit bd5f30d (with uncommitted changes), rendered 2026-11-08 10:52)
- **Compared:** 849 presets. Made by `tools/compare_wavs.py ref c17-winapi`; every preset is in `ref-vs-c17-winapi.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 849 | 100% |
| large | 0 | 0% |

Whole files byte for byte identical (header, samples, INFO chunk): **849 of 849**.

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.
