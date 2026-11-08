# ref vs c17

- **A, ref:** original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000) (commit bd5f30d (with uncommitted changes), rendered 2026-11-08 10:45)
- **B, c17:** C17 rewrite engine/ (64-bit), its own .ds parser (commit bd5f30d (with uncommitted changes), rendered 2026-11-08 10:53)
- **Compared:** 1995 presets. Made by `tools/compare_wavs.py ref c17`; every preset is in `fuzz-ref-vs-c17.csv`.

## Summary

| Category | Presets | Share |
|---|---|---|
| identical | 1995 | 100% |
| large | 0 | 0% |

Whole files byte for byte identical (header, samples, INFO chunk): **1995 of 1995**.

Categories: **identical** means every sample is the same. **Within 1 step** means no sample differs by more than 1 of 32768, which is rounding. **Small** means the difference is at least 60 dB below the sound. **Large** is anything else. **Length differs** means the renders have different lengths; the other figures then cover the common part.

## Missing on one side

- fuzz/fuzz_00274.ds: only in unreadable: not a RIFF WAVE file
- fuzz/fuzz_00862.ds: only in unreadable: not a RIFF WAVE file
- fuzz/fuzz_01339.ds: only in unreadable: not a RIFF WAVE file
- fuzz/fuzz_01643.ds: only in unreadable: not a RIFF WAVE file
- fuzz/fuzz_01836.ds: only in unreadable: not a RIFF WAVE file
