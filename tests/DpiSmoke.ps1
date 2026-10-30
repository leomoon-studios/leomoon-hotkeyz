param(
    [Parameter(Mandatory = $true)] [string]$Executable,
    [string]$AutoItPath = 'C:\Program Files (x86)\AutoIt3\AutoIt3.exe',
    [string]$CaptureDirectory = '',
    [switch]$GdiScaled,
    [switch]$FixtureOnly
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class HotKeyzDpi {
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct MONITORINFO { public uint Size; public RECT Monitor, Work; public uint Flags; }
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr value);
    [DllImport("user32.dll")] public static extern IntPtr MonitorFromPoint(POINT point, uint flags);
    [DllImport("user32.dll")] public static extern IntPtr MonitorFromWindow(IntPtr hwnd, uint flags);
    [DllImport("user32.dll")] public static extern bool GetMonitorInfo(IntPtr monitor, ref MONITORINFO info);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern IntPtr GetWindowDpiAwarenessContext(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool AreDpiAwarenessContextsEqual(IntPtr first, IntPtr second);
    [DllImport("shcore.dll")] public static extern int GetDpiForMonitor(IntPtr monitor, int type, out uint x, out uint y);
    [DllImport("shcore.dll")] public static extern int GetProcessDpiAwareness(IntPtr process, out int awareness);
}
'@
$repository = Split-Path -Parent $PSScriptRoot
$binary = (Resolve-Path -LiteralPath $Executable).Path
$fixture = Join-Path $PSScriptRoot 'EditorKeyboardSmoke.au3'
$testProfile = Join-Path $PSScriptRoot 'LeoMoon HotKeyz.ini'
if (-not $FixtureOnly) {
    try {
        $existing = [Threading.Mutex]::OpenExisting('LeoMoon HotKeyz')
        $existing.Dispose()
        throw 'Exit the running HotKeyz instance before running the DPI test.'
    } catch [Threading.WaitHandleCannotBeOpenedException] { }
}
foreach ($path in @($testProfile, "$testProfile.bak", "$testProfile.tmp")) {
    if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite test profile: $path" }
}
$testDirectory = Join-Path $repository ('build\dpi-probe-' + [guid]::NewGuid().ToString('N'))
$testBinary = Join-Path $testDirectory 'LeoMoon HotKeyz.exe'
$testIni = Join-Path $testDirectory 'LeoMoon HotKeyz.ini'
$output = Join-Path ([IO.Path]::GetTempPath()) ('hotkeyz-dpi-' + [guid]::NewGuid().ToString('N'))
$visualOutput = $output + '.visual'
$stages = @('settings', 'settings-populated', 'editor-program', 'editor-folder', 'editor-system', 'editor-window', 'editor-url', 'editor-text', 'editor-command', 'editor-geometry', 'editor-conditions-summary', 'editor-optical', 'conditions', 'warning')
$app = $null
$editor = $null
$visual = $null
$oldContext = [IntPtr]::Zero
try {
    New-Item -ItemType Directory -Path $testDirectory -ErrorAction Stop | Out-Null
    if (-not $FixtureOnly) {
        Copy-Item -LiteralPath $binary -Destination $testBinary
        [IO.File]::WriteAllText($testIni, "[Options]`r`nMain=^!+{F11}`r`n[Hotkeys]`r`n", [Text.Encoding]::ASCII)
    }
    # Per-monitor awareness is applied only to this PowerShell thread for the
    # display query. It does not change the user's display settings.
    $oldContext = [HotKeyzDpi]::SetThreadDpiAwarenessContext([IntPtr](-4))
    if ($oldContext -eq [IntPtr]::Zero) { throw 'Could not set the DPI context for the display query.' }
    foreach ($screen in [Windows.Forms.Screen]::AllScreens) {
        $point = New-Object HotKeyzDpi+POINT
        $point.X = $screen.Bounds.X + [int]($screen.Bounds.Width / 2)
        $point.Y = $screen.Bounds.Y + [int]($screen.Bounds.Height / 2)
        $monitor = [HotKeyzDpi]::MonitorFromPoint($point, 2)
        [uint32]$dpiX = 0; [uint32]$dpiY = 0
        $hr = [HotKeyzDpi]::GetDpiForMonitor($monitor, 0, [ref]$dpiX, [ref]$dpiY)
        if ($hr -ne 0) { throw "Could not read monitor DPI: $hr" }
        Write-Output ("Display {0}: {1} x {2} DPI ({3}%), bounds {4}, work area {5}" -f $screen.DeviceName, $dpiX, $dpiY, [math]::Round($dpiX * 100 / 96), $screen.Bounds, $screen.WorkingArea)
    }
    [void][HotKeyzDpi]::SetThreadDpiAwarenessContext($oldContext)
    $oldContext = [IntPtr]::Zero
    [int]$appAwareness = -1
    if (-not $FixtureOnly) {
        $app = Start-Process -FilePath $testBinary -WorkingDirectory $testDirectory -WindowStyle Hidden -PassThru
        $null = $app.Handle
        Start-Sleep -Milliseconds 1500
        if ($app.HasExited) { throw "The isolated app exited early ($($app.ExitCode)); another instance may already be running." }
        $hr = [HotKeyzDpi]::GetProcessDpiAwareness($app.Handle, [ref]$appAwareness)
        if ($hr -ne 0) { throw "Could not read compiled app DPI awareness: $hr" }
        Write-Output "Compiled app DPI awareness: $appAwareness (0=unaware, 1=system, 2=per-monitor)"
    } else {
        Write-Output 'Fixture-only mode: the existing HotKeyz instance is not changed.'
    }
    $fixtureMode = 'inspect'
    if ($GdiScaled) { $fixtureMode = 'inspect-gdi' }
    $editor = Start-Process -FilePath $AutoItPath -ArgumentList @('/ErrorStdOut', ('"' + $fixture + '"'), $fixtureMode) -WindowStyle Hidden -PassThru -RedirectStandardOutput $output
    $null = $editor.Handle
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        Start-Sleep -Milliseconds 100
        $editor.Refresh()
        if ($editor.MainWindowHandle -ne [IntPtr]::Zero -or $editor.HasExited) { break }
    }
    if ($editor.HasExited -or $editor.MainWindowHandle -eq [IntPtr]::Zero) { throw 'The GUI fixture did not open.' }
    [int]$fixtureAwareness = -1
    $hr = [HotKeyzDpi]::GetProcessDpiAwareness($editor.Handle, [ref]$fixtureAwareness)
    if ($hr -ne 0) { throw "Could not read fixture DPI awareness: $hr" }
    Write-Output ("GUI fixture DPI awareness: {0}; Settings window DPI: {1}" -f $fixtureAwareness, [HotKeyzDpi]::GetDpiForWindow($editor.MainWindowHandle))
    if (-not $FixtureOnly -and $appAwareness -ne $fixtureAwareness) { throw 'The compiled app and GUI fixture use different DPI awareness; their rendering cannot be compared directly.' }
    $windows = @()
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        Start-Sleep -Milliseconds 50
        $windows = @(Get-Content -LiteralPath $output | Where-Object { $_ -like 'WINDOW|*' })
        if ($windows.Count -eq 3 -or $editor.HasExited) { break }
    }
    if ($windows.Count -ne 3) { throw "Expected three fixture windows; got $($windows.Count)." }
    $oldContext = [HotKeyzDpi]::SetThreadDpiAwarenessContext([IntPtr](-4))
    if ($oldContext -eq [IntPtr]::Zero) { throw 'Could not set the DPI context for window inspection.' }
    foreach ($line in $windows) {
        $parts = $line -split '\|', 3
        $hwnd = [IntPtr][Convert]::ToInt64($parts[2].Replace('0x', ''), 16)
        $rect = New-Object HotKeyzDpi+RECT
        if (-not [HotKeyzDpi]::GetWindowRect($hwnd, [ref]$rect)) { throw "Cannot measure $($parts[1])." }
        if ($GdiScaled -and -not [HotKeyzDpi]::AreDpiAwarenessContextsEqual([HotKeyzDpi]::GetWindowDpiAwarenessContext($hwnd), [IntPtr](-5))) { throw "$($parts[1]) did not use the GDI-scaled DPI context." }
        $info = New-Object HotKeyzDpi+MONITORINFO
        $info.Size = [Runtime.InteropServices.Marshal]::SizeOf($info)
        if (-not [HotKeyzDpi]::GetMonitorInfo([HotKeyzDpi]::MonitorFromWindow($hwnd, 2), [ref]$info)) { throw "Cannot read monitor work area for $($parts[1])." }
        if ($rect.Left -lt $info.Work.Left -or $rect.Top -lt $info.Work.Top -or $rect.Right -gt $info.Work.Right -or $rect.Bottom -gt $info.Work.Bottom) { throw "$($parts[1]) extends outside the monitor work area." }
        $width = $rect.Right - $rect.Left; $height = $rect.Bottom - $rect.Top
        Write-Output ("{0}: physical bounds ({1},{2}) {3}x{4}; window DPI {5}" -f $parts[1], $rect.Left, $rect.Top, $width, $height, [HotKeyzDpi]::GetDpiForWindow($hwnd))
    }
    [void][HotKeyzDpi]::SetThreadDpiAwarenessContext($oldContext)
    $oldContext = [IntPtr]::Zero
    $editor.WaitForExit()
    if ($editor.ExitCode -ne 0) { throw "The GUI fixture failed: $($editor.ExitCode)" }
    if (-not $CaptureDirectory) { $CaptureDirectory = Join-Path $repository ('build\dpi-capture-' + [guid]::NewGuid().ToString('N').Substring(0, 8)) }
    New-Item -ItemType Directory -Path $CaptureDirectory -Force | Out-Null
    foreach ($stage in $stages) {
        $capture = Join-Path $CaptureDirectory ($stage + '.png')
        if (Test-Path -LiteralPath $capture) { throw "Refusing to overwrite capture: $capture" }
    }
    $visualFixture = Join-Path $PSScriptRoot 'DpiVisualFixture.au3'
    $visualArgs = @('/ErrorStdOut', ('"' + $visualFixture + '"'), ('"' + $testDirectory + '"'))
    if ($GdiScaled) { $visualArgs += 'gdi' }
    $visual = Start-Process -FilePath $AutoItPath -ArgumentList $visualArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput $visualOutput
    $null = $visual.Handle
    $oldContext = [HotKeyzDpi]::SetThreadDpiAwarenessContext([IntPtr](-4))
    if ($oldContext -eq [IntPtr]::Zero) { throw 'Could not set the DPI context for screen capture.' }
    foreach ($stage in $stages) {
        $ready = Join-Path $testDirectory ($stage + '.ready')
        $done = Join-Path $testDirectory ($stage + '.done')
        for ($attempt = 0; $attempt -lt 200; $attempt++) {
            if ((Test-Path -LiteralPath $ready) -or $visual.HasExited) { break }
            Start-Sleep -Milliseconds 50
        }
        if (-not (Test-Path -LiteralPath $ready)) { throw "Visual fixture did not open $stage." }
        $hwnd = [IntPtr][Convert]::ToInt64((Get-Content -LiteralPath $ready -Raw).Trim().Replace('0x', ''), 16)
        $rect = New-Object HotKeyzDpi+RECT
        if (-not [HotKeyzDpi]::GetWindowRect($hwnd, [ref]$rect)) { throw "Cannot measure $stage." }
        if ($GdiScaled -and -not [HotKeyzDpi]::AreDpiAwarenessContextsEqual([HotKeyzDpi]::GetWindowDpiAwarenessContext($hwnd), [IntPtr](-5))) { throw "$stage did not use the GDI-scaled DPI context." }
        $info = New-Object HotKeyzDpi+MONITORINFO
        $info.Size = [Runtime.InteropServices.Marshal]::SizeOf($info)
        if (-not [HotKeyzDpi]::GetMonitorInfo([HotKeyzDpi]::MonitorFromWindow($hwnd, 2), [ref]$info)) { throw "Cannot find the monitor for $stage." }
        if ($rect.Left -lt $info.Work.Left -or $rect.Top -lt $info.Work.Top -or $rect.Right -gt $info.Work.Right -or $rect.Bottom -gt $info.Work.Bottom) { throw "$stage extends outside the monitor work area." }
        Start-Sleep -Milliseconds 150
        $bitmap = New-Object Drawing.Bitmap(($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top))
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
            $bitmap.Save((Join-Path $CaptureDirectory ($stage + '.png')), [Drawing.Imaging.ImageFormat]::Png)
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
        [IO.File]::WriteAllText($done, 'captured')
    }
    [void][HotKeyzDpi]::SetThreadDpiAwarenessContext($oldContext)
    $oldContext = [IntPtr]::Zero
    $visual.WaitForExit()
    if ($visual.ExitCode -ne 0) { throw "Visual fixture failed: $($visual.ExitCode)" }
    Write-Output "Actual screen captures: $CaptureDirectory"
    if ($GdiScaled) { Write-Output 'PASSED: GUI windows use the GDI-scaled DPI context; display settings were not changed.' }
    elseif ($FixtureOnly) { Write-Output 'PASSED: GUI windows fit the current work area; display settings were not changed.' }
    else { Write-Output 'PASSED: app and GUI fixture DPI awareness match; display settings were not changed.' }
} finally {
    if ($oldContext -ne [IntPtr]::Zero) { [void][HotKeyzDpi]::SetThreadDpiAwarenessContext($oldContext) }
    if ($null -ne $editor -and -not $editor.HasExited) { $editor.WaitForExit() }
    if ($null -ne $visual -and -not $visual.HasExited) { $visual.WaitForExit() }
    if ($null -ne $app -and -not $app.HasExited) { Stop-Process -Id $app.Id; $app.WaitForExit() }
    if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output -Force }
    foreach ($path in @($testIni, "$testIni.bak", "$testIni.tmp", $testBinary)) {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    foreach ($stage in $stages) {
        foreach ($suffix in @('.ready', '.done')) {
            $signal = Join-Path $testDirectory ($stage + $suffix)
            if (Test-Path -LiteralPath $signal) { Remove-Item -LiteralPath $signal -Force }
        }
    }
    if (Test-Path -LiteralPath $visualOutput) { Remove-Item -LiteralPath $visualOutput -Force }
    if (Test-Path -LiteralPath $testDirectory) { Remove-Item -LiteralPath $testDirectory }
}
