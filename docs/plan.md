# Plan

Decisions and the order of work for this repository. Newest decisions are recorded with their date. The reasoning behind the engine work is in [findings.md](findings.md).

## Goal

A **faithful recreation of mda DrumSynth 2.0** (Paul Kellett, 2000) that is **fully usable with a screen reader**. The original source (`drumsynth.c` and `gui/` from commit `d0ac0c7`) and the original binary (`bin/ds2wav.dll`) are the specification, for the sound and for the features.

## Decisions

| Date | Decision | Why |
|---|---|---|
| 2026-11-08 | **DrumSynth stays separate from Tiktaalik.** Tiktaalik is a Paleozoic Soundsystem product with its own engine; `.ds` presets are eventually not meant to be compatible with it, and its DrumSynth loader was removed. | Different purposes: fidelity here, a new instrument there. |
| 2026-11-08 | **This repository (github.com/dengopaiv/DrumSynth) is the upstream.** No other DrumSynth project is being developed. All presets are kept here: `bin/library.zip` (the 2.0 distribution) and `drumsynths/` (a later collection, 86 presets found nowhere else). | Nowhere else to keep them. |
| 2026-11-08 | **The engine is rewritten in C17, 64-bit, Windows only.** C23 is possible if it stays Windows only. The rewrite becomes one of the renderers in the render comparison and is judged against the original DLL. | The engine must sound like the original. The comparison is the only way to prove that. |
| 2026-11-08 | **The GUI will use wxWidgets.** | On Windows it uses the native controls, which screen readers support well. The envelope editor is built from standard controls (a point list), with any graph only for sighted users. |
| 2026-11-08 | **The reference is the original DLL at the Windows default x87 precision, each preset rendered as the first sound after start, with the stack cleared.** | Findings sections 3–5: the original's output depends on precision, on the previous render and on uninitialized memory. This is the defined, reproducible version of its sound. |
| 2026-11-08 | **Document everything.** Over-documenting is better than under-documenting. | The repository is the record of the research. |
| 2026-11-08 | Work happens on the `refactor` branch. | |
| 2026-11-08 | **The engine aims to be as exact as possible: identical to `ref`, sample for sample.** Not "higher precision than the original": the original's roundings are part of its sound. The method is in [rewrite-plan.md](rewrite-plan.md). | "The more precision we have, the better." |
| 2026-11-08 | **Where the original hangs, the engine renders and flags** (`DS_NOTE_HANG`): it produces a sound and never freezes. | User's choice, from three options: render and flag, refuse with an error, or render silence. |
| 2026-11-08 | **The GUI warns but allows** combinations that freeze the original, such as a one-point tone envelope with tracked triangle overtones. The editor allows what the original allowed, and announces a warning when the engine flags a note. | Faithful to the original's editor, and accessible: the warning is announced. |
| 2026-11-08 | **Testing on other CPUs is postponed.** It stays an open item. | No other machine available now. |

## Done

- **Envelope library:** 461 envelope shapes used 3 or more times, one file per envelope type, in `.ds` syntax, with names that read well aloud. See [envelopes/README.md](envelopes/README.md).
- **Preset collections** committed (`drumsynths/`), with the 6 WAVs the original program saved.
- **Render comparison:**
  - three renderers: the original DLL, the original source, and the modern port;
  - batch rendering, sample-by-sample comparison, and reports grouped by feature.
  - See [rendering.md](rendering.md) and [reports/](reports/README.md).
- **Findings** about the original engine: the reference renderer reproduces the original program; x87 precision; the uninitialized `Ot`; envelope state carrying over between renders. See [findings.md](findings.md).

- **The exact C17 engine** (`engine/`, 2026-11-08), following [rewrite-plan.md](rewrite-plan.md).
  - It is byte-identical to the original DLL on all 849 presets, 454 single-feature presets and 1995 random presets.
  - On the other 5 random presets the DLL hangs. The engine renders them and flags them: findings, section 9. A one-point tone envelope with tracked triangle overtones freezes the original. Decided: the engine renders and flags it, and the GUI warns but allows it.
  - Its routines agree bit for bit with the DLL's own on about 1.9 million inputs.
  - The checksums are frozen as its regression test (`tools/check_reference.py`).
  - The analysis of the machine code is in [disasm/README.md](disasm/README.md).

- **The GUI feature checklist** ([gui-checklist.md](gui-checklist.md), 2026-11-08): every control, range, menu, key, envelope-editor rule and file behaviour of the original GUI, with the accessible equivalent of each and its status.
- **The accessible wxWidgets GUI** (`app/`, 2026-11-08), built on `engine/` against the checklist.
  - Every item of the checklist is done, except two left out on purpose: grey frames for 16-colour screens, and Ctrl alone playing, which conflicts with screen readers.
  - Envelopes are edited with a point list, fields and buttons, with the original's mouse graph beside them.
  - Sliders announce their value text.
  - MSAA reports a name for every focusable control (`app/tests/msaa_dump`).
  - Loading and re-saving all 849 presets: 843 identical, and 6 change exactly as the original GUI changes them (`app/tests/preset_roundtrip`).
  - Help: [gui-help.md](gui-help.md).

## Next

1. **Check the engine on other processors** (an AMD one and a recent Intel one) with `tools/check_reference.py`. Postponed, 2026-11-08. The x87 transcendental instructions may differ in their last bit between models (findings, section 9).
2. **Screen readers.** NVDA was tested on 2026-11-08 with `app/tests/nvda_speech.ps1` (results in `app/README.md`); the problems it found are fixed. Still to do:
   - JAWS: not installed here;
   - Narrator: what UI Automation reports was checked with `app/tests/uia_dump` (correct types, names and slider texts), but Narrator's speech was not heard;
   - longer real sound design work, to tune wording and announcements.

## The existing WPF port

The `modern-wpf` branch has a C#/WPF app (`src/DrumSynth.App/`) on top of the modern port of the engine. It is kept for reference but isn't the way forward. Problems found in it:

- **Bits and Rate:** only 4 choices each, where presets use 0–7. That affects 165 presets.
- **Number fields** are rounded to whole numbers. That affects 78 presets.
- **No envelope editing.**
- **Number parsing depends on the system locale.**
