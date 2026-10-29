[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ToolchainDirectory
)

$ErrorActionPreference = "Stop"
$repositoryDirectory = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repositoryDirectory "src\LeoMoon HotKeyz.au3"
$testPaths = @(
    (Join-Path $repositoryDirectory "tests\TestRunner.au3"),
    (Join-Path $repositoryDirectory "tests\ModuleSmoke.au3"),
    (Join-Path $repositoryDirectory "tests\AudioCycleTest.au3"),
    (Join-Path $repositoryDirectory "tests\HotkeyRestrictionsTest.au3"),
    (Join-Path $repositoryDirectory "tests\InputStateTest.au3"),
    (Join-Path $repositoryDirectory "tests\InputKeyTest.au3"),
    (Join-Path $repositoryDirectory "tests\InputHookLifecycleTest.au3")
)
$toolchainPath = (Resolve-Path -LiteralPath $ToolchainDirectory).Path
$checkerPath = Join-Path $toolchainPath "Au3Check.exe"
$autoItPath = Join-Path $toolchainPath "AutoIt3.exe"
$includePath = Join-Path $toolchainPath "Include"
$projectIncludePath = Join-Path $repositoryDirectory "src"
$startupRegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$startupRegistryName = "LeoMoon HotKeyz"

function Get-StartupRegistryValue {
    try {
        return Get-ItemPropertyValue -LiteralPath $startupRegistryPath -Name $startupRegistryName -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        return $null
    }
    catch [System.Management.Automation.PSArgumentException] {
        return $null
    }
}

if (-not (Test-Path -LiteralPath $checkerPath -PathType Leaf)) {
    throw "Au3Check.exe was not found at $checkerPath"
}
if (-not (Test-Path -LiteralPath $includePath -PathType Container)) {
    throw "The AutoIt include directory was not found at $includePath"
}
if (-not (Test-Path -LiteralPath $autoItPath -PathType Leaf)) {
    throw "AutoIt3.exe was not found at $autoItPath"
}

# ExtMsgBox.au3 explicitly disables warning 7 because it intentionally passes expressions to ByRef parameters.
$checkTargets = @($sourcePath) + $testPaths
foreach ($checkTarget in $checkTargets) {
    if (-not (Test-Path -LiteralPath $checkTarget -PathType Leaf)) {
        throw "The AutoIt source was not found at $checkTarget"
    }
    $arguments = @(
        "-q",
        "-d",
        "-w", "1",
        "-w", "2",
        "-w", "3",
        "-w", "4",
        "-w", "5",
        "-w", "6",
        "-w-", "7",
        "-I", $includePath,
        "-I", $projectIncludePath,
        $checkTarget
    )
    & $checkerPath @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Au3Check failed for $checkTarget with exit code $LASTEXITCODE"
    }
}

$startupValueBeforeTests = Get-StartupRegistryValue
$worktreeBeforeTests = @(& git -C $repositoryDirectory status --porcelain)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to capture the repository worktree before tests"
}
foreach ($testPath in $testPaths) {
    # AutoIt3.exe is a Windows GUI executable; PowerShell may otherwise return
    # before it finishes and report the exit status of the previous command.
    $testOutput = Join-Path ([System.IO.Path]::GetTempPath()) ("hotkeyz-test-" + [guid]::NewGuid().ToString("N") + ".out")
    $testError = $testOutput + ".err"
    try {
        $testProcess = Start-Process -FilePath $autoItPath -ArgumentList @('/ErrorStdOut', ('"' + $testPath + '"')) -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $testOutput -RedirectStandardError $testError
        Get-Content -LiteralPath $testOutput -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
        Get-Content -LiteralPath $testError -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
        if ($testProcess.ExitCode -ne 0) {
            throw "AutoIt test failed for $testPath with exit code $($testProcess.ExitCode)"
        }
    }
    finally {
        Remove-Item -LiteralPath $testOutput, $testError -Force -ErrorAction SilentlyContinue
    }
}

$startupValueAfterTests = Get-StartupRegistryValue
if ($startupValueBeforeTests -ne $startupValueAfterTests) {
    throw "Tests modified the persistent LeoMoon HotKeyz startup registry value"
}

$worktreeAfterTests = @(& git -C $repositoryDirectory status --porcelain)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to verify the repository worktree after tests"
}
if (($worktreeBeforeTests -join "`n") -ne ($worktreeAfterTests -join "`n")) {
    throw "Tests modified the repository worktree"
}

Write-Host "Au3Check and AutoIt tests completed successfully."
