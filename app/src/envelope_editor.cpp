// envelope_editor.cpp - see envelope_editor.h.
#include "envelope_editor.h"

#include <algorithm>
#include <cmath>
#include <wx/dcbuffer.h>
#include <wx/menu.h>
#include <wx/sizer.h>

#include "access.h"
#include "vbtext.h"

namespace {

// The 13 view ranges of EnvRangeChange, shortest first; the default is
// 250 ms (EnvRangeIndex 6).
const struct { const char* name; double seconds; } kRanges[] = {
    {"16 ms", 0.016}, {"25 ms", 0.025}, {"40 ms", 0.04}, {"63 ms", 0.063}, {"100 ms", 0.1},
    {"160 ms", 0.16}, {"250 ms", 0.25}, {"400 ms", 0.4}, {"630 ms", 0.63}, {"1 sec", 1.0},
    {"1.6 sec", 1.6}, {"3 sec", 3.0}, {"10 sec", 10.0}};
const int kDefaultRange = 6;
// The longest time the keyboard editor allows for the last point (the
// original's limit is the right edge of the 10 second view).
const int kMaxTime = 44100 * 100;

// envcol() in Form_Load (VB colours are &HBBGGRR).
wxColour EnvColour(int e)
{
    static const unsigned long bgr[8] = {0, 0xB0C0FF, 0xC0FFC0, 0xFFC0C0, 0xFFC0C0, 0xFFC0FF, 0xFFC0FF, 0xF0F0C0};
    unsigned long c = bgr[e];
    return wxColour(c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF);
}

bool UsesPercent(int e) { return e == ENV_OT2 || e == ENV_FILTER; }

}  // namespace

// ---- The graph ---------------------------------------------------------------
class EnvelopeGraph : public wxPanel {
public:
    EnvelopeGraph(wxWindow* parent, EnvelopeEditor* ed, Preset* p, EnvelopeEditor::Host* host)
        : wxPanel(parent, wxID_ANY, wxDefaultPosition, wxSize(560, 150), wxBORDER_SIMPLE),
          ed_(ed), preset_(p), host_(host)
    {
        SetBackgroundStyle(wxBG_STYLE_PAINT);
        // The graph is for the mouse; keyboard users use the point list.
        SetCanFocus(false);
        Bind(wxEVT_PAINT, &EnvelopeGraph::OnPaint, this);
        Bind(wxEVT_LEFT_DOWN, &EnvelopeGraph::OnDown, this);
        Bind(wxEVT_LEFT_UP, &EnvelopeGraph::OnUp, this);
        Bind(wxEVT_MOTION, &EnvelopeGraph::OnMove, this);
        Bind(wxEVT_RIGHT_DOWN, &EnvelopeGraph::OnRight, this);
        SetToolTip("Envelope graph: click to add a point, drag to move it, drag off the top or bottom "
                   "to delete it, right-click for Copy, Paste and Reset.");
    }

private:
    // envbox: ScaleTop 102, ScaleHeight -104 (level 102 at the top, -2 at the bottom)
    double X(double t) const { return t / ed_->ViewRange() * GetClientSize().x; }
    double Y(double l) const { return (102.0 - l) / 104.0 * GetClientSize().y; }
    double T(int x) const { return x * ed_->ViewRange() / std::max(1, GetClientSize().x); }
    double L(int y) const { return 102.0 - y * 104.0 / std::max(1, GetClientSize().y); }

    void Draw(wxDC& dc, int e, bool current)
    {
        const Envelope& v = preset_->env[e];
        // DrawEnv: the filter envelope's last two segments are not drawn
        size_t next = e == ENV_FILTER ? 3 : 1;
        dc.SetPen(wxPen(current ? *wxBLACK : EnvColour(e), current ? 2 : 1));
        for (size_t ep = 0; ep + next < v.size(); ep++) {
            dc.DrawLine(wxRound(X(v[ep].time)), wxRound(Y(v[ep].level)), wxRound(X(v[ep + 1].time)),
                        wxRound(Y(v[ep + 1].level)));
        }
        if (!current) return;
        for (size_t i = 0; i < v.size(); i++) {
            int x = wxRound(X(v[i].time)), y = wxRound(Y(v[i].level));
            dc.SetBrush(i == ed_->Selected() ? *wxRED_BRUSH : *wxTRANSPARENT_BRUSH);
            dc.DrawRectangle(x - 3, y - 3, 7, 7);
        }
    }

    void OnPaint(wxPaintEvent&)
    {
        wxAutoBufferedPaintDC dc(this);
        dc.SetBackground(*wxWHITE_BRUSH);
        dc.Clear();
        for (int e = 1; e <= 7; e++)
            if (e != ed_->CurrentEnvelope() && host_->isOn(e)) Draw(dc, e, false);
        Draw(dc, ed_->CurrentEnvelope(), true);
    }

    void OnDown(wxMouseEvent& ev)
    {
        // envbox_MouseDown: a point within 1% of the view horizontally and
        // 4 level units vertically is picked up; otherwise a point is added
        Envelope& v = preset_->env[ed_->CurrentEnvelope()];
        double t = T(ev.GetX()), l = L(ev.GetY());
        double ew = ed_->ViewRange() / 100;
        drag_ = -1;
        size_t epos = 0;
        for (size_t i = 0; i < v.size(); i++) {
            if (std::fabs(t - v[i].time) < ew && std::fabs(l - v[i].level) < 4) drag_ = (int)i;
            if (t > v[i].time) epos = i;
        }
        if (drag_ < 0) {
            l = std::clamp(l, 0.0, 100.0);
            if (epos + 1 >= v.size()) {
                // beyond the last point: the original moves the last point out
                // to the click and adds the new point after it
                if (v.size() < (size_t)EnvelopeEditor::kMaxPoints) v.back().time = std::max(v.back().time, t);
            }
            if (ed_->InsertPoint(epos, t, l, false)) drag_ = (int)epos + 1;
            else wxBell();
        }
        if (drag_ >= 0) {
            ed_->SelectPoint(drag_);
            CaptureMouse();
        }
    }

    void OnMove(wxMouseEvent& ev)
    {
        if (drag_ < 0 || !ev.LeftIsDown()) return;
        Envelope& v = preset_->env[ed_->CurrentEnvelope()];
        double l = L(ev.GetY());
        if (l < -16 || l > 120) { // dragged off: delete, not the first or last point
            if (drag_ > 0 && (size_t)drag_ + 1 < v.size()) {
                ed_->DeletePoint(drag_, false);
                drag_ = -1;
            }
            return;
        }
        ed_->MovePoint(drag_, T(ev.GetX()), l);
    }

    void OnUp(wxMouseEvent&)
    {
        if (HasCapture()) ReleaseMouse();
        drag_ = -1;
    }

    void OnRight(wxMouseEvent&)
    {
        wxMenu menu; // mnuWave
        menu.Append(1, "&Copy");
        menu.Append(2, "&Paste");
        menu.Append(3, "&Reset");
        menu.AppendSeparator();
        menu.Append(4, "Cancel");
        int id = GetPopupMenuSelectionFromUser(menu);
        if (id == 1) ed_->Copy();
        else if (id == 2) ed_->Paste();
        else if (id == 3) ed_->Reset();
    }

    EnvelopeEditor* ed_;
    Preset* preset_;
    EnvelopeEditor::Host* host_;
    int drag_ = -1;
};

// ---- The editor ----------------------------------------------------------------
wxString EnvelopeEditor::EnvelopeName(int env, int method)
{
    switch (env) { // ShowEnvName
    case ENV_TONE: return "Tone";
    case ENV_NOISE: return "Noise";
    case ENV_OT1: return method == 0 ? "Overtone A" : "Overtone level";
    case ENV_OT2:
        if (method == 0) return "Overtone B";
        return method == 3 ? "Overtone frequency range" : "Overtone modulation depth";
    case ENV_BAND1: return "Noise Band 1";
    case ENV_BAND2: return "Noise Band 2";
    default: return "Filter frequency";
    }
}

EnvelopeEditor::EnvelopeEditor(wxWindow* parent, Preset* preset, Host host)
    : wxPanel(parent), preset_(preset), host_(std::move(host))
{
    auto* top = new wxBoxSizer(wxHORIZONTAL);
    top->Add(new wxStaticText(this, wxID_ANY, "&Envelope:"), 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 4);
    envChoice_ = new wxChoice(this, wxID_ANY);
    top->Add(envChoice_, 0, wxRIGHT, 12);
    top->Add(new wxStaticText(this, wxID_ANY, "&View range:"), 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, 4);
    rangeChoice_ = new wxChoice(this, wxID_ANY);
    for (const auto& r : kRanges) rangeChoice_->Append(r.name);
    rangeChoice_->SetSelection(kDefaultRange);
    top->Add(rangeChoice_, 0);

    graph_ = new EnvelopeGraph(this, this, preset_, &host_);

    auto* pts = new wxBoxSizer(wxHORIZONTAL);
    auto* left = new wxBoxSizer(wxVERTICAL);
    left->Add(new wxStaticText(this, wxID_ANY, "&Points:"), 0, wxBOTTOM, 2);
    list_ = new wxListBox(this, wxID_ANY, wxDefaultPosition, wxSize(300, 110));
    left->Add(list_, 1, wxEXPAND);
    pts->Add(left, 1, wxEXPAND | wxRIGHT, 8);

    auto* fields = new wxFlexGridSizer(2, 4, 6);
    fields->Add(new wxStaticText(this, wxID_ANY, "&Time (samples):"), 0, wxALIGN_CENTER_VERTICAL);
    auto* trow = new wxBoxSizer(wxHORIZONTAL);
    time_ = new wxSpinCtrl(this, wxID_ANY, "", wxDefaultPosition, wxSize(100, -1), wxSP_ARROW_KEYS, 0, kMaxTime, 0);
    trow->Add(time_, 0);
    timeMs_ = new wxStaticText(this, wxID_ANY, "0 ms");
    trow->Add(timeMs_, 0, wxALIGN_CENTER_VERTICAL | wxLEFT, 6);
    fields->Add(trow);
    fields->Add(new wxStaticText(this, wxID_ANY, "&Level (0 to 100):"), 0, wxALIGN_CENTER_VERTICAL);
    level_ = new wxSpinCtrl(this, wxID_ANY, "", wxDefaultPosition, wxSize(100, -1), wxSP_ARROW_KEYS, 0, 100, 0);
    fields->Add(level_);
    auto* buttons = new wxBoxSizer(wxHORIZONTAL);
    add_ = new wxButton(this, wxID_ANY, "&Add point");
    del_ = new wxButton(this, wxID_ANY, "&Delete point");
    auto* copy = new wxButton(this, wxID_ANY, "C&opy envelope");
    paste_ = new wxButton(this, wxID_ANY, "Pa&ste envelope");
    auto* reset = new wxButton(this, wxID_ANY, "&Reset envelope");
    for (wxButton* b : {add_, del_, copy, paste_, reset}) buttons->Add(b, 0, wxRIGHT, 4);
    auto* right = new wxBoxSizer(wxVERTICAL);
    right->Add(fields, 0, wxBOTTOM, 6);
    right->Add(buttons, 0);
    pts->Add(right, 0);

    auto* main = new wxBoxSizer(wxVERTICAL);
    main->Add(top, 0, wxBOTTOM, 4);
    main->Add(graph_, 1, wxEXPAND | wxBOTTOM, 4);
    main->Add(pts, 0, wxEXPAND);
    SetSizer(main);

    paste_->Disable(); // mnuPaste is disabled until a Copy

    envChoice_->Bind(wxEVT_CHOICE, &EnvelopeEditor::OnChoice, this);
    rangeChoice_->Bind(wxEVT_CHOICE, &EnvelopeEditor::OnRange, this);
    list_->Bind(wxEVT_LISTBOX, &EnvelopeEditor::OnList, this);
    list_->Bind(wxEVT_KEY_DOWN, &EnvelopeEditor::OnListKey, this);
    time_->Bind(wxEVT_SPINCTRL, &EnvelopeEditor::OnTime, this);
    level_->Bind(wxEVT_SPINCTRL, &EnvelopeEditor::OnLevel, this);
    add_->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { AddAtSelection(); });
    del_->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { DeletePoint(sel_, true); });
    copy->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { Copy(); });
    paste_->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { Paste(); });
    reset->Bind(wxEVT_BUTTON, [this](wxCommandEvent&) { Reset(); });

    UpdateNames();
    Reload();
}

double EnvelopeEditor::ViewRange() const
{
    int i = rangeChoice_->GetSelection();
    return 44100.0 * kRanges[i < 0 ? kDefaultRange : i].seconds;
}

void EnvelopeEditor::UpdateNames()
{
    int m = host_.overtoneMethod();
    filling_ = true;
    envChoice_->Clear();
    for (int e = 1; e <= 7; e++) envChoice_->Append(EnvelopeName(e, m));
    envChoice_->SetSelection(cur_ - 1);
    filling_ = false;
}

void EnvelopeEditor::SelectEnvelope(int e)
{
    cur_ = std::clamp(e, 1, 7);
    envChoice_->SetSelection(cur_ - 1);
    sel_ = 0;
    Reload();
}

void EnvelopeEditor::Reload()
{
    if (sel_ >= env().size()) sel_ = env().size() - 1;
    FillList();
    UpdateFields();
    graph_->Refresh();
}

void EnvelopeEditor::FocusPoints() { list_->SetFocus(); }

wxString EnvelopeEditor::PointText(size_t i) const
{
    const Envelope& v = preset_->env[cur_];
    return wxString::Format("Point %zu of %zu: %s, %s", i + 1, v.size(), vb::Time(v[i].time),
                            vb::EnvLevelText(v[i].level, UsesPercent(cur_)));
}

void EnvelopeEditor::FillList()
{
    filling_ = true;
    wxArrayString rows;
    for (size_t i = 0; i < env().size(); i++) rows.Add(PointText(i));
    if (list_->GetCount() == rows.size()) {
        for (size_t i = 0; i < rows.size(); i++)
            if (list_->GetString(i) != rows[i]) list_->SetString(i, rows[i]);
    } else {
        list_->Set(rows);
    }
    list_->SetSelection((int)sel_);
    filling_ = false;
}

void EnvelopeEditor::UpdateFields()
{
    const Envelope& v = env();
    const EnvPoint& p = v[sel_];
    filling_ = true;
    bool first = sel_ == 0, last = sel_ + 1 == v.size();
    double lo = first ? 0 : v[sel_ - 1].time;
    double hi = first ? 0 : last ? kMaxTime : v[sel_ + 1].time;
    time_->SetRange((int)std::ceil(lo), (int)std::floor(std::max(lo, hi)));
    time_->SetValue((int)std::floor(p.time + 0.5));
    time_->Enable(!first);  // the first point stays at time 0
    timeMs_->SetLabel(vb::Time(p.time));
    level_->SetValue((int)std::floor(p.level + 0.5));
    level_->Enable(!last);  // the last point's level is always 0
    del_->Enable(!first && !last);
    add_->Enable(v.size() < (size_t)kMaxPoints);
    filling_ = false;
}

void EnvelopeEditor::SelectPoint(size_t i)
{
    sel_ = std::min(i, env().size() - 1);
    list_->SetSelection((int)sel_);
    UpdateFields();
    graph_->Refresh();
}

void EnvelopeEditor::Edited()
{
    FillList();
    UpdateFields();
    graph_->Refresh();
    if (host_.changed) host_.changed();
}

bool EnvelopeEditor::InsertPoint(size_t after, double time, double level, bool announce)
{
    Envelope& v = env();
    if (v.size() >= (size_t)kMaxPoints) {
        if (announce) { wxBell(); Announce("An envelope can have at most 31 points", this); }
        return false;
    }
    after = std::min(after, v.size() - 1);
    double lo = v[after].time, hi = after + 1 < v.size() ? v[after + 1].time : kMaxTime;
    time = std::clamp(time, lo, hi);
    v.insert(v.begin() + after + 1, EnvPoint{time, std::clamp(level, 0.0, 100.0)});
    if (after + 2 == v.size()) v.back().level = 0; // a new last point
    sel_ = after + 1;
    Edited();
    if (announce) Announce("Added " + PointText(sel_), this);
    return true;
}

void EnvelopeEditor::AddAtSelection()
{
    // halfway to the next point; after the last point, a little later, so
    // the old last point can be given a level
    size_t i = sel_;
    const Envelope& v = env();
    double t, l;
    if (i + 1 < v.size()) { t = (v[i].time + v[i + 1].time) / 2; l = (v[i].level + v[i + 1].level) / 2; }
    else { t = v[i].time + std::max(441.0, ViewRange() / 10); l = 0; }
    InsertPoint(i, std::floor(t + 0.5), std::floor(l + 0.5), true);
}

bool EnvelopeEditor::DeletePoint(size_t i, bool announce)
{
    Envelope& v = env();
    if (i == 0 || i + 1 >= v.size()) {
        if (announce) { wxBell(); Announce("The first and last points can't be deleted", this); }
        return false;
    }
    v.erase(v.begin() + i);
    sel_ = i - 1;
    Edited();
    if (announce) Announce("Deleted. " + PointText(sel_), this);
    return true;
}

void EnvelopeEditor::MovePoint(size_t i, double time, double level)
{
    // envbox_MouseMove: between the neighbours; the first at 0; levels 0-100;
    // the last point's level 0
    Envelope& v = env();
    if (i >= v.size()) return;
    double lo = i == 0 ? 0 : v[i - 1].time;
    double hi = i == 0 ? 0 : i + 1 < v.size() ? v[i + 1].time : kMaxTime;
    v[i].time = std::clamp(time, lo, hi);
    v[i].level = (i + 1 == v.size()) ? 0 : std::clamp(level, 0.0, 100.0);
    sel_ = i;
    Edited();
}

void EnvelopeEditor::Copy()
{
    clip_ = env();
    haveClip_ = true;
    paste_->Enable();
    Announce(EnvelopeName(cur_, host_.overtoneMethod()) + " envelope copied", this);
}

void EnvelopeEditor::Paste()
{
    if (!haveClip_) return;
    // mnuPaste_Click copies array slots 0-18 only: points, and the end marker
    // if it falls within them. Longer envelopes keep the target's slots from
    // 19 on (docs/gui-checklist.md 3.11).
    std::vector<EnvPoint> slots(33, EnvPoint{-1, 0});
    for (size_t i = 0; i < env().size() && i < 33; i++) slots[i] = env()[i];
    for (size_t i = 0; i < 19; i++) slots[i] = i < clip_.size() ? clip_[i] : EnvPoint{-1, 0};
    Envelope out;
    for (const EnvPoint& p : slots) {
        if (p.time < 0) break;
        out.push_back(p);
    }
    if (out.empty()) out.push_back({0, 0});
    env() = out;
    sel_ = 0;
    Edited();
    Announce("Envelope pasted, " + wxString::Format("%zu points", out.size()), this);
}

void EnvelopeEditor::Reset()
{
    env() = ResetEnvelope(cur_);
    sel_ = 0;
    Edited();
    Announce("Envelope reset", this);
}

void EnvelopeEditor::OnChoice(wxCommandEvent&)
{
    if (filling_) return;
    cur_ = envChoice_->GetSelection() + 1;
    sel_ = 0;
    Reload();
}

void EnvelopeEditor::OnRange(wxCommandEvent&) { graph_->Refresh(); }

void EnvelopeEditor::OnList(wxCommandEvent&)
{
    if (filling_) return;
    int i = list_->GetSelection();
    if (i >= 0) SelectPoint(i);
}

void EnvelopeEditor::OnListKey(wxKeyEvent& ev)
{
    int k = ev.GetKeyCode();
    if (k == WXK_DELETE) { DeletePoint(sel_, true); return; }
    if (k == WXK_INSERT) { AddAtSelection(); return; }
    if (ev.ControlDown() && k == 'C') { Copy(); return; }
    if (ev.ControlDown() && k == 'V') { Paste(); return; }
    ev.Skip();
}

void EnvelopeEditor::OnTime(wxSpinEvent& ev)
{
    if (filling_) return;
    MovePoint(sel_, ev.GetPosition(), env()[sel_].level);
}

void EnvelopeEditor::OnLevel(wxSpinEvent& ev)
{
    if (filling_) return;
    MovePoint(sel_, env()[sel_].time, ev.GetPosition());
}
