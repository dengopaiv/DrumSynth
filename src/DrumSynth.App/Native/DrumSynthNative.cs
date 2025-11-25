using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace DrumSynth.Native;

/// <summary>
/// Parameters structure matching the native DrumSynthParams
/// </summary>
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
public struct DrumSynthParams
{
    // General
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
    public string Comment;
    public float Tuning;
    public float Stretch;
    public float Level;

    // Tone
    public int ToneOn;
    public int ToneLevel;
    public float ToneF1;
    public float ToneF2;
    public float ToneDroop;
    public float TonePhase;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 512)]
    public string ToneEnvelope;

    // Noise
    public int NoiseOn;
    public int NoiseLevel;
    public int NoiseSlope;
    public int NoiseFixedSeq;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 512)]
    public string NoiseEnvelope;

    // Overtones
    public int OverOn;
    public int OverLevel;
    public float OverF1;
    public float OverF2;
    public int OverWave1;
    public int OverWave2;
    public int OverTrack1;
    public int OverTrack2;
    public int OverMethod;
    public int OverParam;
    public int OverFilter;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 512)]
    public string OverEnvelope1;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 512)]
    public string OverEnvelope2;

    // Noise Band 1
    public int Band1On;
    public int Band1Level;
    public float Band1F;
    public int Band1Df;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 512)]
    public string Band1Envelope;

    // Noise Band 2
    public int Band2On;
    public int Band2Level;
    public float Band2F;
    public int Band2Df;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 512)]
    public string Band2Envelope;

    // Distortion
    public int DistOn;
    public int DistClipping;
    public int DistBits;
    public int DistRate;

    // Filter
    public int FilterOn;
    public int FilterHighpass;
    public int FilterResonance;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 512)]
    public string FilterEnvelope;
}

/// <summary>
/// P/Invoke wrapper for the native DrumSynth DLL
/// </summary>
public static class DrumSynthNative
{
    private const string DllName = "ds2wav.dll";

    [DllImport(DllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "ds_init_params")]
    private static extern void NativeInitParams(ref DrumSynthParams parameters);

    [DllImport(DllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "ds_load_file", CharSet = CharSet.Ansi)]
    private static extern int NativeLoadFile(string filename, ref DrumSynthParams parameters);

    [DllImport(DllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "ds_save_file", CharSet = CharSet.Ansi)]
    private static extern int NativeSaveFile(string filename, ref DrumSynthParams parameters);

    [DllImport(DllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "ds_synthesize")]
    private static extern int NativeSynthesize(ref DrumSynthParams parameters, [Out] short[] buffer, int maxSamples);

    [DllImport(DllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "ds_estimate_length")]
    private static extern int NativeEstimateLength(ref DrumSynthParams parameters);

    [DllImport(DllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "ds_to_wav", CharSet = CharSet.Ansi)]
    private static extern int NativeToWav(string dsFile, string wavFile);

    [DllImport(DllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "ds_version")]
    private static extern IntPtr NativeVersion();

    /// <summary>
    /// Initialize parameters to default values
    /// </summary>
    public static void InitParams(ref DrumSynthParams parameters)
    {
        // Initialize with managed defaults first (in case DLL is missing)
        parameters = new DrumSynthParams
        {
            Comment = "",
            Tuning = 0.0f,
            Stretch = 100.0f,
            Level = 0.0f,
            ToneOn = 1,
            ToneLevel = 128,
            ToneF1 = 200.0f,
            ToneF2 = 120.0f,
            ToneDroop = 0.0f,
            TonePhase = 90.0f,
            ToneEnvelope = "0,100 100,30 200,0",
            NoiseLevel = 128,
            NoiseFixedSeq = 1,
            NoiseEnvelope = "0,100 100,30 200,0",
            OverLevel = 128,
            OverF1 = 200.0f,
            OverF2 = 120.0f,
            OverMethod = 2,
            OverParam = 50,
            OverEnvelope1 = "0,100 100,30 200,0",
            OverEnvelope2 = "0,100 100,30 200,0",
            Band1Level = 128,
            Band1F = 1000.0f,
            Band1Df = 50,
            Band1Envelope = "0,100 100,30 200,0",
            Band2Level = 128,
            Band2F = 3100.0f,
            Band2Df = 40,
            Band2Envelope = "0,100 100,30 200,0",
            FilterEnvelope = "0,100 442000,100 443000,0"
        };

        try
        {
            NativeInitParams(ref parameters);
        }
        catch (DllNotFoundException)
        {
            // Use managed defaults
        }
    }

    /// <summary>
    /// Load parameters from a .DS file
    /// </summary>
    public static int LoadFile(string filename, ref DrumSynthParams parameters)
    {
        try
        {
            return NativeLoadFile(filename, ref parameters);
        }
        catch (DllNotFoundException)
        {
            // Fall back to managed INI parser
            return LoadFileManaged(filename, ref parameters);
        }
    }

    /// <summary>
    /// Save parameters to a .DS file
    /// </summary>
    public static int SaveFile(string filename, ref DrumSynthParams parameters)
    {
        try
        {
            return NativeSaveFile(filename, ref parameters);
        }
        catch (DllNotFoundException)
        {
            return SaveFileManaged(filename, ref parameters);
        }
    }

    /// <summary>
    /// Synthesize audio into a buffer
    /// </summary>
    public static int Synthesize(ref DrumSynthParams parameters, short[] buffer, int maxSamples)
    {
        try
        {
            return NativeSynthesize(ref parameters, buffer, maxSamples);
        }
        catch (DllNotFoundException)
        {
            // Return silence if DLL not available
            Array.Clear(buffer, 0, buffer.Length);
            return 0;
        }
    }

    /// <summary>
    /// Estimate the output length in samples
    /// </summary>
    public static int EstimateLength(ref DrumSynthParams parameters)
    {
        try
        {
            return NativeEstimateLength(ref parameters);
        }
        catch (DllNotFoundException)
        {
            return 44100; // Default 1 second
        }
    }

    /// <summary>
    /// Convert a .DS file directly to a .WAV file
    /// </summary>
    public static int ToWav(string dsFile, string wavFile)
    {
        try
        {
            return NativeToWav(dsFile, wavFile);
        }
        catch (DllNotFoundException)
        {
            return -1;
        }
    }

    /// <summary>
    /// Get the DLL version string
    /// </summary>
    public static string GetVersion()
    {
        try
        {
            var ptr = NativeVersion();
            return Marshal.PtrToStringAnsi(ptr) ?? "Unknown";
        }
        catch (DllNotFoundException)
        {
            return "Native DLL not found";
        }
    }

    #region Managed Fallback Implementation

    private static int LoadFileManaged(string filename, ref DrumSynthParams parameters)
    {
        if (!File.Exists(filename)) return 2;

        try
        {
            var lines = File.ReadAllLines(filename);
            string currentSection = "";

            foreach (var rawLine in lines)
            {
                var line = rawLine.Trim();
                if (string.IsNullOrEmpty(line) || line.StartsWith(";")) continue;

                if (line.StartsWith("[") && line.EndsWith("]"))
                {
                    currentSection = line[1..^1];
                    continue;
                }

                var eqPos = line.IndexOf('=');
                if (eqPos < 0) continue;

                var key = line[..eqPos].Trim();
                var value = line[(eqPos + 1)..].Trim();

                SetParameter(ref parameters, currentSection, key, value);
            }

            return 0;
        }
        catch
        {
            return 2;
        }
    }

    private static void SetParameter(ref DrumSynthParams p, string section, string key, string value)
    {
        switch (section)
        {
            case "General":
                switch (key)
                {
                    case "Comment": p.Comment = value; break;
                    case "Tuning": float.TryParse(value, out p.Tuning); break;
                    case "Stretch": float.TryParse(value, out p.Stretch); break;
                    case "Level": float.TryParse(value, out p.Level); break;
                    case "Filter": int.TryParse(value, out p.FilterOn); break;
                    case "HighPass": int.TryParse(value, out p.FilterHighpass); break;
                    case "Resonance": int.TryParse(value, out p.FilterResonance); break;
                    case "FilterEnv": p.FilterEnvelope = value; break;
                }
                break;
            case "Tone":
                switch (key)
                {
                    case "On": int.TryParse(value, out p.ToneOn); break;
                    case "Level": int.TryParse(value, out p.ToneLevel); break;
                    case "F1": float.TryParse(value, out p.ToneF1); break;
                    case "F2": float.TryParse(value, out p.ToneF2); break;
                    case "Droop": float.TryParse(value, out p.ToneDroop); break;
                    case "Phase": float.TryParse(value, out p.TonePhase); break;
                    case "Envelope": p.ToneEnvelope = value; break;
                }
                break;
            case "Noise":
                switch (key)
                {
                    case "On": int.TryParse(value, out p.NoiseOn); break;
                    case "Level": int.TryParse(value, out p.NoiseLevel); break;
                    case "Slope": int.TryParse(value, out p.NoiseSlope); break;
                    case "FixedSeq": int.TryParse(value, out p.NoiseFixedSeq); break;
                    case "Envelope": p.NoiseEnvelope = value; break;
                }
                break;
            case "Overtones":
                switch (key)
                {
                    case "On": int.TryParse(value, out p.OverOn); break;
                    case "Level": int.TryParse(value, out p.OverLevel); break;
                    case "F1": float.TryParse(value, out p.OverF1); break;
                    case "F2": float.TryParse(value, out p.OverF2); break;
                    case "Wave1": int.TryParse(value, out p.OverWave1); break;
                    case "Wave2": int.TryParse(value, out p.OverWave2); break;
                    case "Track1": int.TryParse(value, out p.OverTrack1); break;
                    case "Track2": int.TryParse(value, out p.OverTrack2); break;
                    case "Method": int.TryParse(value, out p.OverMethod); break;
                    case "Param": int.TryParse(value, out p.OverParam); break;
                    case "Filter": int.TryParse(value, out p.OverFilter); break;
                    case "Envelope1": p.OverEnvelope1 = value; break;
                    case "Envelope2": p.OverEnvelope2 = value; break;
                }
                break;
            case "NoiseBand":
                switch (key)
                {
                    case "On": int.TryParse(value, out p.Band1On); break;
                    case "Level": int.TryParse(value, out p.Band1Level); break;
                    case "F": float.TryParse(value, out p.Band1F); break;
                    case "dF": int.TryParse(value, out p.Band1Df); break;
                    case "Envelope": p.Band1Envelope = value; break;
                }
                break;
            case "NoiseBand2":
                switch (key)
                {
                    case "On": int.TryParse(value, out p.Band2On); break;
                    case "Level": int.TryParse(value, out p.Band2Level); break;
                    case "F": float.TryParse(value, out p.Band2F); break;
                    case "dF": int.TryParse(value, out p.Band2Df); break;
                    case "Envelope": p.Band2Envelope = value; break;
                }
                break;
            case "Distortion":
                switch (key)
                {
                    case "On": int.TryParse(value, out p.DistOn); break;
                    case "Clipping": int.TryParse(value, out p.DistClipping); break;
                    case "Bits": int.TryParse(value, out p.DistBits); break;
                    case "Rate": int.TryParse(value, out p.DistRate); break;
                }
                break;
        }
    }

    private static int SaveFileManaged(string filename, ref DrumSynthParams p)
    {
        try
        {
            using var writer = new StreamWriter(filename);

            writer.WriteLine("[General]");
            writer.WriteLine("Version=DrumSynth v2.0");
            writer.WriteLine($"Comment={p.Comment}");
            writer.WriteLine($"Tuning={p.Tuning:F2}");
            writer.WriteLine($"Stretch={p.Stretch:F1}");
            writer.WriteLine($"Level={p.Level:F0}");
            writer.WriteLine($"Filter={p.FilterOn}");
            writer.WriteLine($"HighPass={p.FilterHighpass}");
            writer.WriteLine($"Resonance={p.FilterResonance}");
            writer.WriteLine($"FilterEnv={p.FilterEnvelope}");

            writer.WriteLine("\n[Tone]");
            writer.WriteLine($"On={p.ToneOn}");
            writer.WriteLine($"Level={p.ToneLevel}");
            writer.WriteLine($"F1={p.ToneF1:F2}");
            writer.WriteLine($"F2={p.ToneF2:F2}");
            writer.WriteLine($"Droop={p.ToneDroop:F0}");
            writer.WriteLine($"Phase={p.TonePhase:F0}");
            writer.WriteLine($"Envelope={p.ToneEnvelope}");

            writer.WriteLine("\n[Noise]");
            writer.WriteLine($"On={p.NoiseOn}");
            writer.WriteLine($"Level={p.NoiseLevel}");
            writer.WriteLine($"Slope={p.NoiseSlope}");
            writer.WriteLine($"FixedSeq={p.NoiseFixedSeq}");
            writer.WriteLine($"Envelope={p.NoiseEnvelope}");

            writer.WriteLine("\n[Overtones]");
            writer.WriteLine($"On={p.OverOn}");
            writer.WriteLine($"Level={p.OverLevel}");
            writer.WriteLine($"F1={p.OverF1:F2}");
            writer.WriteLine($"F2={p.OverF2:F2}");
            writer.WriteLine($"Wave1={p.OverWave1}");
            writer.WriteLine($"Wave2={p.OverWave2}");
            writer.WriteLine($"Track1={p.OverTrack1}");
            writer.WriteLine($"Track2={p.OverTrack2}");
            writer.WriteLine($"Method={p.OverMethod}");
            writer.WriteLine($"Param={p.OverParam}");
            writer.WriteLine($"Filter={p.OverFilter}");
            writer.WriteLine($"Envelope1={p.OverEnvelope1}");
            writer.WriteLine($"Envelope2={p.OverEnvelope2}");

            writer.WriteLine("\n[NoiseBand]");
            writer.WriteLine($"On={p.Band1On}");
            writer.WriteLine($"Level={p.Band1Level}");
            writer.WriteLine($"F={p.Band1F:F2}");
            writer.WriteLine($"dF={p.Band1Df}");
            writer.WriteLine($"Envelope={p.Band1Envelope}");

            writer.WriteLine("\n[NoiseBand2]");
            writer.WriteLine($"On={p.Band2On}");
            writer.WriteLine($"Level={p.Band2Level}");
            writer.WriteLine($"F={p.Band2F:F2}");
            writer.WriteLine($"dF={p.Band2Df}");
            writer.WriteLine($"Envelope={p.Band2Envelope}");

            writer.WriteLine("\n[Distortion]");
            writer.WriteLine($"On={p.DistOn}");
            writer.WriteLine($"Clipping={p.DistClipping}");
            writer.WriteLine($"Bits={p.DistBits}");
            writer.WriteLine($"Rate={p.DistRate}");

            return 0;
        }
        catch
        {
            return 4;
        }
    }

    #endregion
}
