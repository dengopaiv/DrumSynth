// envelope_editor.h - the accessible envelope editor.
//
// The original edits envelopes only with the mouse, on a graph
// (gui/DRUMSYN.FRM, envbox_Mouse*). This editor keeps that graph, with the
// same mouse rules, for sighted users, and adds what a keyboard and screen
// reader need: a choice of envelope, a list of points read as
// "Point 2 of 3: 45.4 ms, -14.0 dB", fields for the selected point's time and
// level, and buttons for adding, deleting, copying, pasting and resetting.
// The rules are the original's (docs/gui-checklist.md, section 3).
#pragma once

#include <functional>
#include <wx/button.h>
#include <wx/choice.h>
#include <wx/listbox.h>
#include <wx/panel.h>
#include <wx/spinctrl.h>
#include <wx/stattext.h>

#include "preset.h"

class EnvelopeGraph;

class EnvelopeEditor : public wxPanel {
public:
    struct Host {
        std::function<bool(int env)> isOn;        // envIsOn()
        std::function<int()> overtoneMethod;      // for the envelope names
        std::function<void()> changed;            // an envelope was edited
    };
    EnvelopeEditor(wxWindow* parent, Preset* preset, Host host);

    void SelectEnvelope(int env);   // EnvSelChange
    int CurrentEnvelope() const { return cur_; }
    void Reload();                  // after the preset changed
    void UpdateNames();             // after the overtone method changed
    void FocusPoints();

    // Editing operations, shared by the buttons, the keys and the graph.
    bool InsertPoint(size_t after, double time, double level, bool announce);
    bool DeletePoint(size_t i, bool announce);
    void MovePoint(size_t i, double time, double level);
    void AddAtSelection();
    void Copy();
    void Paste();
    void Reset();
    size_t Selected() const { return sel_; }
    void SelectPoint(size_t i);
    double ViewRange() const;       // samples shown by the graph

    static wxString EnvelopeName(int env, int method);
    static const int kMaxPoints = 31;   // insert only while the last index < 30

private:
    Envelope& env() { return preset_->env[cur_]; }
    wxString PointText(size_t i) const;
    void FillList();
    void UpdateFields();
    void OnChoice(wxCommandEvent&);
    void OnRange(wxCommandEvent&);
    void OnList(wxCommandEvent&);
    void OnListKey(wxKeyEvent&);
    void OnTime(wxSpinEvent&);
    void OnLevel(wxSpinEvent&);
    void Edited();

    Preset* preset_;
    Host host_;
    int cur_ = ENV_TONE;
    size_t sel_ = 0;
    Envelope clip_;
    bool haveClip_ = false;
    bool filling_ = false;

    wxChoice* envChoice_;
    wxChoice* rangeChoice_;
    EnvelopeGraph* graph_;
    wxListBox* list_;
    wxSpinCtrl* time_;
    wxStaticText* timeMs_;
    wxSpinCtrl* level_;
    wxButton* add_;
    wxButton* del_;
    wxButton* paste_;
};
