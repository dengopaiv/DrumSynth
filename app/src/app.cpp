// app.cpp - DrumSynth, the accessible GUI: program entry.
//
// Usage: DrumSynth.exe [file.ds]   (a .ds file given is loaded at start, as
// the original did).
#include <wx/app.h>
#include <wx/cmdline.h>

#include "main_frame.h"

class DrumSynthApp : public wxApp {
public:
    bool OnInit() override
    {
        wxString file;
        if (argc > 1) file = argv[1];
        SetAppName("DrumSynth");
        auto* frame = new MainFrame(file);
        frame->Show();
        SetTopWindow(frame);
        return true;
    }
};

wxIMPLEMENT_APP(DrumSynthApp);
