# The original GUI: feature checklist

Everything the DrumSynth 2.0 program does, from its Visual Basic 5 source:
- `gui/DRUMSYN.FRM`, the main window;
- `gui/drumsyn.bas`, file reading and writing, and drawing;
- `gui/fileform.frm`, the "Save As" dialog;
- `gui/genform.frm`, "Generating WAV files";
- `gui/drumdir.frm`, the location dialog;
- `help/drumsyn.rtf`, the help text.

Written 2026-11-08.

Each item names the original control (`name`) and how the new wxWidgets GUI (`app/`) provides it. The new GUI must:
- do everything listed here;
- write the same `.ds` files;
- be fully usable from the keyboard and with a screen reader (decided 2026-11-08, [plan.md](plan.md)).

The **Status** column is filled in by the GUI work: ✓ done, ✗ left out on purpose (with the reason).

## 1. Window and layout

| # | Original | Accessible equivalent | Status |
|---|---|---|---|
| 1.1 | One window, "DrumSynth 2.0", all controls on one page; layout by section with coloured frames (`Shape1`) | One window. Each section is a named group (static box) whose controls follow in tab order. The section colours appear in the envelope graph only. | ✓ |
| 1.2 | Title: `<Name> - DrumSynth` after loading or saving; `[DrumSynth v2.0]` and digits while loading; `NN%` while rendering (the DLL's `SetWindowText`) | The same title. Loading and rendering are quick, so instead of the changing title the result goes to the status bar: "Loaded …", "Rendered 0.32 seconds". | ✓ |
| 1.3 | Tab order (`TabIndex`): Play, kit list, sound list, Load, Save, then Tone, Overtones, Noise, Noise Band 1, Noise Band 2, Distortion, Filter, Master, envelope, comment, Help | The same order. The envelope editor sits after the sections. | ✓ |
| 1.4 | Warning triangle (`warning`) next to Play when reading, writing or playing fails | A status bar message, also announced | ✓ |
| 1.5 | Window position saved in `DrumSyn.ini` next to the program (`[Window] X, Y`) | The same file and keys | ✓ |
| 1.6 | 256/16-colour screens get grey frames | ✗ not needed today | ✗ |
| 1.7 | Help button `?` opens `drumsyn.hlp` (WinHelp, which Windows no longer supports) | Help opens `docs/gui-help.md`, the help text converted to Markdown, or the help folder | ✓ |

## 2. Sections and their controls

Levels are scroll bars 1–181 (`sliLev(0..4)`, LargeChange 9). The label beside each shows `todB(level²)` = 20·log₁₀(level²/32767) with one decimal, or "Mute" when below 1. So 128 shows as "−6.0 dB" and 181 as "0.0 dB".

| # | Section | Control (original name) | Range / values | Saved as |
|---|---|---|---|---|
| 2.1 | Tone | On (`chkOn(0)`) | check | `[Tone] On` 0/1 |
| 2.2 | | Level (`sliLev(0)`) | 1–181, dB label | `Level` |
| 2.3 | | F1 (`txtTF1`) "Hz to" F2 (`txtTF2`) "Hz" | free text, as typed | `F1`, `F2` |
| 2.4 | | Droop (`sliTDroop`) | 0–100; label "Linear" <2, "Slow" <25, "Exp" <66, else "Fast" | `Droop` |
| 2.5 | | Phase (`txtTPhase`), "Degrees phase at start" | free text | `Phase` |
| 2.6 | Overtones | On (`chkOn(2)`) | | `[Overtones] On` |
| 2.7 | | Level (`sliLev(2)`) | 1–181 | `Level` |
| 2.8 | | A: frequency (`txtOF1`), wave (`comOW1`), Tracking (`chkOTrack1`) | wave: Sine, Sine², Tri, Saw, Square (0–4) | `F1`, `Wave1`, `Track1` |
| 2.9 | | B: frequency (`txtOF2`), wave (`comOW2`), Tracking (`chkOTrack2`) | | `F2`, `Wave2`, `Track2` |
| 2.10 | | Method (`comOMethod`) | "A + B", "A . B (freq modulation)", "A x B (ring modulation)", "A....B (cymbal tones)" (0–3) | `Method` |
| 2.11 | | Param (`sliOParam`) | 0–100; label "Mix" (method 0), "Depth" (1, 2), "Reson." (3) | `Param` |
| 2.12 | | Tracking is enabled only while Tone is on; method 3 disables both tracking boxes and both wave lists | | |
| 2.13 | Noise | On (`chkOn(1)`) | default **on** for a new sound | `[Noise] On` |
| 2.14 | | Level (`sliLev(1)`) | 1–181 | `Level` |
| 2.15 | | Slope (`sliNSlope`) | −100–100, SmallChange 2; label "Red" < −80, "Pink" < −20, "White" < 20, "Azure" < 80, else "Blue" | `Slope` |
| 2.16 | | "always same random sequence" (`chkFixedRandom`) | default on. **The engine ignores it** (findings, section 1). | `FixedSeq` |
| 2.17 | Noise Band 1 | On (`chkOn(3)`), Level (`sliLev(3)`), centre frequency (`txtNF`) "Hz centre frequency", Width (`sliNdF`) 0–100 | | `[NoiseBand] On, Level, F, dF` |
| 2.18 | Noise Band 2 | On (`chkOn(4)`), Level (`sliLev(4)`), frequency (`txtNF2`), Width (`sliNdF2`) | | `[NoiseBand2] …` |
| 2.19 | Distortion | On (`chkOn(5)`); Clipping (`sliDist`) 0–60 with label "−N dB"; Bits (`comDB`) "[none]", "14 bit" … " 2 bit" (0–7); Rate (`comDF`) "[none]", "11 kHz", " 7 kHz", " 5 kHz", " 4 kHz", " 3 kHz", " 2 kHz", " 1 kHz" (0–7) | | `[Distortion] On, Clipping, Bits, Rate` |
| 2.20 | Filter | Filter (`MasterFilter`), Filter overtones only (`chkOFilter`), High-pass (`chkHPF`), Resonance (`sliFres`) 0–99 with label "Q = n" | | see 2.22 |
| 2.21 | Master | Master (`chkMasterOn`); Tuning (`MasterTune`) "Semitones transpose", text; Stretch (`MasterLength`) "% Timestretch", text; Level (`sliMasterdB`) −20–20 with label "+n dB" / "n dB" | | `[General] Tuning, Stretch, Level` |
| 2.22 | Filter saving | `[General] Filter` = Filter box if "overtones only" is off, else 0. `[Overtones] Filter` = "overtones only" if Filter is on, else 0. On loading, `[Overtones] Filter=1` also ticks Filter. | | |
| 2.23 | Master saving | With Master off: Tuning 0, Stretch 100, Level 0 | | |
| 2.24 | Master on loading | Master is ticked unless Tuning, Stretch **and** Level are all 0. Since Stretch is normally 100, loading almost always ticks it. This is an original quirk, kept. | | |
| 2.25 | Comment (`comment`) | free text; when focused, all text is selected. A new window shows one of five tips (by `Timer`). | | `[General] Comment` |
| 2.26 | Play is disabled when none of the five sound sections is on | | | |

All sections: **any change** marks the sound as not rendered (`changed()`, `playable = False`). Play then renders it again. A change to a section that is off doesn't count, except for the On boxes.

Status for section 2: ✓ (all items; see the notes in section 8).

## 3. The envelope editor

| # | Original | Accessible equivalent | Status |
|---|---|---|---|
| 3.1 | Seven envelopes: 1 Tone, 2 Noise, 3 Overtone A / level, 4 Overtone B / modulation depth / frequency range (method 3), 5 Noise Band 1, 6 Noise Band 2, 7 Filter frequency. Names change with the overtone method (`ShowEnvName`). | An "Envelope" choice list with the same names, updated with the method | ✓ |
| 3.2 | Selecting: arrow buttons at the bottom left (`imgEnvSel`, cycling 1–7); right-clicking a section's On box; ticking a section on; ticking Filter selects envelope 7. The original also moves the keyboard focus to the section's On box. | The choice list. Ticking a section's On box selects its envelope, as in the original. For Overtones that is envelope 3, or 4 when envelope 3 is current (`chkOn_MouseUp` maps index 6 to envelope 4). The focus is not moved: a jumping focus disorients screen reader users. | ✓ |
| 3.3 | Zoom: 13 ranges, 16 ms, 25, 40, 63, 100, 160, 250 (default), 400, 630 ms, 1 s, 1.6 s, 3 s, 10 s (`imgEnvRange`, `txtEnvRange`) | A "View range" choice list; it affects the graph only | ✓ |
| 3.4 | Graph: the current envelope in black with point boxes; the other active envelopes in their section colours. The filter envelope's last segment isn't drawn: "it continues forever". | The same graph, for sighted users | ✓ |
| 3.5 | Point values: time in samples, level 0–100. Shown while dragging as `toTime(t): todB(level · 327.67)`, or `%` for envelopes 4 and 7. `toTime`: "0 ms"; below 10 ms "0.000 ms"; below 100 ms "0.0 ms"; else "0 ms". | A **point list**: one row per point, "Point n: time, level", with the same time and dB/% texts. A time field (ms) and a level field (0–100) edit the selected point. | ✓ |
| 3.6 | Click on empty space: insert a point there, if the envelope has fewer than 31 points (`ep < 30`); otherwise beep | "Add point" inserts after the selected point, halfway to the next; the same limit, with an announced message | ✓ |
| 3.7 | Drag a point: it stays between its neighbours; the first point stays at time 0; the last can move up to the right edge; levels 0–100 | Editing the fields enforces the same limits | ✓ |
| 3.8 | **The last point's level is always 0** (dragging forces Y = 0 when there is no next point) | Enforced: the last point's level field is 0 and read-only | ✓ |
| 3.9 | Delete: drag a point off the top or bottom of the box; not the first or last point | "Delete point" (and the Delete key in the list), with the same rule | ✓ |
| 3.10 | Right-click menu: Copy, Paste (enabled after a Copy), Reset, Cancel | Buttons and keys: Copy (Ctrl+C in the list), Paste (Ctrl+V), Reset | ✓ |
| 3.11 | **Copy/Paste copy only points 0–18** (19 points and their end marker if it falls within). An envelope with more points is cut when pasted. Original quirk. | Kept, because the result is what the original saved. Documented in the help. | ✓ |
| 3.12 | Reset: envelopes 1–6 become `0,100  (1−e/8)·6000,30  (1−e/8)·12000,0`; filter `0,100 442000,100 442000,0` | The same | ✓ |
| 3.13 | New sound (`Setup`): envelopes 1–6 `0,100 (1−c/8)·2000,20 (1−c/8)·6000,0`, with c = 6 for envelope 2 and c = 2 for envelope 6; filter `0,100 444000,100 444000,0` | The same | ✓ |
| 3.14 | Saving: each point as `Format(t,"0"),Format(l,"0")` followed by a space. Times and levels are written as whole numbers. | The same text. The editor works in whole samples and whole levels. | ✓ |
| 3.15 | Loading: VB `Val()` of each token | The same values for every preset (whole numbers; decimals are kept). | ✓ |

## 4. Files and kits

| # | Original | Accessible equivalent | Status |
|---|---|---|---|
| 4.1 | A location folder (`DS_PATH`, `[Files] Path` in `DrumSyn.ini`, default the program folder) holding kit folders | The same | ✓ |
| 4.2 | Kit list (`kitList`): subfolders, first letter upper-cased; names with a character below `A` (other than space) shown all upper case | A list box with the same names | ✓ |
| 4.3 | Sound list (`fileList`): the kit's `.ds` files without extension, then `.wav` files that have no `.ds`, shown lower case with a trailing space marking them | The same entries. WAV-only entries are described as "(WAV only)" for screen readers. | ✓ |
| 4.4 | Clicking a sound plays its WAV; Load is disabled for WAV-only entries; double-click or right-click while holding loads it | Selecting plays (Space or Enter in the list); Load button; WAV-only entries can't be loaded. A sound with a `.ds` is synthesized from it instead of playing its WAV (section 5). | ✓ |
| 4.5 | Load (`butLoad`): reads every key, with the defaults listed in `openfile` | The same | ✓ |
| 4.6 | Save (`butSave`): asks for a name (`fileform`: "Save As…", with a "Save .WAV" box). The name may not contain `. \ / : * ? " < > \|`. If a WAV of that name exists without a `.ds`, it asks "Overwrite Existing .WAV File?" Then it writes the `.ds` with `WritePrivateProfileString` (keys updated in place in an existing file) and **always** writes the WAV: it copies the last render, or renders. The "Save .WAV" box is remembered (`[Files] SaveWAVs`) but never used, an original quirk. | The same dialog and checks. The WAV is written when "Save .WAV" is ticked, which is what the box says (a deliberate fix, noted in the help). | ✓ |
| 4.7 | Play (`butPlay`), Enter, or Ctrl: writes a temporary `.ds` (`DrumSyn-.tmp`), renders it (`DrumSyn~.tmp`) with the progress in the title, and plays it with `PlaySound`. If nothing changed since the last render, it only plays. | The same, with the C17 engine | ✓ |
| 4.8 | F1–F12 play the first twelve sounds in the list, Shift+F1–F12 the next twelve (`Form_KeyDown`) | The same keys, synthesizing from the `.ds` (section 5) | ✓ |
| 4.9 | Right-click menu on the sound list: Generate All WAVs, "Delete WAVs (size k)", Delete File, New Kit…, Set Location…, Cancel | A "Kit" menu in the menu bar with the same items, plus the same context menu | ✓ |
| 4.10 | Generate All WAVs (`genform`): renders every `.ds` in the kit whose WAV is missing, with a progress bar and Cancel | A progress dialog with Cancel | ✓ |
| 4.11 | Delete WAVs: deletes the WAV of every sound that has a `.ds`, without asking | The same, after a confirmation (deleting without asking is not accessible) | ✓ |
| 4.12 | Delete File: asks "Delete this sound?", then deletes the `.ds` and `.wav` (only the `.wav` for WAV-only entries) | The same | ✓ |
| 4.13 | New Kit…: asks for a name, makes the folder, adds it upper-cased and selects it | The same | ✓ |
| 4.14 | Set Location… (`locform`): a drive and folder picker, "Select a folder that contains folders of .DS files" | A folder picker | ✓ |
| 4.15 | A `.ds` file given on the command line is loaded at start | The same | ✓ |
| 4.16 | On exit: saves window position, path and SaveWAVs; deletes the temporary files | The same | ✓ |

## 5. Keyboard

The original sets `KeyPreview` on the form:
- **Enter, or the Ctrl key alone,** plays.
- **F1–F12** play sounds from the list.

Everything else is mouse only: the envelope editing, the envelope selection and zoom, and the menus.

The new GUI provides all of that from the keyboard:
- Tab and Shift+Tab move between controls, in the order of 1.3.
- Each control has a name that screen readers announce, including its unit.
- Sliders announce their value text (−6.0 dB, Slow (10), Pink (−58), Q = 20…), not only the raw number. Where the original shows only a name (Droop, Slope), the number follows it: every step sounds different, and a sighted user sees the slider's position, which the name alone doesn't tell.
- Changed on purpose:
- **Ctrl alone does not play.** In the original, the Ctrl key on its own plays the sound (`Form_KeyDown`). Screen reader users press Ctrl to stop speech, so it would play constantly. Enter and Ctrl+P play instead. ✗
- **Kit sounds are synthesized, not read from WAV files.** In the original, clicking a sound and F1–F12 play the sound's WAV file, which exists only after Save or Generate All WAVs: the engine was a separate DLL that wrote files. The engine is part of the program now, so a sound with a `.ds` file is rendered from it into memory and played, and nothing is written into the kit. The result is the WAV the original would have generated, byte for byte. A WAV-only sound still plays its file. The renders of the kit shown are kept, so pressing a key again plays at once; a `.ds` changed since is rendered again. ✗

- **Alt+letter shortcuts** are unique across the window. Windows' own dialog handling doesn't reach controls inside the section group boxes, so the main window handles them, as Windows would: a button is pressed, a check box is focused and toggled.
- **Ctrl+N adds an envelope point.** Insert does too, but Insert is the NVDA key.

Menu accelerators:

| Keys | Action |
|---|---|
| Ctrl+O | Load |
| Ctrl+S | Save |
| Ctrl+P | Play, as well as Enter (and Ctrl alone in the original). F5 stays the fifth sound, as in the original. |
| Ctrl+E | Go to the envelope point list |
| Ctrl+K | Go to the kit list |

Enter keeps its normal meaning on buttons and in lists. In the sound list it plays the selected sound.

## 6. Values the original GUI cannot show

VB scroll bars raise an error for a value outside their range, and `openfile` ignores errors (`On Error Resume Next`). So such a preset loads with the control unchanged, and saving it again writes the old value.

The new GUI keeps the preset's value instead, whatever it is, and saves it unchanged. The slider shows the nearest value it can, and its label says "(out of range: 200)". Then loading and saving a preset doesn't change it.

The same goes for list indices out of range: Wave, Method, Bits and Rate.

## 7. Presets that freeze the original

A tone envelope with one point plus tracked triangle overtones makes the original hang (findings, section 9). Decided 2026-11-08: **warn but allow**. After a render, the GUI announces the engine's notes:
- "The original DrumSynth would hang on this sound";
- "reads memory it shouldn't".

## 8. Notes

- The original writes values with `WritePrivateProfileString`, which updates an existing file in place and keeps keys it doesn't know. The new GUI uses the same function, so files keep their extra keys.
- **Re-saving changes 6 of the 849 presets**, in the original as in the new GUI (tested with `app/tests/preset_roundtrip`):
  - 0389 and 0405 have Tuning, Stretch and Level all 0. Master loads as off (2.24), and the sound is saved with Stretch 100 instead of 0, which the engine treats as 20%.
  - Four presets have `[General] Filter=1` and `[Overtones] Filter=1`. They load with both boxes ticked and are saved with the overtones-only filter (2.22).

  This is the original's behaviour and is kept. The help says so.
- **Text fields are saved as typed** (F1 "200", Tuning "-1.5"). The engine reads them with VC6's `sscanf` rules (findings, section 7), so "200 Hz" or "1e3" mean what they meant to the original. `parsefreq()` in `drumsyn.bas`, which reads note names like "C3", is never called by the original. It is not used.
