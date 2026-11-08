# DrumSynth docs

Reference material for the faithful, screen-reader-accessible DrumSynth recreation. The original DrumSynth 2.0 source (`drumsynth.c`, `gui/`) and binary (`bin/ds2wav.dll`) are the specification for sound and features.

| Document | What's in it |
|---|---|
| [plan.md](plan.md) | Goal, decisions with dates and reasons, what's done, what's next |
| [rewrite-plan.md](rewrite-plan.md) | How the C17 engine will be made to match the original exactly: what has to match, how each part is checked, phases, risks |
| [disasm/](disasm/README.md) | The original DLL's machine code, annotated, and what it does that the source doesn't show: every rounding point, reordering, constant and runtime routine |
| [reference/](reference/probes.md) | Reference data: the probe results (DLL routines vs the engine's, bit for bit), Windows' `.ds` reading rules ([ini-rules.md](reference/ini-rules.md)), and the checksums of all reference renders ([checksums.csv](reference/checksums.csv)) |
| [findings.md](findings.md) | How the original engine really behaves, measured: the reference, x87 precision, the uninitialized `Ot`, state carried between renders, and what the C17 rewrite has to do |
| [rendering.md](rendering.md) | How to build the renderers, render all presets and compare two engines |
| [reports/](reports/README.md) | The render comparison reports, with a table of what each one shows |
| [envelopes/](envelopes/README.md) | Library of envelope shapes found in the presets, one file per envelope type, in `.ds` syntax |

The tools themselves are listed in [../tools/README.md](../tools/README.md); the engine is described in [../engine/README.md](../engine/README.md).
