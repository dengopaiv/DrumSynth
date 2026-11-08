<#
.SYNOPSIS
    Drive the DrumSynth GUI with the keyboard under a portable NVDA and print what NVDA
    speaks. Based on C:\GIT\environment\test-addon.ps1: NVDA logs every speech sequence at
    log level 12 (IO), so its log is a transcript of what a user would hear.

    !! THIS TERMINATES ANY RUNNING NVDA !! The installed NVDA is restarted afterwards
    (unless -NoRestore). Fallback speech: Narrator, Win+Ctrl+Enter.

.EXAMPLE
    powershell -File app/tests/nvda_speech.ps1 -Ds drumsynths\Kit\sound.ds
#>
param(
    [Parameter(Mandatory)] [string] $Ds,
    [string] $Exe = "build\app\Release\DrumSynth.exe",
    [string] $Portable = "C:\git\screen reader\nvda\NVDA\nvda.exe",
    [switch] $NoRestore
)
$ErrorActionPreference = 'Stop'
$installed = 'C:\Program Files\NVDA\nvda.exe'
$work = Join-Path ([System.IO.Path]::GetTempPath()) ("ds-nvda-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
$cfg = Join-Path $work 'config'
$logFile = Join-Path $work 'nvda.log'
New-Item -ItemType Directory -Path $cfg -Force | Out-Null
if (-not (Test-Path $Portable)) {
    # no portable copy: generate one from the installed NVDA (as test-addon.ps1 does)
    if (-not (Test-Path $installed)) { throw "No portable NVDA and no installed NVDA." }
    $gen = Join-Path $work 'nvda-portable'
    & $installed --create-portable-silent --portable-path=$gen
    for ($i = 0; $i -lt 60 -and -not (Test-Path (Join-Path $gen 'nvda.exe')); $i++) { Start-Sleep -Seconds 1 }
    Start-Sleep -Seconds 5
    $Portable = Join-Path $gen 'nvda.exe'
    if (-not (Test-Path $Portable)) { throw "Generating a portable NVDA failed ($Portable)" }
}

$wasRunning = $false
if (Test-Path $installed) {
    $check = Start-Process -FilePath $installed -ArgumentList '--check-running' -Wait -PassThru
    if ($check.ExitCode -eq 0) { $wasRunning = $true }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class Fg {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
}
"@
function Test-GuiForeground {
    $pid2 = [uint32]0
    [void][Fg]::GetWindowThreadProcessId([Fg]::GetForegroundWindow(), [ref]$pid2)
    return $pid2 -eq $gui.Id
}
function Set-GuiForeground {
    # an Alt key press lets this process move another window to the front
    [Fg]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)
    [Fg]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
    [void][Fg]::SetForegroundWindow($gui.MainWindowHandle)
    Start-Sleep -Milliseconds 800
    return (Test-GuiForeground)
}

# the GUI
$exePath = (Resolve-Path $Exe).Path
$gui = Start-Process -FilePath $exePath -ArgumentList "`"$((Resolve-Path $Ds).Path)`"" -WorkingDirectory (Split-Path $exePath) -PassThru
Start-Sleep -Seconds 3
$gui.Refresh()
$title = $gui.MainWindowTitle

# NVDA
& $Portable --config-path=$cfg --log-file=$logFile --log-level=12 --minimal --no-sr-flag
Start-Sleep -Seconds 6

function Step([string]$label, [string]$keys, [int]$wait = 900) {
    # Never type into another window: stop if DrumSynth is not in front.
    if (-not (Test-GuiForeground)) { throw "DrumSynth is not the foreground window; stopped before '$label'" }
    Add-Content -Path (Join-Path $work 'steps.txt') -Value ("{0:o} {1}" -f (Get-Date), $label)
    [System.Windows.Forms.SendKeys]::SendWait($keys)
    Start-Sleep -Milliseconds $wait
}

try {
    if (-not (Set-GuiForeground)) { throw "Could not bring DrumSynth to the front" }
    Start-Sleep -Seconds 1
    Step "Play: Alt+P" "%p"
    Step "Tab to the kit list" "{TAB}"
    Step "Tab to the sound list" "{TAB}"
    Step "Sounds: Down" "{DOWN}"
    Step "Sounds: Space plays the WAV" " " 1500
    Step "Tab to Load" "{TAB}"
    Step "Tab to Save" "{TAB}"
    Step "Tab to Tone on" "{TAB}"
    Step "Tab to Tone level" "{TAB}"
    Step "Tone level: Right" "{RIGHT}"
    Step "Tone level: Page Down" "{PGDN}"
    Step "Tab to start frequency" "{TAB}"
    Step "Tab to end frequency" "{TAB}"
    Step "Tab to droop" "{TAB}"
    Step "Droop: End" "{END}"
    Step "Envelope points: Ctrl+E" "^e"
    Step "Points: Down" "{DOWN}"
    Step "Points: Ctrl+N adds a point" "^n" 1500
    Step "Tab to time field" "{TAB}"
    Step "Time: Up" "{UP}"
    Step "Tab to level field" "{TAB}"
    Step "Level: Up" "{UP}"
    Step "Points again: Ctrl+E" "^e"
    Step "Copy envelope: Ctrl+C" "^c" 1500
    Step "Play: F5" "{F5}" 2500
    Step "Envelope choice: Alt+V" "%v"
    Step "Envelope choice: Down" "{DOWN}"
    Step "Overtones on: Alt+O" "%o"
    Step "Toggle it back: Space" " " 1200
    Step "Kit menu: Alt+K" "%k"
    Step "Close menu: Escape" "{ESC}"
} finally {
    Start-Sleep -Seconds 2
    & $Portable --quit
    Start-Sleep -Seconds 3
    Stop-Process -Id $gui.Id -ErrorAction SilentlyContinue
    # Always leave a screen reader running: restart the installed NVDA if none is.
    # (--check-running exits with 0 if an NVDA runs; the portable copy is
    # given time to exit first)
    Start-Sleep -Seconds 3
    $check = Start-Process -FilePath $installed -ArgumentList '--check-running' -Wait -PassThru
    if (-not $NoRestore -and (Test-Path $installed) -and $check.ExitCode -ne 0) {
        Start-Process -FilePath $installed
        Start-Sleep -Seconds 3
        Write-Output "Installed NVDA restarted."
    }
}

"=== Steps and speech ==="
Get-Content $logFile | Select-String -Pattern 'Speaking\s+(.*)$' | ForEach-Object { "  " + $_.Matches[0].Groups[1].Value }
"=== Steps sent ==="
Get-Content (Join-Path $work 'steps.txt')
"(log: $logFile)"
