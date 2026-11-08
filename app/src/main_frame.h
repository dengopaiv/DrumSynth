// main_frame.h - the DrumSynth main window (gui/DRUMSYN.FRM), accessible.
#pragma once

#include <string>
#include <vector>
#include <wx/checkbox.h>
#include <wx/choice.h>
#include <wx/frame.h>
#include <wx/listbox.h>
#include <wx/stattext.h>
#include <wx/textctrl.h>

#include "access.h"
#include "envelope_editor.h"
#include "preset.h"

class MainFrame : public wxFrame {
public:
    explicit MainFrame(const wxString& openFile);

private:
    // Building the window
    wxSizer* MakeFileArea(wxWindow* p);
    wxSizer* MakeSections(wxWindow* p);
    ValueSlider* AddSlider(wxWindow* p, wxSizer* s, const wxString& label, int min, int max, int page,
                           ValueSlider::Formatter f, int* field);
    wxTextCtrl* AddText(wxWindow* p, wxSizer* s, const wxString& label, const wxString& unit,
                        std::string* field, int width = 70);
    wxCheckBox* AddCheck(wxWindow* p, wxSizer* s, const wxString& label, int* field);
    wxChoice* AddChoice(wxWindow* p, wxSizer* s, const wxString& label,
                        const std::vector<wxString>& items, int* field);
    void MakeMenus();

    // The preset and the controls
    void ApplyToControls();  // after loading
    void UpdateEnabling();   // chkOn_Click, comOMethod_Click
    void Changed();          // changed(): the sound must be rendered again
    void SectionToggled(int section, bool on);

    // Sound
    bool Render(std::vector<unsigned char>* wav, unsigned* notes, int* code);
    void Play();
    void PlayFile(const std::wstring& path);
    void Warn(const wxString& msg);
    void AnnounceNotes(unsigned notes);

    // Files and kits
    void LoadSettings();
    void SaveSettings();
    void ReadKits();
    void FillSoundList();
    std::wstring KitDir() const;
    bool SelectedSound(std::wstring* name, bool* wavOnly) const;
    void LoadSelected();
    void LoadFile(const std::wstring& path);
    void SaveAs();
    void PlaySoundAt(int index);
    void GenerateAll();
    void DeleteAllWavs();
    void DeleteSound();
    void NewKit();
    void SetLocation();
    void ShowHelp();
    void SetTitleFor(const std::wstring& path);

    void OnCharHook(wxKeyEvent& ev);
    void OnClose(wxCloseEvent& ev);

    Preset preset_;
    bool playable_ = false;
    std::vector<unsigned char> wav_;     // the last render, kept for PlaySound
    std::wstring tempDs_, tempWav_;
    std::wstring dsPath_;
    int saveWav_ = 1;
    std::wstring iniPath_;
    bool soundListMouse_ = false;
    bool loading_ = false;

    struct Bound { std::function<void()> apply; };
    std::vector<Bound> bindings_;        // control <- preset, for ApplyToControls

    wxButton* play_ = nullptr;
    wxButton* load_ = nullptr;
    wxListBox* kits_ = nullptr;
    wxListBox* sounds_ = nullptr;
    std::vector<std::pair<std::wstring, bool>> soundEntries_; // name, WAV only
    wxCheckBox* chkOn_[6] = {};
    wxCheckBox* track1_ = nullptr;
    wxCheckBox* track2_ = nullptr;
    wxChoice* wave1_ = nullptr;
    wxChoice* wave2_ = nullptr;
    wxChoice* method_ = nullptr;
    wxStaticText* paramLabel_ = nullptr;
    ValueSlider* param_ = nullptr;
    wxCheckBox* filter_ = nullptr;
    wxCheckBox* otFilter_ = nullptr;
    wxTextCtrl* comment_ = nullptr;
    EnvelopeEditor* env_ = nullptr;
};
