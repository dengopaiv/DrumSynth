# DrumSynth: the accessible GUI

A recreation of the DrumSynth 2.0 program (`gui/`, Visual Basic 5) in C++17 with wxWidgets 3.3, on the exact C17 engine (`engine/`). It does what the original did, and is fully usable from the keyboard and with a screen reader.

- **What it must do:** [docs/gui-checklist.md](../docs/gui-checklist.md), with the status of every item.
- **How to use it:** [docs/gui-help.md](../docs/gui-help.md), which the Help button opens.

## Building

You need:
- Visual Studio with the C++ tools;
- CMake;
- wxWidgets from vcpkg (`vcpkg install wxwidgets:x64-windows`).

```
cmake -S app -B build/app -A x64 -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake
cmake --build build/app --config Release
build\app\Release\DrumSynth.exe [sound.ds]
```

vcpkg copies the wxWidgets DLLs next to `DrumSynth.exe`, and the build copies `gui-help.md` there. At first the program looks for kit folders next to itself, as the original did. **Kit → Set location** chooses another folder, such as the repository's `drumsynths/`, and the choice is remembered in `DrumSyn.ini` next to the program.

Optional: put `Tolk.dll` (and its screen reader client DLLs) next to the program. Messages such as "Saved", "Envelope pasted" or the warnings are then spoken through Tolk. Without it they go out as UI Automation notifications, which NVDA and Narrator read, and they also appear in the status bar.

## How it is made accessible

- **Native Windows controls** for everything that can be edited, in the original's tab order. Each has a visible label just before it, which MSAA reports as its name.
- **Sliders say their value text.** Each slider has its own accessible object (`ValueSlider` in `src/access.cpp`) whose value is the original's display text, such as "−6.0 dB", "Slow", "Pink (−58)" or "Q = 20", not the raw number.
- **The envelope editor**, which in the original is mouse-only, is a choice of envelope, a list of points with readable rows, time and level fields, and buttons (`src/envelope_editor.cpp`). The original's mouse graph is kept beside it.
- **Messages** are announced, and also shown in the status bar.

`tests/msaa_dump` lists what MSAA reports for every control of the running program, and fails if a focusable control has no name.

## Files

| File | What it is |
|---|---|
| `src/app.cpp` | Program entry; a `.ds` file on the command line is loaded |
| `src/main_frame.cpp` | The main window: sections, kit browser, Play/Load/Save, menus, keys (`DRUMSYN.FRM`) |
| `src/preset.cpp` | A sound as the GUI holds it, with loading and saving (`openfile`, `savefile`, `getEnv`, `putenv` in `drumsyn.bas`) |
| `src/envelope_editor.cpp` | The envelope editor and its graph |
| `src/vbtext.cpp` | VB's `Val`, `CInt`, `Format`, and the GUI's display texts (`todB`, `toTime`, the droop and slope names) |
| `src/access.cpp` | Announcements (Tolk or UI Automation) and the value-text sliders |
| `tests/preset_roundtrip.cpp` | Loads and re-saves every preset as the GUI does, and renders both |
| `tests/msaa_dump.cpp` | What a screen reader sees |

## Tests

Load and re-save all 849 presets, and render both:

```
build\app\Release\preset_roundtrip.exe LISTFILE     (one .ds path per line)
```

Result on 2026-11-08: 843 identical. The other 6 change exactly as the original GUI changes them when re-saving:
- two have Tuning, Stretch and Level all 0, so they load with Master off and are saved with Stretch 100;
- four have both filter boxes on, so they are saved with the overtones-only filter.

To test Play, run `powershell -File app/tests/smoke_play.ps1 -Ds <file.ds>`. It starts the program with the sound, presses Play through the menu command, and checks that the program is still running and has written and rendered its temporary preset. It passed on 2026-11-08 with a normal preset, and with one that makes the original hang.

### With NVDA

`powershell -File app/tests/nvda_speech.ps1 -Ds <file.ds>` drives the program with the keyboard under a portable NVDA, and prints what NVDA spoke from its log (level 12).

It **terminates a running NVDA** for about a minute. It always restarts the installed NVDA afterwards if none is running. It also refuses to send a key while DrumSynth isn't the foreground window, so keys never go elsewhere.

Result on 2026-11-08 (NVDA 2026.3):

| Steps | What NVDA spoke |
|---|---|
| Tab through Play, Kits, Sounds, Load, Save | "Kits: list, Acoustic", "Sounds … list, Brush1" |
| Tab through the Tone section | "Tone grouping", "Tone on check box checked", "Tone level slider −12.7 dB", then "−12.5 dB" and "−10.8 dB" as it moves |
| Text fields and Droop | "Start frequency: edit 180"; "Droop slider Linear", "Fast" |
| The point list (Ctrl+E), adding a point (Ctrl+N), then Time and Level | "Points: list, Point 1 of 4: 0 ms, Mute"; "Added Point 3 of 5: 7.778 ms, −4.4 dB"; "Time (samples): edit 343", "344" |
| Copy, the Envelope list (Alt+V), Overtones on (Alt+O) and Space, the Kit menu | "Tone envelope copied"; "Envelope: combo box Tone", "Noise"; "Overtones on check box checked", "not checked"; "Kit subMenu", "Generate all WAVs" |

Problems the test found, all fixed:
- Tab didn't move at all.
- Focus was lost when the window was activated again.
- Insert, the NVDA key, couldn't add points: Ctrl+N does now.
- Alt shortcuts didn't reach the section controls, and Alt+E was claimed twice.
- Empty lists read "unknown".
- Announcements didn't reach NVDA: they do now through Tolk, which the build copies from `C:\GIT\environment	olk` when it is there.

JAWS was not available to test, and Narrator was not tested.

### What MSAA reports

To see what a screen reader sees, start the program, then run:

```
build\app\Release\msaa_dump.exe "DrumSynth"
```
