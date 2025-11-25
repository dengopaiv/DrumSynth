# Building DrumSynth 3.0 (Modern Edition)

## Prerequisites

### For the WPF Application
- .NET 8.0 SDK or later
- Visual Studio 2022 (optional, for IDE)

### For the Native Synthesis Engine
- CMake 3.20 or later
- MSVC (Visual Studio 2019/2022) or MinGW-w64

## Quick Build

### Windows (PowerShell)

```powershell
# Build the C# application
cd src/DrumSynth.App
dotnet restore
dotnet build -c Release

# Build the native DLL (using MSVC)
cd ../DrumSynth.Core
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release

# Copy DLL to app output
copy build\Release\ds2wav.dll ..\DrumSynth.App\bin\Release\net8.0-windows\
```

### Build Native DLL with CMake

```bash
cd src/DrumSynth.Core
mkdir build && cd build
cmake ..
cmake --build . --config Release
```

## Project Structure

```
DrumSynth/
├── src/
│   ├── DrumSynth.Core/     # C synthesis engine (cross-platform)
│   │   ├── drumsynth.c     # Main synthesis code
│   │   ├── drumsynth.h     # Public API header
│   │   └── CMakeLists.txt  # CMake build
│   │
│   └── DrumSynth.App/      # WPF Application (.NET 8)
│       ├── MainWindow.xaml # Main UI (accessible)
│       ├── Native/         # P/Invoke bindings
│       └── Services/       # Audio playback
│
├── bin/                    # Original binaries & presets
│   └── library.zip         # Preset sound library
│
├── DrumSynth.sln          # Visual Studio solution
└── BUILD.md               # This file
```

## Running the Application

1. Build both the native DLL and the .NET application
2. Ensure `ds2wav.dll` is in the same folder as `DrumSynth.exe`
3. Extract `bin/library.zip` to a `library` folder next to the executable
4. Run `DrumSynth.exe`

## Accessibility Features

The modern edition includes full accessibility support:
- All controls have screen reader labels (NVDA, Narrator, JAWS compatible)
- Full keyboard navigation
- High contrast color scheme
- Logical tab order

## Fallback Mode

If the native DLL is not available, the application will:
- Load and save .DS preset files using a managed INI parser
- Display the UI but synthesis will be silent
- Show "Native DLL not found" in version info

## License

Original DrumSynth (c) 1998-2000 Paul Kellett
MIT / GPL-2.0 dual license
