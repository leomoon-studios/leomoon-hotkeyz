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
    (Join-Path $repositoryDirectory "tests\ModuleSmoke.au3")
)
$toolchainPath = (Resolve-Path -LiteralPath $ToolchainDirectory).Path
$checkerPath = Join-Path $toolchainPath "Au3Check.exe"
$autoItPath = Join-Path $toolchainPath "AutoIt3.exe"
$includePath = Join-Path $toolchainPath "Include"
$projectIncludePath = Join-Path $repositoryDirectory "src"

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

foreach ($testPath in $testPaths) {
    & $autoItPath /ErrorStdOut $testPath
    if ($LASTEXITCODE -ne 0) {
        throw "AutoIt test failed for $testPath with exit code $LASTEXITCODE"
    }
}

Write-Host "Au3Check and AutoIt tests completed successfully."
