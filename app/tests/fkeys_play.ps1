# fkeys_play.ps1 - check that F1-F12 and the sound list play kit sounds by
# synthesizing them from their .ds files (docs/gui-checklist.md, section 5),
# without WAV files and without writing anything into the kit; that F5 plays
# the fifth sound, as in the original; and that Ctrl+P plays the sound being
# edited.
#
# wxWidgets sees F1-F12 through a keyboard hook, which only real key presses
# reach, so this test types: it brings DrumSynth to the front and checks
# before every key that DrumSynth is still the foreground window, stopping
# otherwise, so no key can reach another program. Don't use the keyboard or
# mouse while it runs (about 10 seconds). The sounds are audible.
#
# After each key it reads the sound list's selection and the status bar,
# where warnings such as "There is no WAV file for this sound" appear. Run
# from the repository root:
#
#   powershell -File app/tests/fkeys_play.ps1 [-Exe dist\DrumSynth-4.0.0-win64\DrumSynth.exe] [-Kit tr808]
#
# The program's DrumSyn.ini must point at a folder of kits (the release's
# does: Path=Kits). The program is closed with WM_CLOSE, so it saves its
# settings as usual.
param([string]$Exe = "build\app\Release\DrumSynth.exe", [string]$Kit = "tr808")
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Collections.Generic; using System.Text;
public static class FK {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc f, IntPtr l);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll", CharSet=CharSet.Unicode, EntryPoint="SendMessageW")] public static extern IntPtr SendText(IntPtr h, uint m, IntPtr w, StringBuilder l);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetParent(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  public static int Msg(IntPtr h, int m, int w) { return (int)SendMessage(h, (uint)m, (IntPtr)w, IntPtr.Zero); }
  public static List<IntPtr> Children(IntPtr top, string cls) {
    var r = new List<IntPtr>();
    EnumChildWindows(top, (h, l) => { var sb = new StringBuilder(64); GetClassName(h, sb, 64);
      if (sb.ToString() == cls) r.Add(h); return true; }, IntPtr.Zero);
    return r;
  }
  // the system copies LB_GETTEXT's text across processes
  public static string ItemText(IntPtr lb, int i) {
    int n = Msg(lb, 0x018A, i);                                       // LB_GETTEXTLEN
    var sb = new StringBuilder(n + 1); SendText(lb, 0x0189, (IntPtr)i, sb); return sb.ToString(); // LB_GETTEXT
  }
}
"@
$LB_SETCURSEL = 0x0186; $LB_GETCURSEL = 0x0188; $LB_GETCOUNT = 0x018B
$WM_COMMAND = 0x0111; $LBN_SELCHANGE = 1
$exePath = (Resolve-Path $Exe).Path
$fail = 0
function Check($ok, $what) { if ($ok) { "  ok: $what" } else { "  FAIL: $what"; $script:fail++ } }
function Status {
    # WM_GETTEXT gives a status bar's first field, and the system copies it
    # across processes (SB_GETTEXT would not be)
    $sb = New-Object System.Text.StringBuilder 512
    [void][FK]::SendText($script:statusBar, 0x000D, [IntPtr]512, $sb)
    return "status bar: '" + $sb.ToString() + "'"
}
function Test-Foreground {
    $id = [uint32]0
    [void][FK]::GetWindowThreadProcessId([FK]::GetForegroundWindow(), [ref]$id)
    return $id -eq $p.Id
}
function Send([string]$label, [string]$keys) {
    # never type into another window
    if (-not (Test-Foreground)) { throw "DrumSynth is not the foreground window; stopped before $label" }
    [System.Windows.Forms.SendKeys]::SendWait($keys)
    Start-Sleep -Milliseconds 1200
}

$p = Start-Process -FilePath $exePath -WorkingDirectory (Split-Path $exePath) -PassThru
Start-Sleep -Seconds 3
$p.Refresh()
$top = $p.MainWindowHandle
$script:title = $p.MainWindowTitle
try {
    $lists = [FK]::Children($top, "ListBox")
    $kits = $lists[0]; $sounds = $lists[1]
    $script:statusBar = ([FK]::Children($top, "msctls_statusbar32"))[0]

    # choose the kit as a click would: select it and notify the window
    $k = -1
    for ($i = 0; $i -lt [FK]::Msg($kits, $LB_GETCOUNT, 0); $i++) { if ([FK]::ItemText($kits, $i) -eq $Kit) { $k = $i } }
    if ($k -lt 0) { throw "kit $Kit not found" }
    [void][FK]::Msg($kits, $LB_SETCURSEL, $k)
    $id = [FK]::GetDlgCtrlID($kits) -band 0xFFFF    # wxWidgets' ids are negative
    [void][FK]::SendMessage([FK]::GetParent($kits), $WM_COMMAND, [IntPtr](($LBN_SELCHANGE -shl 16) -bor $id), $kits)
    Start-Sleep -Milliseconds 500
    # the kits' folder: [Files] Path in DrumSyn.ini, relative to the program's folder
    $exeDir = Split-Path $exePath
    $path = (Select-String -Path (Join-Path $exeDir "DrumSyn.ini") -Pattern "^Path=(.*)$").Matches[0].Groups[1].Value.Trim()
    if (-not [System.IO.Path]::IsPathRooted($path)) { $path = Join-Path $exeDir $path }
    $kitDir = Join-Path $path $Kit
    $before = @(Get-ChildItem $kitDir -Filter *.wav).Count
    $count = [FK]::Msg($sounds, $LB_GETCOUNT, 0)
    "kit $Kit`: $count sounds, $before WAV files, first sound '$([FK]::ItemText($sounds, 0))'"
    Check ($count -ge 5) "the kit has at least five sounds"

    # an Alt key press lets this process bring another window to the front
    [FK]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [FK]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
    [void][FK]::SetForegroundWindow($top)
    Start-Sleep -Milliseconds 800
    # that Alt tap can open DrumSynth's menu bar, which would swallow the
    # next key: Escape closes it (and does nothing otherwise). The focus
    # stays on the Play button, where the program starts.
    Send "Escape" "{ESC}"

    # F1 last, so that each key moves the selection
    foreach ($key in @(@{k = "{F3}"; n = "F3"; sel = 2}, @{k = "{F5}"; n = "F5"; sel = 4}, @{k = "{F1}"; n = "F1"; sel = 0})) {
        Send $key.n $key.k
        $sel = [FK]::Msg($sounds, $LB_GETCURSEL, 0)
        $st = Status
        "$($key.n): selected '$([FK]::ItemText($sounds, $sel))'; $st"
        Check ($sel -eq $key.sel) "$($key.n) selects and plays sound $($key.sel + 1)"
        Check ($st -notmatch "no WAV|could not") "$($key.n): no warning"
        Check ($st -notmatch "Rendered") "$($key.n) does not play the sound being edited"
    }
    # Space in the sound list plays the selected sound
    Send "Alt+D" "%d"
    Send "Space" " "
    $st = Status
    "Space in the list: $st"
    Check ($st -notmatch "no WAV|could not") "Space in the list: no warning"
    # Ctrl+P plays the sound being edited: its status shows the render
    Send "Ctrl+P" "^p"
    $st = Status
    "Ctrl+P: $st"
    Check ($st -match "Rendered") "Ctrl+P renders and plays the sound being edited"
    Check (@(Get-ChildItem $kitDir -Filter *.wav).Count -eq $before) "no WAV file written into the kit"
    $p.Refresh()
    Check (-not $p.HasExited) "the program is still running"
} catch {
    "FAIL: $_"
    $fail++
} finally {
    [void][FK]::PostMessage($top, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)   # WM_CLOSE
}
if ($fail) { "FAILED: $fail"; exit 1 }
"OK"
exit 0
