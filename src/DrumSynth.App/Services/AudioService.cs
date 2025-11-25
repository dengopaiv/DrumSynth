using System;
using NAudio.Wave;

namespace DrumSynth.Services;

/// <summary>
/// Audio playback service using NAudio
/// </summary>
public sealed class AudioService : IDisposable
{
    private WaveOutEvent? _waveOut;
    private BufferedWaveProvider? _buffer;
    private bool _disposed;

    public AudioService()
    {
    }

    /// <summary>
    /// Play audio samples
    /// </summary>
    /// <param name="samples">16-bit mono PCM samples</param>
    /// <param name="sampleCount">Number of samples to play</param>
    public void Play(short[] samples, int sampleCount)
    {
        Stop();

        // Convert shorts to bytes
        var bytes = new byte[sampleCount * 2];
        Buffer.BlockCopy(samples, 0, bytes, 0, sampleCount * 2);

        // Create wave format: 16-bit mono 44.1kHz
        var format = new WaveFormat(44100, 16, 1);

        _buffer = new BufferedWaveProvider(format)
        {
            BufferLength = bytes.Length + 4096,
            DiscardOnBufferOverflow = true
        };
        _buffer.AddSamples(bytes, 0, bytes.Length);

        _waveOut = new WaveOutEvent
        {
            DesiredLatency = 100
        };
        _waveOut.Init(_buffer);
        _waveOut.Play();
    }

    /// <summary>
    /// Stop current playback
    /// </summary>
    public void Stop()
    {
        if (_waveOut != null)
        {
            if (_waveOut.PlaybackState == PlaybackState.Playing)
            {
                _waveOut.Stop();
            }
            _waveOut.Dispose();
            _waveOut = null;
        }
        _buffer = null;
    }

    /// <summary>
    /// Check if audio is currently playing
    /// </summary>
    public bool IsPlaying => _waveOut?.PlaybackState == PlaybackState.Playing;

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        Stop();
    }
}
