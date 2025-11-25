// DrumSynth Core - Modern portable synthesis engine
// Original (c) 1998-2000 Paul Kellett (mda-vst.com)
// Modernized for cross-platform use
// MIT/GPL-2.0 dual license

#ifndef DRUMSYNTH_H
#define DRUMSYNTH_H

#include <stdint.h>

#ifdef _WIN32
    #ifdef DS_EXPORTS
        #define DS_API __declspec(dllexport)
    #else
        #define DS_API __declspec(dllimport)
    #endif
    #define DS_CALL __stdcall
#else
    #define DS_API
    #define DS_CALL
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Return codes
#define DS_OK           0
#define DS_ERR_VERSION  1
#define DS_ERR_INPUT    2
#define DS_ERR_MEMORY   3
#define DS_ERR_OUTPUT   4

// Synthesis parameters structure (matches .DS file format)
typedef struct {
    // General
    char comment[256];
    float tuning;           // Semitones
    float stretch;          // Time stretch percentage (100 = normal)
    float level;            // Master level in dB

    // Tone section
    int tone_on;
    int tone_level;         // 0-181
    float tone_f1;          // Start frequency Hz
    float tone_f2;          // End frequency Hz
    float tone_droop;       // Pitch envelope droop
    float tone_phase;       // Start phase in degrees
    char tone_envelope[512];

    // Noise section
    int noise_on;
    int noise_level;
    int noise_slope;        // -100 to +100
    int noise_fixed_seq;    // Use fixed random sequence
    char noise_envelope[512];

    // Overtones section
    int over_on;
    int over_level;
    float over_f1;
    float over_f2;
    int over_wave1;         // 0=sin, 1=sin^2, 2=tri, 3=saw, 4=square
    int over_wave2;
    int over_track1;        // Track tone frequency
    int over_track2;
    int over_method;        // 0=add, 1=FM, 2=RM, 3=808 cymbal
    int over_param;         // Mix/drive parameter 0-100
    int over_filter;        // Filter overtones only
    char over_envelope1[512];
    char over_envelope2[512];

    // Noise Band 1
    int band1_on;
    int band1_level;
    float band1_f;          // Center frequency Hz
    int band1_df;           // Bandwidth 0-100
    char band1_envelope[512];

    // Noise Band 2
    int band2_on;
    int band2_level;
    float band2_f;
    int band2_df;
    char band2_envelope[512];

    // Distortion
    int dist_on;
    int dist_clipping;      // dB
    int dist_bits;          // Bit reduction index
    int dist_rate;          // Downsampling rate index

    // Master Filter
    int filter_on;
    int filter_highpass;
    int filter_resonance;   // 0-99
    char filter_envelope[512];
} DrumSynthParams;

// Initialize parameters to defaults
DS_API void DS_CALL ds_init_params(DrumSynthParams* params);

// Load parameters from .DS file
DS_API int DS_CALL ds_load_file(const char* filename, DrumSynthParams* params);

// Save parameters to .DS file
DS_API int DS_CALL ds_save_file(const char* filename, const DrumSynthParams* params);

// Synthesize drum sound to memory buffer
// Returns number of samples generated, or negative error code
// buffer must be pre-allocated (use ds_estimate_length for size)
DS_API int DS_CALL ds_synthesize(const DrumSynthParams* params, int16_t* buffer, int max_samples);

// Estimate output length in samples
DS_API int DS_CALL ds_estimate_length(const DrumSynthParams* params);

// Synthesize and write directly to WAV file
DS_API int DS_CALL ds_to_wav(const char* dsfile, const char* wavfile);

// Get version string
DS_API const char* DS_CALL ds_version(void);

#ifdef __cplusplus
}
#endif

#endif // DRUMSYNTH_H
