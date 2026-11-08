# smoke_play.ps1 - start the GUI with a .ds file, press Play through the
# menu command, and check that the program is still running and has written
# its temporary preset (%TEMP%\DrumSyn-.tmp, in savefile's format) and
# rendered it. Run from the repository root:
#
#   powershell -File app/tests/smoke_play.ps1 -Ds drumsynths\kit\sound.ds
#
# ID_PLAY is wxID_HIGHEST + 1 (6001 with wxWidgets 3.3).
param([string]$Ds, [string]$Exe = "build\app\Release\DrumSynth.exe", [int]$Command = 6001)
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class W {
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
}
"@
$tmp = Join-Path $env:TEMP "DrumSyn-.tmp"
Remove-Item $tmp -ErrorAction SilentlyContinue
$exePath = (Resolve-Path $Exe).Path
$p = Start-Process -FilePath $exePath -ArgumentList "`"$((Resolve-Path $Ds).Path)`"" -WorkingDirectory (Split-Path $exePath) -PassThru
Start-Sleep -Seconds 3
$p.Refresh()
Write-Output ("title: " + $p.MainWindowTitle)
[W]::PostMessage($p.MainWindowHandle, 0x0111, [IntPtr]$Command, [IntPtr]0) | Out-Null   # WM_COMMAND
Start-Sleep -Seconds 2
$p.Refresh()
if ($p.HasExited) { Write-Output "FAIL: the program exited"; exit 1 }
if (-not (Test-Path $tmp)) { Write-Output "FAIL: no temporary preset written"; Stop-Process $p; exit 1 }
Write-Output "OK: still running, temporary preset written ($((Get-Item $tmp).Length) bytes)"
Stop-Process $p
exit 0
