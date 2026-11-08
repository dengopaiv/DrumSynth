# Probe results: the DLL's internal routines against the C17 engine

Made by `python tools/probes/run_probes.py`.
Each row calls the routine in the original `bin/ds2wav.dll` by address (`tools/probes/probe32.c`) and the engine's version (`tools/probes/probe64.c`), or for `ini` the Windows profile functions and the engine's parser (`tools/probes/ini_probe.c`), on the same inputs, and compares the results bit for bit (the 80-bit register value for `waveform`; for `pow`, the DLL's 80-bit result against the engine's double, since the DLL's result is always a double value).

CPU: Intel(R) Core(TM) i7-8850H CPU @ 2.60GHz

| Routine | Inputs compared | Different |
|---|---:|---:|
| sscanf %f | 112,872 | 0 |
| pow (_CIpow) | 474,342 | 0 |
| waveform | 280,056 | 0 |
| rand after srand(1) | 1,000,000 | 0 |
| ini, 64-bit Windows functions | 91,246 | 0 |
| ini, 32-bit Windows functions (as the DLL calls them) | 91,246 | 0 |
