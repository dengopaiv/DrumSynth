// main_frame.cpp - see main_frame.h. Behaviour follows gui/DRUMSYN.FRM; the
// numbers in comments refer to docs/gui-checklist.md.
#include "main_frame.h"

#include <algorithm>
#include <cwctype>
#include <filesystem>
#include <functional>
#include <wx/button.h>
#include <wx/dirdlg.h>
#include <wx/filedlg.h>
#include <wx/menu.h>
#include <wx/msgdlg.h>
#include <wx/progdlg.h>
#include <wx/scrolwin.h>
#include <wx/sizer.h>
#include <wx/statbox.h>
#include <wx/statusbr.h>
#include <wx/stdpaths.h>
#include <wx/textdlg.h>
#include <wx/utils.h>
#include <windows.h>
#include <mmsystem.h>

#include "drumsynth.h"
#include "vbtext.h"

namespace fs = std::filesystem;

namespace {

enum {
    ID_PLAY = wxID_HIGHEST + 1, ID_LOAD, ID_SAVE, ID_GEN_WAVS, ID_DEL_WAVS, ID_DEL_SOUND, ID_NEW_KIT,
    ID_LOCATION, ID_GO_POINTS, ID_GO_KITS, ID_ENV_COPY, ID_ENV_PASTE, ID_ENV_RESET, ID_HELP
};

const std::vector<wxString> kWaves = {"Sine", "Sine²", "Tri", "Saw", "Square"};
const std::vector<wxString> kMethods = {"A + B", "A . B (freq modulation)", "A x B (ring modulation)",
                                        "A....B (cymbal tones)"};
const std::vector<wxString> kBits = {"[none]", "14 bit", "12 bit", "10 bit", " 8 bit", " 6 bit", " 4 bit", " 2 bit"};
const std::vector<wxString> kRates = {"[none]", "11 kHz", " 7 kHz", " 5 kHz", " 4 kHz", " 3 kHz", " 2 kHz", " 1 kHz"};

// Form_Load: one of five tips in a new window's comment
const char* kTips[] = {
    "Right-click the file list and envelope display for menu options",
    "You can use this space to add a comment to each sound!",
    "DrumSynth 2.0 by maxim digital audio, Copyright \xA9" "2000 Paul Kellett  http://www.mda-vst.com",
    "Use FruityLoops to sequence your DrumSynth sounds!  http://www.fruityloops.com",
    "You can use [Ctrl] and [Enter] to trigger the Play button!"};

wxString FromAnsi(const std::string& s) { return wxString(s.c_str(), wxConvLocal); }
std::string ToAnsi(const wxString& s)
{
    int n = WideCharToMultiByte(CP_ACP, 0, s.wc_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string out(n > 0 ? n - 1 : 0, '\0');
    if (n > 1) WideCharToMultiByte(CP_ACP, 0, s.wc_str(), -1, out.data(), n, nullptr, nullptr);
    return out;
}

std::wstring ExeDir()
{
    return fs::path(wxStandardPaths::Get().GetExecutablePath().ToStdWstring()).parent_path().wstring();
}

std::wstring IniGet(const std::wstring& ini, const wchar_t* sec, const wchar_t* key, const std::wstring& def)
{
    wchar_t buf[512];
    DWORD n = GetPrivateProfileStringW(sec, key, L"", buf, 512, ini.c_str());
    return n ? std::wstring(buf, n) : def;
}

// NeatName(): the file name without extension, first letter upper case,
// the rest lower case
std::wstring NeatName(const std::wstring& path)
{
    std::wstring n = fs::path(path).stem().wstring();
    for (size_t i = 0; i < n.size(); i++) n[i] = i == 0 ? std::towupper(n[i]) : std::towlower(n[i]);
    return n;
}

int Clamp(int v, int lo, int hi) { return std::min(std::max(v, lo), hi); }

}  // namespace

// ---- Building the window -------------------------------------------------------

MainFrame::MainFrame(const wxString& openFile)
    : wxFrame(nullptr, wxID_ANY, "DrumSynth 2.0")
{
    preset_ = Preset::NewSound();
    preset_.comment = kTips[(GetTickCount() / 10) % 5];

    wchar_t tmp[MAX_PATH];
    GetTempPathW(MAX_PATH, tmp);
    tempDs_ = std::wstring(tmp) + L"DrumSyn-.tmp";
    tempWav_ = std::wstring(tmp) + L"DrumSyn~.tmp";
    iniPath_ = ExeDir() + L"\\DrumSyn.ini";
    LoadSettings();

    // without wxSTB_ELLIPSIZE_END: it puts the shortened text ("Rendered
    // 0.16 s...") into the control, which is what screen readers read
    CreateStatusBar(1, wxSTB_SIZEGRIP | wxSTB_SHOW_TIPS | wxFULL_REPAINT_ON_RESIZE);
    auto* scroll = new wxScrolledWindow(this, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxVSCROLL | wxHSCROLL | wxTAB_TRAVERSAL);
    scroll->SetScrollRate(10, 10);
    auto* main = new wxBoxSizer(wxVERTICAL);
    main->Add(MakeFileArea(scroll), 0, wxEXPAND | wxALL, 6);
    main->Add(MakeSections(scroll), 0, wxEXPAND | wxLEFT | wxRIGHT, 6);

    EnvelopeEditor::Host host;
    host.isOn = [this](int e) {
        switch (e) { // envIsOn()
        case ENV_TONE: return preset_.toneOn == 1;
        case ENV_NOISE: return preset_.noiseOn == 1;
        case ENV_OT1: case ENV_OT2: return preset_.otOn == 1;
        case ENV_BAND1: return preset_.band1On == 1;
        case ENV_BAND2: return preset_.band2On == 1;
        default: return preset_.filter == 1 || preset_.otFilter == 1;
        }
    };
    host.overtoneMethod = [this] { return preset_.method; };
    host.changed = [this] { Changed(); };
    auto* envBox = new wxStaticBoxSizer(wxVERTICAL, scroll, "Envelopes");
    env_ = new EnvelopeEditor(envBox->GetStaticBox(), &preset_, host);
    envBox->Add(env_, 1, wxEXPAND | wxALL, 4);
    main->Add(envBox, 1, wxEXPAND | wxALL, 6);

    auto* bottom = new wxBoxSizer(wxHORIZONTAL);
    bottom->Add(new wxStaticText(scroll, wxID_ANY, "&Comment:"), 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 4);
    comment_ = new wxTextCtrl(scroll, wxID_ANY, FromAnsi(preset_.comment));
    comment_->Bind(wxEVT_TEXT, [this](wxCommandEvent&) {
        if (loading_) return;
        preset_.comment = ToAnsi(comment_->GetValue());
        Changed();
    });
    comment_->Bind(wxEVT_SET_FOCUS, [this](wxFocusEvent& e) { // comment_GotFocus
        CallAfter([this] { comment_->SelectAll(); });
        e.Skip();
    });
    bottom->Add(comment_, 1, wxEXPAND | wxRIGHT, 8);
    auto* help = new wxButton(scroll, ID_HELP, "Help");
    bottom->Add(help, 0);
    main->Add(bottom, 0, wxEXPAND | wxALL, 6);

    scroll->SetSizer(main);
    auto* frameSizer = new wxBoxSizer(wxVERTICAL);
    frameSizer->Add(scroll, 1, wxEXPAND);
    SetSizer(frameSizer);
    main->Fit(scroll);
    MakeMenus();
    SetClientSize(scroll->GetBestSize() + wxSize(20, 20));
    wxSize screen = wxGetDisplaySize();
    if (GetSize().y > screen.y - 60) SetSize(GetSize().x, screen.y - 60);

    Bind(wxEVT_CHAR_HOOK, &MainFrame::OnCharHook, this);
    // Keep the keyboard focus on a control when the window is activated
    // again (Alt+Tab): remember the last focused control and restore it.
    Bind(wxEVT_CHILD_FOCUS, [this](wxChildFocusEvent& e) {
        wxWindow* f = FindFocus();
        if (f && f != this && IsDescendant(f)) lastFocus_ = f;
        e.Skip();
    });
    Bind(wxEVT_ACTIVATE, [this](wxActivateEvent& e) {
        if (e.GetActive()) CallAfter([this] {
            wxWindow* f = FindFocus();
            if ((!f || !IsDescendant(f) || f == this) && lastFocus_) lastFocus_->SetFocus();
        });
        e.Skip();
    });
    Bind(wxEVT_CLOSE_WINDOW, &MainFrame::OnClose, this);
    Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { ShowHelp(); }, ID_HELP);

    ReadKits();
    ApplyToControls();
    if (!openFile.empty()) LoadFile(openFile.ToStdWstring());
    play_->SetFocus();
}

void MainFrame::MakeMenus()
{
    auto* file = new wxMenu;
    file->Append(ID_PLAY, "&Play\tCtrl+P"); // F5 plays sound 5 (Form_KeyDown)
    file->Append(ID_LOAD, "&Load selected sound\tCtrl+O");
    file->Append(ID_SAVE, "&Save as...\tCtrl+S");
    file->AppendSeparator();
    file->Append(wxID_EXIT, "E&xit");
    auto* kit = new wxMenu;
    kit->Append(ID_GEN_WAVS, "&Generate all WAVs");
    kit->Append(ID_DEL_WAVS, "De&lete all WAVs...");
    kit->Append(ID_DEL_SOUND, "&Delete sound...");
    kit->AppendSeparator();
    kit->Append(ID_NEW_KIT, "&New kit...");
    kit->Append(ID_LOCATION, "Set &location...");
    kit->AppendSeparator();
    kit->Append(ID_GO_KITS, "Go to &kit list\tCtrl+K");
    auto* env = new wxMenu;
    env->Append(ID_GO_POINTS, "Go to envelope &points\tCtrl+E");
    env->Append(ID_ENV_COPY, "&Copy envelope");
    env->Append(ID_ENV_PASTE, "&Paste envelope");
    env->Append(ID_ENV_RESET, "&Reset envelope");
    auto* help = new wxMenu;
    help->Append(ID_HELP, "DrumSynth &help");
    help->Append(wxID_ABOUT, "&About DrumSynth");
    auto* bar = new wxMenuBar;
    bar->Append(file, "&File");
    bar->Append(kit, "&Kit");
    bar->Append(env, "&Envelope");
    bar->Append(help, "&Help");
    SetMenuBar(bar);

    Bind(wxEVT_MENU, [this](wxCommandEvent&) { Play(); }, ID_PLAY);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { LoadSelected(); }, ID_LOAD);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { SaveAs(); }, ID_SAVE);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { Close(); }, wxID_EXIT);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { GenerateAll(); }, ID_GEN_WAVS);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { DeleteAllWavs(); }, ID_DEL_WAVS);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { DeleteSound(); }, ID_DEL_SOUND);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { NewKit(); }, ID_NEW_KIT);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { SetLocation(); }, ID_LOCATION);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { kits_->SetFocus(); }, ID_GO_KITS);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { env_->FocusPoints(); }, ID_GO_POINTS);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { env_->Copy(); }, ID_ENV_COPY);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { env_->Paste(); }, ID_ENV_PASTE);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { env_->Reset(); }, ID_ENV_RESET);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) { ShowHelp(); }, ID_HELP);
    Bind(wxEVT_MENU, [this](wxCommandEvent&) {
        wxMessageBox("DrumSynth " DS_VERSION_STRING ", accessible edition.\n\n"
                     "A recreation of DrumSynth 2.0, Copyright (c) 2000 Paul Kellett (mda-vst.com). "
                     "It renders sounds exactly as the original does.\n\n"
                     "MIT licence or GPL version 2 or later. https://github.com/dengopaiv/DrumSynth",
                     "About DrumSynth", wxOK | wxICON_INFORMATION, this);
    }, wxID_ABOUT);
}

wxSizer* MainFrame::MakeFileArea(wxWindow* p)
{
    auto* row = new wxBoxSizer(wxHORIZONTAL);
    play_ = new wxButton(p, ID_PLAY, "&Play");
    play_->SetToolTip("Play the sound (Enter or Ctrl+P)");
    play_->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { Play(); });
    row->Add(play_, 0, wxRIGHT | wxALIGN_TOP, 8);

    auto* kcol = new wxBoxSizer(wxVERTICAL);
    kcol->Add(new wxStaticText(p, wxID_ANY, "K&its:"), 0, wxBOTTOM, 2);
    kits_ = new wxListBox(p, wxID_ANY, wxDefaultPosition, wxSize(160, 120));
    kits_->Bind(wxEVT_LISTBOX, [this](wxCommandEvent&) { FillSoundList(); });
    kcol->Add(kits_, 1, wxEXPAND);
    row->Add(kcol, 0, wxEXPAND | wxRIGHT, 8);

    auto* scol = new wxBoxSizer(wxVERTICAL);
    scol->Add(new wxStaticText(p, wxID_ANY, "Soun&ds (F1 to F12 play them):"), 0, wxBOTTOM, 2);
    sounds_ = new wxListBox(p, wxID_ANY, wxDefaultPosition, wxSize(220, 120));
    // fileList_MouseDown: a click plays the sound's WAV; a double-click loads
    sounds_->Bind(wxEVT_LEFT_DOWN, [this](wxMouseEvent& e) { soundListMouse_ = true; e.Skip(); });
    sounds_->Bind(wxEVT_LISTBOX, [this](wxCommandEvent&) {
        std::wstring n;
        bool w;
        if (SelectedSound(&n, &w)) load_->Enable(!w);
        if (soundListMouse_) PlaySoundAt(sounds_->GetSelection());
        soundListMouse_ = false;
    });
    sounds_->Bind(wxEVT_LISTBOX_DCLICK, [this](wxCommandEvent&) { LoadSelected(); });
    sounds_->Bind(wxEVT_KEY_DOWN, [this](wxKeyEvent& e) {
        if (e.GetKeyCode() == WXK_SPACE || e.GetKeyCode() == WXK_RETURN || e.GetKeyCode() == WXK_NUMPAD_ENTER)
            PlaySoundAt(sounds_->GetSelection());
        else if (e.GetKeyCode() == WXK_DELETE) DeleteSound();
        else e.Skip();
    });
    sounds_->Bind(wxEVT_CONTEXT_MENU, [this](wxContextMenuEvent&) {
        wxMenu m; // mnuMain
        m.Append(ID_GEN_WAVS, "Generate All WAVs");
        m.Append(ID_DEL_WAVS, "Delete All WAVs...");
        m.Append(ID_DEL_SOUND, "Delete File...");
        m.AppendSeparator();
        m.Append(ID_NEW_KIT, "New Kit...");
        m.Append(ID_LOCATION, "Set Location...");
        m.AppendSeparator();
        m.Append(wxID_CANCEL, "Cancel");
        PopupMenu(&m);
    });
    scol->Add(sounds_, 1, wxEXPAND);
    row->Add(scol, 1, wxEXPAND | wxRIGHT, 8);

    auto* bcol = new wxBoxSizer(wxVERTICAL);
    load_ = new wxButton(p, ID_LOAD, "&Load");
    load_->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { LoadSelected(); });
    save_ = new wxButton(p, ID_SAVE, "&Save...");
    save_->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { SaveAs(); });
    bcol->Add(load_, 0, wxEXPAND | wxBOTTOM, 4);
    bcol->Add(save_, 0, wxEXPAND);
    row->Add(bcol, 0);
    return row;
}

ValueSlider* MainFrame::AddSlider(wxWindow* p, wxSizer* s, const wxString& label, int min, int max, int page,
                                  ValueSlider::Formatter f, int* field)
{
    wxString plain = wxStripMenuCodes(label);
    plain.Replace(":", "");
    s->Add(new wxStaticText(p, wxID_ANY, label), 0, wxALIGN_CENTER_VERTICAL);
    auto* row = new wxBoxSizer(wxHORIZONTAL);
    auto* slider = new ValueSlider(p, Clamp(*field, min, max), min, max, plain, f, page);
    auto* value = new wxStaticText(p, wxID_ANY, slider->ValueText(), wxDefaultPosition, wxSize(130, -1));
    row->Add(slider, 0, wxRIGHT, 4);
    row->Add(value, 0, wxALIGN_CENTER_VERTICAL);
    s->Add(row, 0, wxEXPAND);
    auto show = [slider, value] { value->SetLabel(slider->ValueText()); };
    slider->Bind(wxEVT_SLIDER, [this, slider, field, show](wxCommandEvent&) {
        if (loading_) return;
        *field = slider->GetValue();
        slider->SetRawOverride("");
        show();
        slider->NotifyValueChanged();
        Changed();
    });
    bindings_.push_back({[slider, field, min, max, show] {
        slider->SetValue(Clamp(*field, min, max));
        slider->SetRawOverride(*field < min || *field > max ? wxString::Format("%d", *field) : wxString());
        show();
    }});
    return slider;
}

wxTextCtrl* MainFrame::AddText(wxWindow* p, wxSizer* s, const wxString& label, const wxString& unit,
                               std::string* field, int width)
{
    s->Add(new wxStaticText(p, wxID_ANY, label), 0, wxALIGN_CENTER_VERTICAL);
    auto* row = new wxBoxSizer(wxHORIZONTAL);
    auto* t = new wxTextCtrl(p, wxID_ANY, FromAnsi(*field), wxDefaultPosition, wxSize(width, -1));
    row->Add(t, 0, wxRIGHT, 4);
    if (!unit.empty()) row->Add(new wxStaticText(p, wxID_ANY, unit), 0, wxALIGN_CENTER_VERTICAL);
    s->Add(row, 0);
    t->Bind(wxEVT_TEXT, [this, t, field](wxCommandEvent&) {
        if (loading_) return;
        *field = ToAnsi(t->GetValue());
        Changed();
    });
    bindings_.push_back({[t, field] { t->ChangeValue(FromAnsi(*field)); }});
    return t;
}

wxCheckBox* MainFrame::AddCheck(wxWindow* p, wxSizer* s, const wxString& label, int* field)
{
    auto* c = new wxCheckBox(p, wxID_ANY, label);
    s->Add(c, 0, wxALIGN_CENTER_VERTICAL);
    s->AddSpacer(0);
    c->Bind(wxEVT_CHECKBOX, [this, c, field](wxCommandEvent&) {
        if (loading_) return;
        *field = c->GetValue() ? 1 : 0;
        Changed();
        UpdateEnabling();
    });
    bindings_.push_back({[c, field] { c->SetValue(*field == 1); }});
    return c;
}

wxChoice* MainFrame::AddChoice(wxWindow* p, wxSizer* s, const wxString& label,
                               const std::vector<wxString>& items, int* field)
{
    s->Add(new wxStaticText(p, wxID_ANY, label), 0, wxALIGN_CENTER_VERTICAL);
    auto* c = new wxChoice(p, wxID_ANY);
    for (const wxString& i : items) c->Append(i);
    s->Add(c, 0);
    size_t n = items.size();
    c->Bind(wxEVT_CHOICE, [this, c, field, n](wxCommandEvent&) {
        if (loading_) return;
        int sel = c->GetSelection();
        if (sel >= 0 && (size_t)sel < n) {
            *field = sel;
            while (c->GetCount() > n) c->Delete(n); // the out-of-range entry goes
        }
        Changed();
        UpdateEnabling();
    });
    // a value outside the list is kept and shown as an extra entry (6)
    bindings_.push_back({[c, field, n] {
        while (c->GetCount() > n) c->Delete(n);
        if (*field >= 0 && (size_t)*field < n) c->SetSelection(*field);
        else c->SetSelection(c->Append(wxString::Format("(value %d, not in the original's list)", *field)));
    }});
    return c;
}

wxSizer* MainFrame::MakeSections(wxWindow* p)
{
    auto grid = [](wxStaticBoxSizer* box) {
        auto* g = new wxFlexGridSizer(2, 4, 8);
        box->Add(g, 0, wxALL, 4);
        return g;
    };
    auto lev = [](int l) { return wxString(vb::LevelDb(l)); };
    auto* cols = new wxBoxSizer(wxHORIZONTAL);
    auto* c1 = new wxBoxSizer(wxVERTICAL);
    auto* c2 = new wxBoxSizer(wxVERTICAL);
    auto* c3 = new wxBoxSizer(wxVERTICAL);
    cols->Add(c1, 0, wxRIGHT, 6);
    cols->Add(c2, 0, wxRIGHT, 6);
    cols->Add(c3, 0);

    // Tone (2.1-2.5)
    auto* tone = new wxStaticBoxSizer(wxVERTICAL, p, "Tone");
    wxWindow* tp = tone->GetStaticBox();
    auto* g = grid(tone);
    chkOn_[0] = AddCheck(tp, g, "&Tone on", &preset_.toneOn);
    AddSlider(tp, g, "Tone level:", 1, 181, 9, lev, &preset_.toneLevel);
    AddText(tp, g, "Start frequency:", "Hz", &preset_.toneF1);
    AddText(tp, g, "End frequency:", "Hz", &preset_.toneF2);
    // the original shows only the name; every value sounds different, so
    // the number is added, as for the noise colour
    AddSlider(tp, g, "Droop:", 0, 100, 10,
              [](int v) { return wxString::Format("%s (%d)", vb::DroopName(v), v); }, &preset_.droop);
    AddText(tp, g, "Phase at start:", "degrees", &preset_.phase);
    c1->Add(tone, 0, wxEXPAND | wxBOTTOM, 6);

    // Overtones (2.6-2.12)
    auto* ot = new wxStaticBoxSizer(wxVERTICAL, p, "Overtones");
    wxWindow* op = ot->GetStaticBox();
    g = grid(ot);
    chkOn_[2] = AddCheck(op, g, "&Overtones on", &preset_.otOn);
    AddSlider(op, g, "Overtones level:", 1, 181, 9, lev, &preset_.otLevel);
    AddText(op, g, "A frequency:", "Hz", &preset_.otF1);
    wave1_ = AddChoice(op, g, "A waveform:", kWaves, &preset_.wave1);
    track1_ = AddCheck(op, g, "A tracking (follows the tone)", &preset_.track1);
    AddText(op, g, "B frequency:", "Hz", &preset_.otF2);
    wave2_ = AddChoice(op, g, "B waveform:", kWaves, &preset_.wave2);
    track2_ = AddCheck(op, g, "B tracking (follows the tone)", &preset_.track2);
    method_ = AddChoice(op, g, "Method:", kMethods, &preset_.method);
    paramLabel_ = new wxStaticText(op, wxID_ANY, "Mix:");
    g->Add(paramLabel_, 0, wxALIGN_CENTER_VERTICAL);
    {
        auto* row = new wxBoxSizer(wxHORIZONTAL);
        param_ = new ValueSlider(op, preset_.param, 0, 100, "Mix", nullptr, 10);
        auto* value = new wxStaticText(op, wxID_ANY, param_->ValueText(), wxDefaultPosition, wxSize(130, -1));
        row->Add(param_, 0, wxRIGHT, 4);
        row->Add(value, 0, wxALIGN_CENTER_VERTICAL);
        g->Add(row);
        param_->Bind(wxEVT_SLIDER, [this, value](wxCommandEvent&) {
            if (loading_) return;
            preset_.param = param_->GetValue();
            param_->SetRawOverride("");
            value->SetLabel(param_->ValueText());
            param_->NotifyValueChanged();
            Changed();
        });
        bindings_.push_back({[this, value] {
            param_->SetValue(Clamp(preset_.param, 0, 100));
            param_->SetRawOverride(preset_.param < 0 || preset_.param > 100 ? wxString::Format("%d", preset_.param) : "");
            value->SetLabel(param_->ValueText());
        }});
    }
    c1->Add(ot, 0, wxEXPAND);

    // Noise (2.13-2.16)
    auto* noise = new wxStaticBoxSizer(wxVERTICAL, p, "Noise");
    wxWindow* np = noise->GetStaticBox();
    g = grid(noise);
    chkOn_[1] = AddCheck(np, g, "&Noise on", &preset_.noiseOn);
    AddSlider(np, g, "Noise level:", 1, 181, 9, lev, &preset_.noiseLevel);
    AddSlider(np, g, "Noise colour (slope):", -100, 100, 10,
              [](int v) { return wxString::Format("%s (%d)", vb::SlopeName(v), v); }, &preset_.slope);
    AddCheck(np, g, "Always same random sequence", &preset_.fixedSeq);
    c2->Add(noise, 0, wxEXPAND | wxBOTTOM, 6);

    // Noise bands (2.17, 2.18)
    auto band = [&](const wxString& name, int idx, int* on, int* level, std::string* f, int* width, wxSizer* col) {
        auto* box = new wxStaticBoxSizer(wxVERTICAL, p, name);
        wxWindow* bp = box->GetStaticBox();
        auto* bg = grid(box);
        chkOn_[idx] = AddCheck(bp, bg, name + " on", on);
        AddSlider(bp, bg, name + " level:", 1, 181, 9, lev, level);
        AddText(bp, bg, name + " centre frequency:", "Hz", f);
        AddSlider(bp, bg, name + " width:", 0, 100, 10, nullptr, width);
        col->Add(box, 0, wxEXPAND | wxBOTTOM, 6);
    };
    band("Noise Band 1", 3, &preset_.band1On, &preset_.band1Level, &preset_.band1F, &preset_.band1Width, c2);
    band("Noise Band 2", 4, &preset_.band2On, &preset_.band2Level, &preset_.band2F, &preset_.band2Width, c2);

    // Distortion (2.19)
    auto* dist = new wxStaticBoxSizer(wxVERTICAL, p, "Distortion");
    wxWindow* dp = dist->GetStaticBox();
    g = grid(dist);
    chkOn_[5] = AddCheck(dp, g, "Distortion on", &preset_.distOn);
    AddSlider(dp, g, "Clipping:", 0, 60, 3, [](int v) { return wxString(vb::ClipDb(v)); }, &preset_.clipping);
    AddChoice(dp, g, "Bit resolution:", kBits, &preset_.bits);
    AddChoice(dp, g, "Sample rate:", kRates, &preset_.rate);
    c3->Add(dist, 0, wxEXPAND | wxBOTTOM, 6);

    // Filter (2.20, 2.22)
    auto* filt = new wxStaticBoxSizer(wxVERTICAL, p, "Filter");
    wxWindow* fp = filt->GetStaticBox();
    g = grid(filt);
    filter_ = AddCheck(fp, g, "Filte&r", &preset_.filter);
    otFilter_ = AddCheck(fp, g, "Filter overtones only", &preset_.otFilter);
    AddCheck(fp, g, "High-pass", &preset_.highPass);
    AddSlider(fp, g, "Resonance:", 0, 99, 10, [](int v) { return wxString::Format("Q = %d", v); }, &preset_.resonance);
    c3->Add(filt, 0, wxEXPAND | wxBOTTOM, 6);

    // Master (2.21, 2.23)
    auto* master = new wxStaticBoxSizer(wxVERTICAL, p, "Master");
    wxWindow* mp = master->GetStaticBox();
    g = grid(master);
    masterOn_ = AddCheck(mp, g, "M&aster on", &preset_.masterOn);
    AddText(mp, g, "Tuning:", "semitones transpose", &preset_.tuning);
    AddText(mp, g, "Stretch:", "% timestretch", &preset_.stretch);
    AddSlider(mp, g, "Master level:", -20, 20, 3, [](int v) { return wxString(vb::MasterDb(v)); }, &preset_.masterDb);
    c3->Add(master, 0, wxEXPAND);

    // section On boxes select their envelope (chkOn_MouseUp, MasterFilter_Click)
    const int envFor[6] = {ENV_TONE, ENV_NOISE, ENV_OT1, ENV_BAND1, ENV_BAND2, 0};
    for (int i = 0; i < 5; i++) {
        chkOn_[i]->Bind(wxEVT_CHECKBOX, [this, i, envFor](wxCommandEvent& e) {
            e.Skip();
            if (!chkOn_[i]->GetValue()) return;
            int target = envFor[i];
            if (i == 2 && env_->CurrentEnvelope() == ENV_OT1) target = ENV_OT2;
            CallAfter([this, target] { env_->SelectEnvelope(target); });
        });
    }
    filter_->Bind(wxEVT_CHECKBOX, [this](wxCommandEvent& e) {
        e.Skip();
        if (filter_->GetValue()) CallAfter([this] { env_->SelectEnvelope(ENV_FILTER); });
    });
    return cols;
}

// ---- Preset <-> controls --------------------------------------------------------

void MainFrame::ApplyToControls()
{
    loading_ = true;
    for (auto& b : bindings_) b.apply();
    comment_->ChangeValue(FromAnsi(preset_.comment));
    loading_ = false;
    UpdateEnabling();
    if (env_) {
        env_->UpdateNames();
        env_->Reload();
    }
}

void MainFrame::UpdateEnabling()
{
    // chkOn_Click: Play needs a sound section on; tracking needs the tone
    bool any = preset_.toneOn == 1 || preset_.noiseOn == 1 || preset_.otOn == 1 || preset_.band1On == 1 ||
               preset_.band2On == 1;
    play_->Enable(any);
    // comOMethod_Click: the cymbal method has no waveforms or tracking
    bool notCymbal = preset_.method != 3;
    track1_->Enable(notCymbal && preset_.toneOn == 1);
    track2_->Enable(notCymbal && preset_.toneOn == 1);
    wave1_->Enable(notCymbal);
    wave2_->Enable(notCymbal);
    wxString name = preset_.method == 0 ? "Mix" : preset_.method == 3 ? "Reson." : "Depth";
    paramLabel_->SetLabel(name + ":");
    param_->SetAccessibleName(name);
    if (env_) {
        env_->UpdateNames();
        env_->Reload();
    }
}

void MainFrame::Changed()
{
    if (loading_) return;
    playable_ = false;
}

// ---- Sound -----------------------------------------------------------------------

// ds2wav() into memory: read a .ds file with the engine's own parser (the
// same rules as the original), render it, and give the WAV file's bytes,
// exactly as the original would have written them. Returns the result code.
static int RenderDsFile(const std::wstring& path, std::vector<unsigned char>* wav, unsigned* notes)
{
    FILE* f = _wfopen(path.c_str(), L"rb");
    if (!f) return DS_ERR_INPUT;
    std::string text;
    char buf[65536];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0) text.append(buf, n);
    fclose(f);
    ds_ini* ini = ds_ini_parse(text.data(), text.size());
    if (!ini) return DS_ERR_OUTPUT;
    ds_source src = ds_ini_source(ini);
    ds_sound sound;
    int code = ds_render(&src, nullptr, &sound);
    ds_ini_free(ini);
    if (code != DS_OK) return code;
    *notes = sound.notes;
    unsigned char* bytes = nullptr;
    n = ds_wav_bytes(&sound, &bytes);
    ds_sound_free(&sound);
    if (n == 0) return DS_ERR_OUTPUT;
    wav->assign(bytes, bytes + n);
    free(bytes);
    return DS_OK;
}

bool MainFrame::Render(std::vector<unsigned char>* wav, unsigned* notes, int* code)
{
    // butPlay_Click: savefile() to a temporary .ds, then ds2wav() on it
    DeleteFileW(tempDs_.c_str());
    if (!preset_.Save(tempDs_)) { *code = DS_ERR_OUTPUT; return false; }
    wxBusyCursor busy;
    *code = RenderDsFile(tempDs_, wav, notes);
    return *code == DS_OK;
}

void MainFrame::AnnounceNotes(unsigned notes)
{
    // docs/gui-checklist.md, section 7: warn but allow
    wxString msg;
    if (notes & DS_NOTE_HANG) msg += "Warning: the original DrumSynth would hang on this sound. ";
    if (notes & DS_NOTE_MEMORY_BEYOND) msg += "Note: the original reads memory it shouldn't for this sound. ";
    if (notes & DS_NOTE_TOKEN_START) msg += "Note: an envelope starts with a separator. ";
    if (!msg.empty()) {
        SetStatusText(msg);
        Announce(msg, this);
    }
}

void MainFrame::Play()
{
    if (!play_->IsEnabled()) return;
    if (!playable_) {
        PlaySoundW(nullptr, nullptr, 0);
        unsigned notes = 0;
        int code = 0;
        if (!Render(&wav_, &notes, &code)) {
            Warn(wxString::Format("The sound could not be rendered (result %d).", code));
            return;
        }
        playable_ = true;
        SetStatusText(wxString::Format("Rendered %.2f seconds", (wav_.size() - 88.0) / 88200.0));
        AnnounceNotes(notes);
    }
    if (!PlaySoundW(reinterpret_cast<LPCWSTR>(wav_.data()), nullptr, SND_MEMORY | SND_ASYNC | SND_NODEFAULT))
        Warn("The sound could not be played.");
}

void MainFrame::PlayFile(const std::wstring& path)
{
    if (!PlaySoundW(path.c_str(), nullptr, SND_FILENAME | SND_ASYNC | SND_NODEFAULT))
        Warn("There is no WAV file for this sound.");
}

void MainFrame::Warn(const wxString& msg)
{
    // the warning triangle (1.4)
    wxBell();
    SetStatusText(msg);
    Announce(msg, this);
}

// ---- Files and kits ---------------------------------------------------------------

void MainFrame::LoadSettings()
{
    dsPath_ = IniGet(iniPath_, L"Files", L"Path", ExeDir());
    // a relative location is relative to the program's folder (the release
    // ships "Path=Kits"), so the folder can be moved
    if (fs::path(dsPath_).is_relative()) dsPath_ = (fs::path(ExeDir()) / dsPath_).lexically_normal().wstring();
    while (!dsPath_.empty() && dsPath_.back() == L'\\') dsPath_.pop_back();
    saveWav_ = (int)vb::Val(ToAnsi(IniGet(iniPath_, L"Files", L"SaveWAVs", L"1")));
    int x = (int)vb::Val(ToAnsi(IniGet(iniPath_, L"Window", L"X", L"-1")));
    int y = (int)vb::Val(ToAnsi(IniGet(iniPath_, L"Window", L"Y", L"-1")));
    if (x > 0 && y > 0) SetPosition(wxPoint(x, y));
}

void MainFrame::SaveSettings()
{
    wxPoint pos = GetPosition();
    WritePrivateProfileStringW(L"Window", L"X", std::to_wstring(pos.x).c_str(), iniPath_.c_str());
    WritePrivateProfileStringW(L"Window", L"Y", std::to_wstring(pos.y).c_str(), iniPath_.c_str());
    // a location inside the program's folder is kept relative
    std::wstring path = dsPath_;
    std::error_code ec;
    fs::path rel = fs::relative(dsPath_, ExeDir(), ec);
    if (!ec && !rel.empty() && rel.native().rfind(L"..", 0) != 0) path = rel.wstring();
    WritePrivateProfileStringW(L"Files", L"Path", path.c_str(), iniPath_.c_str());
    WritePrivateProfileStringW(L"Files", L"SaveWAVs", std::to_wstring(saveWav_).c_str(), iniPath_.c_str());
}

void MainFrame::ReadKits()
{
    // ReadDirs(): the location's subfolders; the first letter upper case, and
    // all upper case if a character below 'A' (other than space) occurs
    kits_->Clear();
    std::vector<std::wstring> names;
    std::error_code ec;
    for (const auto& d : fs::directory_iterator(dsPath_, ec)) {
        if (!d.is_directory(ec)) continue;
        std::wstring n = d.path().filename().wstring();
        if (!n.empty()) n[0] = std::towupper(n[0]);
        bool upper = false;
        for (wchar_t c : n) if (c < L'A' && c != L' ') upper = true;
        if (upper) for (wchar_t& c : n) c = std::towupper(c);
        names.push_back(n);
    }
    for (const auto& n : names) kits_->Append(n);
    noKits_ = names.empty();
    if (noKits_) {
        // an empty list reads as "unknown" to screen readers: say what to do
        kits_->Append("(no kits here: use Kit, Set location)");
        SetStatusText("No kit folders here. Use Kit, Set location, to choose the folder that holds them.");
    }
    kits_->SetSelection(0);
    FillSoundList();
}

std::wstring MainFrame::KitDir() const
{
    int i = kits_->GetSelection();
    if (i < 0 || noKits_) return std::wstring();
    return dsPath_ + L"\\" + kits_->GetString(i).ToStdWstring();
}

void MainFrame::FillSoundList()
{
    // fillfilelist(): the .ds files, then WAV files without a .ds
    sounds_->Clear();
    soundEntries_.clear();
    std::wstring dir = KitDir();
    // keep the renders of this kit only, and the last one played, which
    // may still be playing (PlaySound reads it from memory)
    std::wstring prefix = dir + L"\\";
    for (auto it = kitRenders_.begin(); it != kitRenders_.end();) {
        bool keep = it->first == lastKitRender_ ||
                    (!dir.empty() && it->first.compare(0, prefix.size(), prefix) == 0);
        it = keep ? std::next(it) : kitRenders_.erase(it);
    }
    if (dir.empty()) { sounds_->Append("(no sounds)"); return; }
    std::vector<std::wstring> ds, wav;
    std::error_code ec;
    for (const auto& f : fs::directory_iterator(dir, ec)) {
        std::wstring ext = f.path().extension().wstring();
        for (wchar_t& c : ext) c = std::towlower(c);
        if (ext == L".ds") ds.push_back(f.path().stem().wstring());
        else if (ext == L".wav") wav.push_back(f.path().stem().wstring());
    }
    for (const auto& n : ds) {
        soundEntries_.push_back({n, false});
        sounds_->Append(n);
    }
    for (auto n : wav) {
        for (wchar_t& c : n) c = std::towlower(c);
        bool found = false;
        for (const auto& d : ds) {
            std::wstring l = d;
            for (wchar_t& c : l) c = std::towlower(c);
            if (l == n) found = true;
        }
        if (!found) {
            soundEntries_.push_back({n, true});
            sounds_->Append(n + L" (WAV only)");
        }
    }
    if (soundEntries_.empty()) sounds_->Append("(no sounds in this kit)");
    sounds_->SetSelection(0);
    if (!soundEntries_.empty()) load_->Enable(!soundEntries_[0].second);
}

bool MainFrame::SelectedSound(std::wstring* name, bool* wavOnly) const
{
    int i = sounds_->GetSelection();
    if (i < 0 || (size_t)i >= soundEntries_.size()) return false;
    *name = soundEntries_[i].first;
    *wavOnly = soundEntries_[i].second;
    return true;
}

void MainFrame::PlaySoundAt(int i)
{
    // fileList_MouseDown and Form_KeyDown played the sound's WAV file, which
    // had to be made first with Generate All WAVs. The engine is part of the
    // program now, so a sound with a .ds file is rendered from it (into
    // memory: the kit folder is not changed) and played; only a sound
    // without a .ds plays its WAV file.
    if (i < 0 || (size_t)i >= soundEntries_.size()) return;
    sounds_->SetSelection(i);
    const auto& [name, wavOnly] = soundEntries_[i];
    load_->Enable(!wavOnly);
    std::wstring base = KitDir() + L"\\" + name;
    if (wavOnly) { PlayFile(base + L".wav"); return; }

    // The renders are kept, so playing a sound again (a drum pad) is
    // immediate; one whose .ds changed since is rendered again.
    std::wstring ds = base + L".ds";
    std::error_code ec;
    auto time = fs::last_write_time(ds, ec);
    auto it = kitRenders_.find(ds);
    if (it == kitRenders_.end() || it->second.time != time) {
        PlaySoundW(nullptr, nullptr, 0); // the buffer being replaced may be playing
        KitRender r;
        r.time = time;
        wxBusyCursor busy;
        int code = RenderDsFile(ds, &r.wav, &r.notes);
        if (code != DS_OK) {
            Warn(wxString::Format("The sound could not be rendered (result %d).", code));
            return;
        }
        it = kitRenders_.insert_or_assign(ds, std::move(r)).first;
        AnnounceNotes(it->second.notes);
    }
    lastKitRender_ = ds;
    if (!PlaySoundW(reinterpret_cast<LPCWSTR>(it->second.wav.data()), nullptr, SND_MEMORY | SND_ASYNC | SND_NODEFAULT))
        Warn("The sound could not be played.");
}

void MainFrame::SetTitleFor(const std::wstring& path) { SetTitle(NeatName(path) + L" - DrumSynth"); }

void MainFrame::LoadFile(const std::wstring& path)
{
    std::string version;
    Preset p = preset_;
    if (!p.Load(path, &version)) {
        Warn("The sound could not be read.");
        return;
    }
    preset_ = p;
    playable_ = false;
    ApplyToControls();
    SetTitleFor(path);
    Announce(wxString("Loaded ") + NeatName(path), this);
}

void MainFrame::LoadSelected()
{
    std::wstring n;
    bool wavOnly;
    if (!SelectedSound(&n, &wavOnly)) { Warn("Select a sound in the list first."); return; }
    if (wavOnly) { Warn("This is a WAV file without a .ds file; it can't be loaded for editing."); return; }
    LoadFile(KitDir() + L"\\" + n + L".ds");
}

namespace {

// fileform: a name without . \ / : * ? " < > |, and "Save .WAV"
class SaveDialog : public wxDialog {
public:
    SaveDialog(wxWindow* parent, const wxString& name, bool wav) : wxDialog(parent, wxID_ANY, "Save As...")
    {
        auto* s = new wxBoxSizer(wxVERTICAL);
        s->Add(new wxStaticText(this, wxID_ANY, "Sound &name:"), 0, wxLEFT | wxRIGHT | wxTOP, 8);
        text_ = new wxTextCtrl(this, wxID_ANY, name, wxDefaultPosition, wxSize(260, -1));
        text_->Bind(wxEVT_CHAR, [](wxKeyEvent& e) {
            static const wxString bad = ".\\/:*?\"<>|";
            if (bad.Find((wxChar)e.GetUnicodeKey()) != wxNOT_FOUND) { wxBell(); return; }
            e.Skip();
        });
        s->Add(text_, 0, wxEXPAND | wxALL, 8);
        wav_ = new wxCheckBox(this, wxID_ANY, "Save .&WAV");
        wav_->SetValue(wav);
        s->Add(wav_, 0, wxLEFT | wxRIGHT, 8);
        s->Add(CreateButtonSizer(wxOK | wxCANCEL), 0, wxEXPAND | wxALL, 8);
        SetSizerAndFit(s);
        text_->SetFocus();
        text_->SelectAll();
    }
    wxString Name() const { return text_->GetValue().Strip(wxString::both); }
    bool Wav() const { return wav_->GetValue(); }

private:
    wxTextCtrl* text_;
    wxCheckBox* wav_;
};

}  // namespace

void MainFrame::SaveAs()
{
    // butSave_Click
    std::wstring dir = KitDir();
    if (dir.empty()) { Warn("Choose a kit folder first (Kit menu, Set location)."); return; }
    std::wstring cur;
    bool wavOnly = false;
    SelectedSound(&cur, &wavOnly);
    SaveDialog dlg(this, cur, saveWav_ == 1);
    if (dlg.ShowModal() != wxID_OK) { saveWav_ = dlg.Wav() ? 1 : 0; return; }
    saveWav_ = dlg.Wav() ? 1 : 0;
    std::wstring name = dlg.Name().ToStdWstring();
    if (name.empty()) return;
    std::wstring ds = dir + L"\\" + name + L".ds", wav = dir + L"\\" + name + L".wav";
    if (fs::exists(wav) && !fs::exists(ds)) {
        if (wxMessageBox("Overwrite Existing .WAV File?", name, wxOK | wxCANCEL | wxICON_QUESTION, this) != wxOK)
            return;
    }
    if (!preset_.Save(ds)) { Warn("The sound could not be saved."); return; }
    if (saveWav_ == 1) {
        // checklist 4.6: the WAV is written when "Save .WAV" is ticked
        unsigned notes = 0;
        int code = 0;
        if (!playable_ && Render(&wav_, &notes, &code)) playable_ = true;
        FILE* f = _wfopen(wav.c_str(), L"wb");
        if (!playable_ || !f || fwrite(wav_.data(), 1, wav_.size(), f) != wav_.size()) Warn("The WAV could not be written.");
        if (f) fclose(f);
    }
    PlaySoundW(nullptr, nullptr, 0);
    FillSoundList();
    for (size_t i = 0; i < soundEntries_.size(); i++)
        if (soundEntries_[i].first == name && !soundEntries_[i].second) sounds_->SetSelection((int)i);
    SetTitleFor(ds);
    Announce(wxString("Saved ") + name, this);
}

void MainFrame::GenerateAll()
{
    // genform: render every .ds whose WAV is missing, with Cancel
    std::wstring dir = KitDir();
    std::vector<std::wstring> todo;
    for (const auto& e : soundEntries_)
        if (!e.second && !fs::exists(dir + L"\\" + e.first + L".wav")) todo.push_back(e.first);
    if (todo.empty()) { Announce("All WAV files exist already", this); return; }
    wxProgressDialog prog("Generating WAV files...", "", (int)todo.size(), this,
                          wxPD_CAN_ABORT | wxPD_APP_MODAL | wxPD_AUTO_HIDE);
    int done = 0;
    for (const auto& n : todo) {
        if (!prog.Update(done, n)) break;
        std::wstring ds = dir + L"\\" + n + L".ds", wav = dir + L"\\" + n + L".wav";
        std::vector<unsigned char> bytes;
        unsigned notes = 0;
        if (RenderDsFile(ds, &bytes, &notes) == DS_OK) {
            FILE* o = _wfopen(wav.c_str(), L"wb");
            if (o) { fwrite(bytes.data(), 1, bytes.size(), o); fclose(o); }
        }
        done++;
    }
    FillSoundList();
    Announce(wxString::Format("Generated %d WAV files", done), this);
}

void MainFrame::DeleteAllWavs()
{
    std::wstring dir = KitDir();
    double kb = 0;
    std::error_code ec;
    for (const auto& f : fs::directory_iterator(dir, ec)) {
        std::wstring ext = f.path().extension().wstring();
        for (wchar_t& c : ext) c = std::towlower(c);
        if (ext == L".wav") kb += (double)f.file_size(ec) / 1024;
    }
    if (wxMessageBox(wxString::Format("Delete the WAV files of all sounds in this kit (%.0fk)? Sounds without "
                                      "a .ds file are kept.", kb),
                     "Delete WAVs", wxOK | wxCANCEL | wxICON_WARNING, this) != wxOK)
        return;
    PlaySoundW(nullptr, nullptr, 0);
    for (const auto& e : soundEntries_)
        if (!e.second) DeleteFileW((dir + L"\\" + e.first + L".wav").c_str());
    FillSoundList();
    Announce("WAV files deleted", this);
}

void MainFrame::DeleteSound()
{
    std::wstring n;
    bool wavOnly;
    if (!SelectedSound(&n, &wavOnly)) return;
    if (wxMessageBox("Delete this sound?", kits_->GetStringSelection() + "\\" + n, wxOK | wxCANCEL | wxICON_WARNING,
                     this) != wxOK)
        return;
    PlaySoundW(nullptr, nullptr, 0);
    std::wstring base = KitDir() + L"\\" + n;
    if (!wavOnly) DeleteFileW((base + L".ds").c_str());
    DeleteFileW((base + L".wav").c_str());
    FillSoundList();
    Announce(wxString("Deleted ") + n, this);
}

void MainFrame::NewKit()
{
    wxTextEntryDialog dlg(this, "Kit name:", "New Kit");
    if (dlg.ShowModal() != wxID_OK) return;
    wxString name = dlg.GetValue().Strip(wxString::both);
    if (name.empty()) return;
    std::error_code ec;
    if (!fs::create_directory(dsPath_ + L"\\" + name.ToStdWstring(), ec) && ec) {
        Warn("The kit folder could not be made.");
        return;
    }
    int i = kits_->Append(name.Upper());
    kits_->SetSelection(i);
    FillSoundList();
    Announce("Kit " + name.Upper() + " made", this);
}

void MainFrame::SetLocation()
{
    wxDirDialog dlg(this, "Choose a folder that contains folders of .ds files", dsPath_);
    if (dlg.ShowModal() != wxID_OK) return;
    dsPath_ = dlg.GetPath().ToStdWstring();
    while (!dsPath_.empty() && dsPath_.back() == L'\\') dsPath_.pop_back();
    ReadKits();
    Announce(wxString::Format("%u kits", kits_->GetCount()), this);
}

void MainFrame::ShowHelp()
{
    for (const wchar_t* rel : {L"\\gui-help.md", L"\\..\\..\\..\\docs\\gui-help.md", L"\\..\\docs\\gui-help.md"}) {
        fs::path p = fs::path(ExeDir() + rel);
        std::error_code ec;
        if (fs::exists(p, ec)) {
            wxLaunchDefaultApplication(fs::canonical(p, ec).wstring());
            return;
        }
    }
    Warn("The help file gui-help.md was not found next to the program.");
}

// ---- Keys and closing -------------------------------------------------------------

void MainFrame::OnCharHook(wxKeyEvent& ev)
{
    int k = ev.GetKeyCode();
    // Alt+letter shortcuts of the labels (docs/gui-help.md). Windows' own
    // handling doesn't reach controls inside the section group boxes, so
    // they are done here: a button is pressed, a check box is focused and
    // toggled, anything else is focused.
    if (ev.AltDown() && !ev.ControlDown() && k >= 'A' && k <= 'Z') {
        const std::pair<int, wxWindow*> keys[] = {
            {'P', play_}, {'I', kits_}, {'D', sounds_}, {'L', load_}, {'S', save_}, {'T', chkOn_[0]},
            {'O', chkOn_[2]}, {'N', chkOn_[1]}, {'R', filter_}, {'A', masterOn_}, {'C', comment_}};
        for (const auto& [key, w] : keys) {
            if (key != k || !w || !w->IsEnabled()) continue;
            if (auto* b = wxDynamicCast(w, wxButton)) {
                wxCommandEvent e(wxEVT_BUTTON, b->GetId());
                e.SetEventObject(b);
                b->SetFocus();
                b->GetEventHandler()->ProcessEvent(e);
            } else if (auto* c = wxDynamicCast(w, wxCheckBox)) {
                c->SetFocus();
                c->SetValue(!c->GetValue());
                wxCommandEvent e(wxEVT_CHECKBOX, c->GetId());
                e.SetEventObject(c);
                e.SetInt(c->GetValue() ? 1 : 0);
                c->GetEventHandler()->ProcessEvent(e);
            } else {
                w->SetFocus();
            }
            return;
        }
    }
    // Form_KeyDown: F1-F12 play sounds 1-12, Shift+F1-F12 sounds 13-24
    if (k >= WXK_F1 && k <= WXK_F12 && !ev.ControlDown() && !ev.AltDown()) {
        PlaySoundAt(k - WXK_F1 + (ev.ShiftDown() ? 12 : 0));
        return;
    }
    // Enter plays, except where Enter has its own meaning (checklist 5)
    if ((k == WXK_RETURN || k == WXK_NUMPAD_ENTER) && !ev.HasAnyModifiers()) {
        wxWindow* f = FindFocus();
        bool own = wxDynamicCast(f, wxButton) || wxDynamicCast(f, wxListBox) ||
                   (wxDynamicCast(f, wxTextCtrl) && wxDynamicCast(f, wxTextCtrl)->IsMultiLine());
        if (!own) { Play(); return; }
    }
    ev.Skip();
}

void MainFrame::OnClose(wxCloseEvent& ev)
{
    // Form_QueryUnload
    SaveSettings();
    PlaySoundW(nullptr, nullptr, 0);
    DeleteFileW(tempDs_.c_str());
    DeleteFileW(tempWav_.c_str());
    ev.Skip();
}
