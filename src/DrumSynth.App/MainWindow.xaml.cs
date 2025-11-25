using System;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using DrumSynth.Native;
using DrumSynth.Services;
using Microsoft.Win32;

namespace DrumSynth;

public partial class MainWindow : Window
{
    private readonly AudioService _audioService;
    private DrumSynthParams _currentParams;
    private string? _currentFile;
    private string? _libraryPath;
    private bool _isLoading;

    public MainWindow()
    {
        InitializeComponent();
        _audioService = new AudioService();
        _currentParams = new DrumSynthParams();
        DrumSynthNative.InitParams(ref _currentParams);

        // Set default combo box selections
        DistBits.SelectedIndex = 0;
        DistRate.SelectedIndex = 0;
        OverWave1.SelectedIndex = 0;
        OverWave2.SelectedIndex = 0;
        OverMethod.SelectedIndex = 2; // RM default
    }

    private void Window_Loaded(object sender, RoutedEventArgs e)
    {
        // Try to find library folder
        var exePath = AppDomain.CurrentDomain.BaseDirectory;
        var possiblePaths = new[]
        {
            Path.Combine(exePath, "library"),
            Path.Combine(exePath, "..", "..", "..", "..", "bin", "library"),
            Path.Combine(exePath, "..", "library"),
        };

        foreach (var path in possiblePaths)
        {
            if (Directory.Exists(path))
            {
                _libraryPath = Path.GetFullPath(path);
                break;
            }
        }

        if (_libraryPath != null)
        {
            LoadKitList();
        }

        UpdateSliderDisplays();

        // Announce to screen reader
        Title = "DrumSynth 3.0 - Ready";
    }

    private void LoadKitList()
    {
        if (_libraryPath == null) return;

        KitList.Items.Clear();
        try
        {
            foreach (var dir in Directory.GetDirectories(_libraryPath))
            {
                KitList.Items.Add(Path.GetFileName(dir));
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error loading library: {ex.Message}", "Error",
                MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }

    private void KitList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (KitList.SelectedItem == null || _libraryPath == null) return;

        PresetList.Items.Clear();
        var kitPath = Path.Combine(_libraryPath, KitList.SelectedItem.ToString()!);

        try
        {
            foreach (var file in Directory.GetFiles(kitPath, "*.ds"))
            {
                PresetList.Items.Add(Path.GetFileNameWithoutExtension(file));
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error loading presets: {ex.Message}", "Error",
                MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }

    private void PresetList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (PresetList.SelectedItem == null || KitList.SelectedItem == null || _libraryPath == null)
            return;

        var presetPath = Path.Combine(_libraryPath,
            KitList.SelectedItem.ToString()!,
            PresetList.SelectedItem.ToString()! + ".ds");

        LoadPreset(presetPath);
    }

    private void LoadPreset(string path)
    {
        _isLoading = true;
        try
        {
            var result = DrumSynthNative.LoadFile(path, ref _currentParams);
            if (result != 0)
            {
                MessageBox.Show("Failed to load preset file.", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            _currentFile = path;
            UpdateUIFromParams();
            Title = $"DrumSynth 3.0 - {Path.GetFileNameWithoutExtension(path)}";

            // Auto-preview
            PlaySound();
        }
        finally
        {
            _isLoading = false;
        }
    }

    private void UpdateUIFromParams()
    {
        // Tone
        ToneOn.IsChecked = _currentParams.ToneOn != 0;
        ToneLevel.Value = _currentParams.ToneLevel;
        ToneF1.Text = _currentParams.ToneF1.ToString("F0");
        ToneF2.Text = _currentParams.ToneF2.ToString("F0");
        ToneDroop.Value = _currentParams.ToneDroop;
        TonePhase.Text = _currentParams.TonePhase.ToString("F0");

        // Noise
        NoiseOn.IsChecked = _currentParams.NoiseOn != 0;
        NoiseLevel.Value = _currentParams.NoiseLevel;
        NoiseSlope.Value = _currentParams.NoiseSlope;
        NoiseFixedSeq.IsChecked = _currentParams.NoiseFixedSeq != 0;

        // Overtones
        OvertonesOn.IsChecked = _currentParams.OverOn != 0;
        OverLevel.Value = _currentParams.OverLevel;
        OverF1.Text = _currentParams.OverF1.ToString("F0");
        OverF2.Text = _currentParams.OverF2.ToString("F0");
        OverWave1.SelectedIndex = Math.Clamp(_currentParams.OverWave1, 0, 4);
        OverWave2.SelectedIndex = Math.Clamp(_currentParams.OverWave2, 0, 4);
        OverMethod.SelectedIndex = Math.Clamp(_currentParams.OverMethod, 0, 3);
        OverParam.Value = _currentParams.OverParam;
        OverTrack1.IsChecked = _currentParams.OverTrack1 != 0;
        OverTrack2.IsChecked = _currentParams.OverTrack2 != 0;

        // Noise bands
        Band1On.IsChecked = _currentParams.Band1On != 0;
        Band1Level.Value = _currentParams.Band1Level;
        Band1Freq.Text = _currentParams.Band1F.ToString("F0");
        Band1Width.Value = _currentParams.Band1Df;

        Band2On.IsChecked = _currentParams.Band2On != 0;
        Band2Level.Value = _currentParams.Band2Level;
        Band2Freq.Text = _currentParams.Band2F.ToString("F0");
        Band2Width.Value = _currentParams.Band2Df;

        // Distortion
        DistortionOn.IsChecked = _currentParams.DistOn != 0;
        DistClipping.Value = _currentParams.DistClipping;
        DistBits.SelectedIndex = Math.Clamp(_currentParams.DistBits, 0, 3);
        DistRate.SelectedIndex = Math.Clamp(_currentParams.DistRate, 0, 3);

        // Filter
        FilterOn.IsChecked = _currentParams.FilterOn != 0;
        FilterResonance.Value = _currentParams.FilterResonance;
        FilterHighPass.IsChecked = _currentParams.FilterHighpass != 0;
        FilterOvertonesOnly.IsChecked = _currentParams.OverFilter != 0;

        // Master
        MasterTune.Text = _currentParams.Tuning.ToString("F2");
        MasterStretch.Text = _currentParams.Stretch.ToString("F1");
        MasterLevel.Value = _currentParams.Level;
        MasterOn.IsChecked = _currentParams.Tuning != 0 ||
                             Math.Abs(_currentParams.Stretch - 100) > 0.1 ||
                             _currentParams.Level != 0;

        CommentText.Text = _currentParams.Comment ?? "";

        UpdateSliderDisplays();
    }

    private void UpdateParamsFromUI()
    {
        // Tone
        _currentParams.ToneOn = ToneOn.IsChecked == true ? 1 : 0;
        _currentParams.ToneLevel = (int)ToneLevel.Value;
        if (float.TryParse(ToneF1.Text, out var tf1)) _currentParams.ToneF1 = tf1;
        if (float.TryParse(ToneF2.Text, out var tf2)) _currentParams.ToneF2 = tf2;
        _currentParams.ToneDroop = (float)ToneDroop.Value;
        if (float.TryParse(TonePhase.Text, out var tp)) _currentParams.TonePhase = tp;

        // Noise
        _currentParams.NoiseOn = NoiseOn.IsChecked == true ? 1 : 0;
        _currentParams.NoiseLevel = (int)NoiseLevel.Value;
        _currentParams.NoiseSlope = (int)NoiseSlope.Value;
        _currentParams.NoiseFixedSeq = NoiseFixedSeq.IsChecked == true ? 1 : 0;

        // Overtones
        _currentParams.OverOn = OvertonesOn.IsChecked == true ? 1 : 0;
        _currentParams.OverLevel = (int)OverLevel.Value;
        if (float.TryParse(OverF1.Text, out var of1)) _currentParams.OverF1 = of1;
        if (float.TryParse(OverF2.Text, out var of2)) _currentParams.OverF2 = of2;
        _currentParams.OverWave1 = OverWave1.SelectedIndex;
        _currentParams.OverWave2 = OverWave2.SelectedIndex;
        _currentParams.OverMethod = OverMethod.SelectedIndex;
        _currentParams.OverParam = (int)OverParam.Value;
        _currentParams.OverTrack1 = OverTrack1.IsChecked == true ? 1 : 0;
        _currentParams.OverTrack2 = OverTrack2.IsChecked == true ? 1 : 0;

        // Noise bands
        _currentParams.Band1On = Band1On.IsChecked == true ? 1 : 0;
        _currentParams.Band1Level = (int)Band1Level.Value;
        if (float.TryParse(Band1Freq.Text, out var b1f)) _currentParams.Band1F = b1f;
        _currentParams.Band1Df = (int)Band1Width.Value;

        _currentParams.Band2On = Band2On.IsChecked == true ? 1 : 0;
        _currentParams.Band2Level = (int)Band2Level.Value;
        if (float.TryParse(Band2Freq.Text, out var b2f)) _currentParams.Band2F = b2f;
        _currentParams.Band2Df = (int)Band2Width.Value;

        // Distortion
        _currentParams.DistOn = DistortionOn.IsChecked == true ? 1 : 0;
        _currentParams.DistClipping = (int)DistClipping.Value;
        _currentParams.DistBits = DistBits.SelectedIndex;
        _currentParams.DistRate = DistRate.SelectedIndex;

        // Filter
        _currentParams.FilterOn = FilterOn.IsChecked == true ? 1 : 0;
        _currentParams.FilterResonance = (int)FilterResonance.Value;
        _currentParams.FilterHighpass = FilterHighPass.IsChecked == true ? 1 : 0;
        _currentParams.OverFilter = FilterOvertonesOnly.IsChecked == true ? 1 : 0;

        // Master
        if (float.TryParse(MasterTune.Text, out var tune)) _currentParams.Tuning = tune;
        if (float.TryParse(MasterStretch.Text, out var stretch)) _currentParams.Stretch = stretch;
        _currentParams.Level = (float)MasterLevel.Value;

        _currentParams.Comment = CommentText.Text;
    }

    private void UpdateSliderDisplays()
    {
        ToneLevelText.Text = ((int)ToneLevel.Value).ToString();
        ToneDroopText.Text = ((int)ToneDroop.Value).ToString();
        NoiseLevelText.Text = ((int)NoiseLevel.Value).ToString();
        NoiseSlopeText.Text = ((int)NoiseSlope.Value).ToString();
        OverLevelText.Text = ((int)OverLevel.Value).ToString();
        OverParamText.Text = ((int)OverParam.Value).ToString();
        Band1LevelText.Text = ((int)Band1Level.Value).ToString();
        Band1WidthText.Text = ((int)Band1Width.Value).ToString();
        Band2LevelText.Text = ((int)Band2Level.Value).ToString();
        Band2WidthText.Text = ((int)Band2Width.Value).ToString();
        DistClipText.Text = $"{(int)DistClipping.Value} dB";
        FilterResText.Text = ((int)FilterResonance.Value).ToString();
        MasterLevelText.Text = $"{(int)MasterLevel.Value} dB";
    }

    private void ParamChanged(object sender, RoutedEventArgs e)
    {
        if (_isLoading) return;
        UpdateSliderDisplays();
        UpdateParamsFromUI();
    }

    private void ParamChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_isLoading) return;
        UpdateSliderDisplays();
        UpdateParamsFromUI();
    }

    private void PlaySound()
    {
        try
        {
            UpdateParamsFromUI();
            int length = DrumSynthNative.EstimateLength(ref _currentParams);
            if (length <= 0) length = 44100; // Default 1 second

            short[] buffer = new short[length];
            int samples = DrumSynthNative.Synthesize(ref _currentParams, buffer, length);

            if (samples > 0)
            {
                _audioService.Play(buffer, samples);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error playing sound: {ex.Message}", "Playback Error",
                MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }

    private void Play_Click(object sender, RoutedEventArgs e)
    {
        PlaySound();
    }

    private void Stop_Click(object sender, RoutedEventArgs e)
    {
        _audioService.Stop();
    }

    private void OpenPreset_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFileDialog
        {
            Filter = "DrumSynth Files (*.ds)|*.ds|All Files (*.*)|*.*",
            Title = "Open DrumSynth Preset"
        };

        if (dialog.ShowDialog() == true)
        {
            LoadPreset(dialog.FileName);
        }
    }

    private void SavePreset_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new SaveFileDialog
        {
            Filter = "DrumSynth Files (*.ds)|*.ds",
            Title = "Save DrumSynth Preset"
        };

        if (_currentFile != null)
        {
            dialog.InitialDirectory = Path.GetDirectoryName(_currentFile);
            dialog.FileName = Path.GetFileName(_currentFile);
        }

        if (dialog.ShowDialog() == true)
        {
            UpdateParamsFromUI();
            var result = DrumSynthNative.SaveFile(dialog.FileName, ref _currentParams);
            if (result != 0)
            {
                MessageBox.Show("Failed to save preset file.", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
            else
            {
                _currentFile = dialog.FileName;
                Title = $"DrumSynth 3.0 - {Path.GetFileNameWithoutExtension(dialog.FileName)}";
            }
        }
    }

    private void ExportWav_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new SaveFileDialog
        {
            Filter = "WAV Files (*.wav)|*.wav",
            Title = "Export to WAV"
        };

        if (dialog.ShowDialog() == true)
        {
            try
            {
                UpdateParamsFromUI();

                // Save temp .ds file, then convert
                var tempDs = Path.GetTempFileName() + ".ds";
                DrumSynthNative.SaveFile(tempDs, ref _currentParams);
                var result = DrumSynthNative.ToWav(tempDs, dialog.FileName);
                File.Delete(tempDs);

                if (result != 0)
                {
                    MessageBox.Show("Failed to export WAV file.", "Error",
                        MessageBoxButton.OK, MessageBoxImage.Error);
                }
                else
                {
                    MessageBox.Show($"Exported to {dialog.FileName}", "Export Complete",
                        MessageBoxButton.OK, MessageBoxImage.Information);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Export error: {ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }

    private void ResetParams_Click(object sender, RoutedEventArgs e)
    {
        if (MessageBox.Show("Reset all parameters to defaults?", "Confirm Reset",
            MessageBoxButton.YesNo, MessageBoxImage.Question) == MessageBoxResult.Yes)
        {
            _isLoading = true;
            DrumSynthNative.InitParams(ref _currentParams);
            UpdateUIFromParams();
            _isLoading = false;
            _currentFile = null;
            Title = "DrumSynth 3.0";
        }
    }

    private void Exit_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }

    private void ShowShortcuts_Click(object sender, RoutedEventArgs e)
    {
        MessageBox.Show(
            "Keyboard Shortcuts:\n\n" +
            "Ctrl+O - Open preset\n" +
            "Ctrl+S - Save preset\n" +
            "Ctrl+Space - Play sound\n" +
            "Tab - Navigate between controls\n" +
            "Arrow keys - Adjust sliders\n" +
            "Space - Toggle checkboxes\n\n" +
            "Screen reader users: All controls are labeled for accessibility.",
            "Keyboard Shortcuts",
            MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void ShowAbout_Click(object sender, RoutedEventArgs e)
    {
        MessageBox.Show(
            "DrumSynth 3.0 - Modern Edition\n\n" +
            "Original DrumSynth by Paul Kellett (c) 1998-2000\n" +
            "mda-vst.com\n\n" +
            "Modern port with accessibility support.\n" +
            "MIT / GPL-2.0 dual license.\n\n" +
            "This version features:\n" +
            "- Full screen reader support\n" +
            "- Keyboard navigation\n" +
            "- Modern Windows compatibility\n" +
            "- No legacy DLL dependencies",
            "About DrumSynth",
            MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void Window_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Space && Keyboard.Modifiers == ModifierKeys.Control)
        {
            PlaySound();
            e.Handled = true;
        }
    }

    private void EnvelopeCanvas_KeyDown(object sender, KeyEventArgs e)
    {
        // Placeholder for envelope editor keyboard navigation
    }

    protected override void OnClosed(EventArgs e)
    {
        _audioService.Dispose();
        base.OnClosed(e);
    }
}
