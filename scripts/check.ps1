[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ToolchainDirectory
)

$ErrorActionPreference = "Stop"
$repositoryDirectory = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repositoryDirectory "src\LeoMoon HotKeyz.au3"
$toolchainPath = (Resolve-Path -LiteralPath $ToolchainDirectory).Path
$checkerPath = Join-Path $toolchainPath "Au3Check.exe"
$includePath = Join-Path $toolchainPath "Include"
$projectIncludePath = Join-Path $repositoryDirectory "src"

if (-not (Test-Path -LiteralPath $checkerPath -PathType Leaf)) {
    throw "Au3Check.exe was not found at $checkerPath"
}
if (-not (Test-Path -LiteralPath $includePath -PathType Container)) {
    throw "The AutoIt include directory was not found at $includePath"
}
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "The application source was not found at $sourcePath"
}

# ExtMsgBox.au3 explicitly disables warning 7 because it intentionally passes expressions to ByRef parameters.
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
    $sourcePath
)

& $checkerPath @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Au3Check failed with exit code $LASTEXITCODE"
}

Write-Host "Au3Check completed successfully."
