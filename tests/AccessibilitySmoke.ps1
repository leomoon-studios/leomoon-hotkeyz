param([string]$AutoItPath = "C:\Program Files (x86)\AutoIt3\AutoIt3.exe")
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName Accessibility
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class HotKeyzMsaa {
    [DllImport("oleacc.dll")]
    public static extern int AccessibleObjectFromWindow(IntPtr hwnd, uint objectId, ref Guid iid, out IntPtr result);
}
'@
$output = Join-Path ([IO.Path]::GetTempPath()) ('hotkeyz-access-' + [guid]::NewGuid().ToString('N'))
$fixture = Join-Path $PSScriptRoot 'EditorKeyboardSmoke.au3'
$process = $null
try {
    $process = Start-Process -FilePath $AutoItPath -ArgumentList @('/ErrorStdOut', ('"' + $fixture + '"'), 'inspect') -WindowStyle Hidden -PassThru -RedirectStandardOutput $output
    $null = $process.Handle
    $lines = @()
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        Start-Sleep -Milliseconds 100
        if (Test-Path -LiteralPath $output) { $lines = @(Get-Content -LiteralPath $output | Where-Object { $_ -like 'ACCESS|*' }) }
        if ($lines.Count -eq 24 -or $process.HasExited) { break }
    }
    if ($lines.Count -ne 24) { throw "Expected 24 control handles; got $($lines.Count)." }
    $iid = [Guid]'618736e0-3c3d-11cf-810c-00aa00389b71'
    foreach ($line in $lines) {
        $parts = $line -split '\|', 3
        $handle = [IntPtr][Convert]::ToInt64($parts[2].Replace('0x', ''), 16)
        $ptr = [IntPtr]::Zero
        $hr = [HotKeyzMsaa]::AccessibleObjectFromWindow($handle, [uint32]4294967292, [ref]$iid, [ref]$ptr)
        if ($hr -ne 0) { throw "Could not inspect $($parts[1]): HRESULT $hr." }
        try {
            $accessible = [Runtime.InteropServices.Marshal]::GetTypedObjectForIUnknown($ptr, [Accessibility.IAccessible])
            $actual = $accessible.accName(0)
            if ($actual -ne $parts[1]) { throw "Expected '$($parts[1])', got '$actual'." }
        } finally { [void][Runtime.InteropServices.Marshal]::Release($ptr) }
    }
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "Fixture exited with code $($process.ExitCode)." }
    Write-Output "PASSED: $($lines.Count) editor, Settings and conditions control names through MSAA"
} finally {
    if ($null -ne $process -and -not $process.HasExited) { $process.WaitForExit() }
    if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output -Force }
}
