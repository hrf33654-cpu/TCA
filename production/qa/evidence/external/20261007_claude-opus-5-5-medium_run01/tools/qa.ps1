param(
  [Parameter(Mandatory=$true)][string]$Action,
  [string]$Arg1 = "",
  [string]$Arg2 = ""
)
# Temporary QA helper: OS-level screenshot / SendInput mouse+keyboard against the TCA window.
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class W {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, int x, int y, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint f, UIntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  public struct RECT { public int L, T, R, B; }
  public struct POINT { public int X, Y; }
}
"@
[W]::SetProcessDPIAware() | Out-Null

function Get-Win {
  $p = Get-Process -Name TCA -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  if (-not $p) { throw "TCA window not found" }
  return $p
}
function Get-Client($h) {
  $r = New-Object W+RECT; [W]::GetClientRect($h, [ref]$r) | Out-Null
  $pt = New-Object W+POINT; [W]::ClientToScreen($h, [ref]$pt) | Out-Null
  return @{ X = $pt.X; Y = $pt.Y; W = $r.R; H = $r.B }
}
function Focus($h) { [W]::ShowWindow($h, 9) | Out-Null; [W]::SetForegroundWindow($h) | Out-Null; Start-Sleep -Milliseconds 150 }

$vk = @{ TAB=0x09; ENTER=0x0D; SPACE=0x20; ESC=0x1B; SHIFT=0x10; LEFT=0x25; UP=0x26; RIGHT=0x27; DOWN=0x28;
         R=0x52; C=0x43; E=0x45; F3=0x72 }

switch ($Action) {
  "info" {
    $p = Get-Win; $c = Get-Client $p.MainWindowHandle
    "pid=$($p.Id) title=$($p.MainWindowTitle) client=$($c.X),$($c.Y) $($c.W)x$($c.H) ws=$([math]::Round($p.WorkingSet64/1MB))MB priv=$([math]::Round($p.PrivateMemorySize64/1MB))MB fg=$([W]::GetForegroundWindow() -eq $p.MainWindowHandle)"
  }
  "shot" {
    $p = Get-Win; Focus $p.MainWindowHandle; $c = Get-Client $p.MainWindowHandle
    $bmp = New-Object System.Drawing.Bitmap $c.W, $c.H
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($c.X, $c.Y, 0, 0, $bmp.Size)
    $bmp.Save($Arg1, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
    "saved $Arg1 ($($c.W)x$($c.H))"
  }
  "click" {
    # Arg1,Arg2 = client-area pixel coordinates (physical pixels, same as screenshot)
    $p = Get-Win; Focus $p.MainWindowHandle; $c = Get-Client $p.MainWindowHandle
    [W]::SetCursorPos($c.X + [int]$Arg1, $c.Y + [int]$Arg2) | Out-Null; Start-Sleep -Milliseconds 80
    [W]::mouse_event(0x02, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 60
    [W]::mouse_event(0x04, 0, 0, 0, [UIntPtr]::Zero)
    "clicked $Arg1,$Arg2"
  }
  "move" {
    $p = Get-Win; Focus $p.MainWindowHandle; $c = Get-Client $p.MainWindowHandle
    [W]::SetCursorPos($c.X + [int]$Arg1, $c.Y + [int]$Arg2) | Out-Null; "moved"
  }
  "key" {
    # Arg1 = comma separated key names; prefix "S+" for shift. Arg2 = delay ms between keys (default 120)
    $p = Get-Win; Focus $p.MainWindowHandle
    $delay = if ($Arg2) { [int]$Arg2 } else { 120 }
    foreach ($k in $Arg1.Split(",")) {
      $shift = $k.StartsWith("S+"); $name = $k.Replace("S+", "")
      if ($shift) { [W]::keybd_event(0x10, 0, 0, [UIntPtr]::Zero) }
      [W]::keybd_event([byte]$vk[$name], 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 40
      [W]::keybd_event([byte]$vk[$name], 0, 2, [UIntPtr]::Zero)
      if ($shift) { [W]::keybd_event(0x10, 0, 2, [UIntPtr]::Zero) }
      Start-Sleep -Milliseconds $delay
    }
    "keys $Arg1"
  }
  default { throw "unknown action $Action" }
}
