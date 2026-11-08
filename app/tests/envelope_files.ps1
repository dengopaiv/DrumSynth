# envelope_files.ps1 - check the envelope files (.dse) and "Load envelope
# from sound" (docs/gui-checklist.md, section 5) through the real dialogs,
# with the keyboard:
#
#   1. start with a sound, and read its Tone envelope's point list;
#   2. Ctrl+Shift+S: save the envelope as a file (typed into the dialog);
#   3. Envelope menu, Reset: the list must change;
#   4. Ctrl+Shift+O: load the file: the list must be as in 1;
#   5. Envelope menu, Load envelope from sound: another sound's Tone
#      envelope (the choice offered first): the list must have its points.
#
# Like fkeys_play.ps1 it types real keys, only while a DrumSynth window (the
# main window or one of its dialogs) is in front, and stops otherwise. Don't
# use the keyboard or mouse while it runs (about 20 seconds). The program's
# DrumSyn.ini is restored afterwards, so the test's folder isn't remembered.
# Run from the repository root:
#
#   powershell -File app/tests/envelope_files.ps1 [-Exe build\app\Release\DrumSynth.exe]
param([string]$Exe = "build\app\Release\DrumSynth.exe",
      [string]$Ds = "drumsynths\tr808\Kick.ds", [string]$Other = "drumsynths\tr808\Handclap.ds")
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Collections.Generic; using System.Text;
public static class EF {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc f, IntPtr l);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll", CharSet=CharSet.Unicode, EntryPoint="SendMessageW")] public static extern IntPtr SendText(IntPtr h, uint m, IntPtr w, StringBuilder l);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern IntPtr GetParent(IntPtr h);
  [DllImport("user32.dll", CharSet=CharSet.Unicode, EntryPoint="SendMessageW")] public static extern IntPtr SetText(IntPtr h, uint m, IntPtr w, string l);
  // the file name box of the file dialog in front: the Edit in a ComboBox
  public static bool SetFileName(string name) {
    IntPtr found = IntPtr.Zero;
    EnumChildWindows(GetForegroundWindow(), (h, l) => { var c = new StringBuilder(64); GetClassName(h, c, 64);
      var pc = new StringBuilder(64); GetClassName(GetParent(h), pc, 64);
      if (c.ToString() == "Edit" && pc.ToString() == "ComboBox") { found = h; return false; } return true; }, IntPtr.Zero);
    if (found == IntPtr.Zero) return false;
    SetText(found, 0x000C, IntPtr.Zero, name);   // WM_SETTEXT
    return true;
  }
  // the texts of the window in front, for failure messages
  public static string FrontTexts() {
    var r = new StringBuilder();
    EnumChildWindows(GetForegroundWindow(), (h, l) => { var c = new StringBuilder(64); GetClassName(h, c, 64);
      var t = new StringBuilder(300); SendText(h, 0x000D, (IntPtr)300, t);
      if (t.Length > 0) r.Append(c + " '" + t + "'; "); return true; }, IntPtr.Zero);
    return r.ToString();
  }
  public static string FrontTitle() { var t = new StringBuilder(256); GetWindowText(GetForegroundWindow(), t, 256); return t.ToString(); }
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  public static List<IntPtr> Children(IntPtr top, string cls) {
    var r = new List<IntPtr>();
    EnumChildWindows(top, (h, l) => { var sb = new StringBuilder(64); GetClassName(h, sb, 64);
      if (sb.ToString() == cls) r.Add(h); return true; }, IntPtr.Zero);
    return r;
  }
  // the items of a list box (the system copies LB_GETTEXT across processes)
  public static string[] Items(IntPtr lb) {
    int n = (int)SendMessage(lb, 0x018B, IntPtr.Zero, IntPtr.Zero);   // LB_GETCOUNT
    var r = new string[n];
    for (int i = 0; i < n; i++) {
      int len = (int)SendMessage(lb, 0x018A, (IntPtr)i, IntPtr.Zero);  // LB_GETTEXTLEN
      var sb = new StringBuilder(len + 1); SendText(lb, 0x0189, (IntPtr)i, sb); r[i] = sb.ToString();
    }
    return r;
  }
}
"@
$exePath = (Resolve-Path $Exe).Path
$exeDir = Split-Path $exePath
$fail = 0
function Check($ok, $what) { if ($ok) { "  ok: $what" } else { "  FAIL: $what"; $script:fail++ } }
function Test-Foreground {
    $id = [uint32]0
    [void][EF]::GetWindowThreadProcessId([EF]::GetForegroundWindow(), [ref]$id)
    return $id -eq $p.Id
}
function Send([string]$label, [string]$keys, [int]$wait = 1200) {
    # never type into another program's window
    if (-not (Test-Foreground)) { throw "DrumSynth is not in front; stopped before $label" }
    [System.Windows.Forms.SendKeys]::SendWait($keys)
    Start-Sleep -Milliseconds $wait
}
# wait until a window of DrumSynth whose title matches is in front (the
# first file dialog can take seconds to open)
function Wait-Front([string]$title, [int]$seconds = 15) {
    $end = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $end) {
        if ((Test-Foreground) -and [EF]::FrontTitle() -match $title) { Start-Sleep -Milliseconds 300; return }
        Start-Sleep -Milliseconds 200
    }
    throw "no window '$title' in front (front: '$([EF]::FrontTitle())': $([EF]::FrontTexts()))"
}
# Choose a file in the file dialog in front: put the name into its name
# box and press its Save or Open button. (Typing the name would open the
# box's autocomplete list, and Enter would take a suggestion or, just after
# the dialog opens, reach another part of it.) The file dialogs are Windows'
# own; what is tested is what DrumSynth does with the file.
function Choose-File([string]$name) {
    if (-not (Test-Foreground)) { throw "DrumSynth is not in front; stopped before the file name" }
    if (-not [EF]::SetFileName($name)) { throw "no file name box in '$([EF]::FrontTitle())'" }
    Start-Sleep -Milliseconds 300
    [void][EF]::PostMessage([EF]::GetForegroundWindow(), 0x0111, [IntPtr]1, [IntPtr]::Zero)   # WM_COMMAND IDOK
}
function Points { ([EF]::Items($script:points)) -join " | " }
function EnvLine([string]$ds) {
    # the [Tone] Envelope line of a .ds, as points "time,level"
    $inTone = $false
    foreach ($l in Get-Content $ds) {
        if ($l -match '^\[') { $inTone = $l -eq '[Tone]' }
        elseif ($inTone -and $l -match '^Envelope=(.*)$') { return $Matches[1].Trim() }
    }
}

$work = Join-Path $env:TEMP "ds_envelope_test"
New-Item -ItemType Directory -Force $work | Out-Null
$dse = Join-Path $work "Kick tone test.dse"
Remove-Item $dse -ErrorAction SilentlyContinue
$ini = Join-Path $exeDir "DrumSyn.ini"
$iniBackup = if (Test-Path $ini) { Get-Content $ini -Raw } else { $null }

$p = Start-Process -FilePath $exePath -ArgumentList "`"$((Resolve-Path $Ds).Path)`"" -WorkingDirectory $exeDir -PassThru
Start-Sleep -Seconds 3
$p.Refresh()
$top = $p.MainWindowHandle
try {
    $script:points = ([EF]::Children($top, "ListBox"))[2]   # kits, sounds, points
    $before = Points
    "1. $Ds, Tone: $before"
    Check ([EF]::Items($script:points).Count -eq (EnvLine $Ds).Split(' ').Count) "the point list has the sound's Tone points"

    [EF]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [EF]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
    [void][EF]::SetForegroundWindow($top)
    Start-Sleep -Milliseconds 800
    Send "Escape" "{ESC}"   # the Alt tap may have opened the menu bar

    Send "Ctrl+Shift+S" "^+s" 0
    Wait-Front "^Save the Tone envelope$"
    Choose-File $dse
    Wait-Front " - DrumSynth$"
    Check (Test-Path $dse) "2. Ctrl+Shift+S saved $dse"
    if (Test-Path $dse) {
        $text = Get-Content $dse -Raw
        "   file: " + ($text -replace "`r`n", " / ")
        Check ($text -match "\[DrumSynth Envelope\]" -and $text -match "Envelope=$([regex]::Escape((EnvLine $Ds)))") "the file holds the envelope as the .ds has it"
    }

    Send "Envelope menu" "%e" 800
    Send "Reset" "r" 1000
    $reset = Points
    "3. after Reset: $reset"
    Check ($reset -ne $before) "Reset changed the envelope"

    Send "Ctrl+Shift+O" "^+o" 0
    Wait-Front "^Load an envelope into Tone$"
    Choose-File $dse
    Wait-Front " - DrumSynth$"
    $loaded = Points
    "4. after loading the file: $loaded"
    Check ($loaded -eq $before) "loading the file gave the envelope back"

    $otherPath = (Resolve-Path $Other).Path
    Send "Envelope menu" "%e" 800
    Send "Load envelope from sound" "u" 0
    Wait-Front "^Load an envelope into Tone from a sound$"
    Choose-File $otherPath
    Wait-Front "^Load envelope from sound$"
    Send "Enter (the Tone envelope, offered first)" "{ENTER}" 0
    Wait-Front " - DrumSynth$"
    $fromSound = Points
    $expect = (EnvLine $Other).Split(' ').Count
    "5. after loading the Tone envelope of $Other ($expect points): $fromSound"
    Check ([EF]::Items($script:points).Count -eq $expect) "the point list has the other sound's Tone points"
    $p.Refresh()
    Check (-not $p.HasExited) "the program is still running"
} catch {
    "FAIL: $_"
    $fail++
} finally {
    if (-not $p.HasExited) {
        [void][EF]::PostMessage($top, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)   # WM_CLOSE
        Start-Sleep -Seconds 2
        if (-not $p.HasExited) { Stop-Process $p }
    }
    if ($null -ne $iniBackup) { Set-Content -Path $ini -Value $iniBackup -NoNewline -Encoding Default }
    Remove-Item $work -Recurse -ErrorAction SilentlyContinue
}
if ($fail) { "FAILED: $fail"; exit 1 }
"OK"
exit 0
