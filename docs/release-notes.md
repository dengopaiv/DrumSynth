# Release notes

## DrumSynth 4.0.0, accessible edition (2026-11-08)

A new DrumSynth, built from the ground up to be **exact** and **accessible**:
- the sound engine reproduces the original DrumSynth 2.0 (Paul Kellett, 2000) byte for byte;
- the program can be used entirely from the keyboard and with a screen reader.

It replaces the 3.0 "Modern WPF Edition", which stays on the `modern-wpf` branch for reference.

### Download

`DrumSynth-4.0.0-win64.zip`, for Windows 10 or 11, 64-bit. Unzip it anywhere and start `DrumSynth.exe`; nothing is installed. The `Kits` folder holds 31 kits: the DrumSynth 2.0 library and later presets.

### The engine: exactly the original's sound

- A rewrite in C17 of the original `ds2wav.dll`, transcribed from its machine code. It follows every rounding the 2000 compiler made, the x87 instructions for `sin`, `cos`, `pow` and `exp`, and Visual C++ 6's number reading. See [findings.md](findings.md) and [disasm/README.md](disasm/README.md).
- Byte for byte identical WAV files to the original DLL on:
  - all 849 presets;
  - 454 single-feature test presets;
  - the 1995 of 2000 random presets the original can render.
- The original hangs on the other 5. The new engine renders them, and the program warns: one example is a tone envelope with a single point together with tracked triangle overtones.
- The rewrite follows the original's own bugs where they shape the sound. Where the original depends on leftover memory, the rewrite uses its defined "first sound after start". The original's differences between renders, and its uninitialized overtone value, are gone.

### The program: everything the original did, accessible

- All sections and controls of DrumSynth 2.0, the kit and sound browser, Play, Load, Save, Generate and Delete WAVs, New Kit and Set Location, and F1 to F12 to play sounds. Kit sounds are synthesized from their `.ds` files as you play them, so the kits need no WAV files. The full list is in [gui-checklist.md](gui-checklist.md).
- Native Windows controls in a logical tab order, each with a name.
- Sliders speak the original's value texts: "−6.0 dB", "Slow", "Pink (−58)", "Q = 20".
- **An envelope editor that works without a mouse:**
  - a list of points read as "Point 2 of 3: 45.4 ms, −14.0 dB";
  - time and level fields;
  - Add, Delete, Copy, Paste and Reset (Ctrl+N, Delete, Ctrl+C, Ctrl+V);
  - **envelope files**, new in this edition: Save envelope (Ctrl+Shift+S) keeps an envelope shape in a `.dse` file, Load envelope (Ctrl+Shift+O) puts one into any envelope of any sound, and Load envelope from sound takes an envelope out of another sound.

  The original's mouse graph is still there.
- Messages ("Saved", "Envelope copied", warnings) are spoken through NVDA (Tolk), or sent as UI Automation notifications, and shown in the status bar.
- **Tested** with NVDA by what it actually spoke. What UI Automation reports, which Narrator reads, was also checked. JAWS was not tested.
- Sounds are saved exactly as the original saved them. As in the original, re-saving rounds envelope values to whole numbers. Two other original rules are kept as well: a sound with Tuning, Stretch and Level all 0 is saved with Master off, and with both filter boxes on it is saved with the overtone filter.

### Differences from the original program

- The Ctrl key on its own no longer plays the sound, because screen reader users press it to stop speech. Enter and Ctrl+P play.
- Clicking a sound in the kit, or pressing F1 to F12, synthesizes it from its `.ds` file. The original played the sound's WAV file, which had to be generated first.
- "Save .WAV" in the Save dialog now decides whether the WAV is saved. The original always saved it.
- Envelopes can be saved and loaded on their own, and taken from another sound. The original could only copy an envelope within the sound being edited.
- Help is a Markdown file, `gui-help.md`, instead of WinHelp, which today's Windows can't open.

### Known limits

- The x87 instructions for `sin`, `cos` and `log` may differ in their last bit on other processor models. The reference checksums were made on an Intel Core i7-8850H; on another CPU, `tools/check_reference.py` shows whether the output is still identical.
- Files with NUL bytes or a byte order mark aren't read the way Windows reads them. No preset has either.

### Licence

MIT, or the GNU GPL version 2 or (at your option) any later version. Third-party components are listed in `licenses/THIRD-PARTY.txt` in the download:
- wxWidgets and the image libraries it uses;
- Tolk and NVDA's controller client (LGPL);
- the Microsoft Visual C++ runtime.

### Building it yourself

See [../app/README.md](../app/README.md) and [../engine/README.md](../engine/README.md). `python tools/make_release.py` builds, tests and packages a release.
