[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$AutoItDirectory,

    [Parameter(Mandatory = $true)]
    [string]$AutoIt3WrapperPath,

    [string]$BuildDirectory = ""
)

$ErrorActionPreference = "Stop"
$repositoryDirectory = Split-Path -Parent $PSScriptRoot
if (-not $BuildDirectory) {
    $BuildDirectory = Join-Path $repositoryDirectory "build\windows"
}

$buildRoot = [System.IO.Path]::GetFullPath($BuildDirectory)
$repositoryRoot = [System.IO.Path]::GetFullPath($repositoryDirectory)
$allowedBuildRoot = [System.IO.Path]::GetFullPath((Join-Path $repositoryDirectory "build")) + [System.IO.Path]::DirectorySeparatorChar
if ($buildRoot -eq [System.IO.Path]::GetPathRoot($buildRoot) -or $buildRoot -eq $repositoryRoot -or -not ($buildRoot + [System.IO.Path]::DirectorySeparatorChar).StartsWith($allowedBuildRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to replace unsafe build directory: $buildRoot"
}

$autoItRoot = (Resolve-Path -LiteralPath $AutoItDirectory).Path
$autoItExe = Join-Path $autoItRoot "AutoIt3.exe"
$wrapper = (Resolve-Path -LiteralPath $AutoIt3WrapperPath).Path
if (-not (Test-Path -LiteralPath $autoItExe -PathType Leaf)) {
    throw "AutoIt3.exe was not found at $autoItExe"
}

$sourceDirectory = Join-Path $repositoryDirectory "src"
$stageDirectory = Join-Path $buildRoot "stage"
$stageSource = Join-Path $stageDirectory "src"
$outputDirectory = Join-Path $buildRoot "output"
$applicationPath = Join-Path $outputDirectory "LeoMoon HotKeyz.exe"

if (Test-Path -LiteralPath $buildRoot) {
    Remove-Item -LiteralPath $buildRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $stageSource -Force | Out-Null
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
Copy-Item -Path (Join-Path $sourceDirectory "*") -Destination $stageSource -Recurse -Force

$runtimeVersion = $Version
$fileVersion = "$Version.0"
$constantsPath = Join-Path $stageSource "core\AppConstants.au3"
$constants = Get-Content -LiteralPath $constantsPath -Raw
$constants = $constants -replace '(?m)^Global Const \$APP_VERSION = "[^"]+"\r?$', "Global Const `$APP_VERSION = `"$runtimeVersion`""
$constants = $constants -replace '(?m)^Global Const \$APP_FILE_VERSION = "[^"]+"\r?$', "Global Const `$APP_FILE_VERSION = `"$fileVersion`""
if ($constants -notmatch [regex]::Escape("Global Const `$APP_VERSION = `"$runtimeVersion`"") -or $constants -notmatch [regex]::Escape("Global Const `$APP_FILE_VERSION = `"$fileVersion`"")) {
    throw "Unable to inject runtime version metadata into AppConstants.au3"
}
Set-Content -LiteralPath $constantsPath -Value $constants -Encoding utf8NoBOM

$mainSource = Join-Path $stageSource "LeoMoon HotKeyz.au3"
$main = Get-Content -LiteralPath $mainSource -Raw
$main = $main -replace '(?m)^#pragma compile\(Out,.*\r?$', '; Output is supplied by scripts/build-windows.ps1.'
$main = $main -replace '(?m)^#pragma compile\(FileVersion,.*\r?$', "#pragma compile(FileVersion, $fileVersion)"
$main = $main -replace '(?m)^#pragma compile\(ProductVersion,.*\r?$', "#pragma compile(ProductVersion, $fileVersion)"
if ($main -match '(?m)^#pragma compile\(Out,' -or $main -notmatch [regex]::Escape("#pragma compile(FileVersion, $fileVersion)") -or $main -notmatch [regex]::Escape("#pragma compile(ProductVersion, $fileVersion)")) {
    throw "Unable to inject Windows version metadata into LeoMoon HotKeyz.au3"
}
foreach ($iconName in @("main.ico", "disabled.ico")) {
    $iconPath = Join-Path $stageSource "resources\$iconName"
    if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf) -or $main -notmatch [regex]::Escape("resources\$iconName")) {
        throw "Required embedded icon is missing from the staged source: $iconName"
    }
}
Set-Content -LiteralPath $mainSource -Value $main -Encoding utf8NoBOM

$wrapperArguments = @(
    "/ErrorStdOut",
    $wrapper,
    "/in", $mainSource,
    "/out", $applicationPath,
    "/icon", (Join-Path $stageSource "resources\main.ico"),
    "/x86",
    "/prod",
    "/NoStatus",
    "/NoPack",
    "/comp", "4",
    "/AutoIt3Dir", $autoItRoot
)
$wrapperStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
$wrapperStartInfo.FileName = $autoItExe
$wrapperStartInfo.WorkingDirectory = $stageSource
$wrapperStartInfo.UseShellExecute = $false
foreach ($argument in $wrapperArguments) {
    [void]$wrapperStartInfo.ArgumentList.Add($argument)
}
$wrapperProcess = [System.Diagnostics.Process]::new()
$wrapperProcess.StartInfo = $wrapperStartInfo
if (-not $wrapperProcess.Start()) {
    throw "Unable to start AutoIt3Wrapper"
}
$wrapperProcess.WaitForExit()
if ($wrapperProcess.ExitCode -ne 0) {
    throw "AutoIt3Wrapper failed with exit code $($wrapperProcess.ExitCode)"
}
if (-not (Test-Path -LiteralPath $applicationPath -PathType Leaf)) {
    throw "AutoIt3Wrapper did not create $applicationPath"
}

$versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($applicationPath)
if ($versionInfo.FileVersion -ne $fileVersion -or $versionInfo.ProductVersion -ne $fileVersion) {
    throw "Compiled version metadata does not match $fileVersion. FileVersion=$($versionInfo.FileVersion), ProductVersion=$($versionInfo.ProductVersion)"
}

$bytes = [System.IO.File]::ReadAllBytes($applicationPath)
if ($bytes.Length -lt 64 -or [System.Text.Encoding]::ASCII.GetString($bytes, 0, 2) -ne "MZ") {
    throw "Compiled output is not a PE executable"
}
$peOffset = [System.BitConverter]::ToInt32($bytes, 0x3c)
$machine = [System.BitConverter]::ToUInt16($bytes, $peOffset + 4)
if ($machine -ne 0x014c) {
    throw "Compiled output is not an x86 executable"
}

Write-Host "Built $applicationPath with runtime version $runtimeVersion and file version $fileVersion"
