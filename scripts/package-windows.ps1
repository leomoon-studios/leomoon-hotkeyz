[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$StageDirectory,

    [Parameter(Mandatory = $true)]
    [string]$DistDirectory,

    [Parameter(Mandatory = $true)]
    [string]$IsccPath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}T')]
    [string]$ReleaseDate,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-fA-F]{7,64}$')]
    [string]$Commit
)

$ErrorActionPreference = "Stop"
$repositoryDirectory = Split-Path -Parent $PSScriptRoot
$stage = (Resolve-Path -LiteralPath $StageDirectory).Path
$iscc = (Resolve-Path -LiteralPath $IsccPath).Path
$application = Join-Path $stage "LeoMoon HotKeyz.exe"
if (-not (Test-Path -LiteralPath $application -PathType Leaf)) {
    throw "StageDirectory must contain LeoMoon HotKeyz.exe"
}

$dist = [System.IO.Path]::GetFullPath($DistDirectory)
$repositoryRoot = [System.IO.Path]::GetFullPath($repositoryDirectory)
if ($dist -eq [System.IO.Path]::GetPathRoot($dist) -or $dist -eq $repositoryRoot) {
    throw "Refusing to replace unsafe artifact directory: $dist"
}
if (Test-Path -LiteralPath $dist) {
    Remove-Item -LiteralPath $dist -Recurse -Force
}
New-Item -ItemType Directory -Path $dist | Out-Null

$packageRoot = Join-Path $repositoryDirectory "build\package\windows"
$portableStage = Join-Path $packageRoot "portable"
if (Test-Path -LiteralPath $packageRoot) {
    Remove-Item -LiteralPath $packageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $portableStage -Force | Out-Null
Copy-Item -LiteralPath $application -Destination $portableStage

$portableName = "leomoon-hotkeyz-$Version-windows-x86-portable.zip"
$installerName = "leomoon-hotkeyz-$Version-windows-x86-setup.exe"
$portablePath = Join-Path $dist $portableName
$installerPath = Join-Path $dist $installerName
$manifestPath = Join-Path $dist "release-manifest.json"
$checksumsPath = Join-Path $dist "SHA256SUMS"

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($portableStage, $portablePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

$installerScript = Join-Path $repositoryDirectory "packaging\windows\hotkeyz.iss"
$fileVersion = "$Version.0"
& $iscc "/Qp" "/DAppVersion=$Version" "/DAppFileVersion=$fileVersion" "/DStageDir=$stage" "/DOutputDir=$dist" $installerScript
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup failed with exit code $LASTEXITCODE"
}
if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    throw "Inno Setup did not create $installerPath"
}

$manifest = [ordered]@{
    application = "LeoMoon HotKeyz"
    version = $Version
    fileVersion = $fileVersion
    releaseDate = $ReleaseDate
    commit = $Commit.ToLowerInvariant()
    platform = "windows"
    architecture = "x86"
    signed = $false
    artifacts = @($portableName, $installerName)
}
$manifest | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $manifestPath -Encoding utf8NoBOM

@($portablePath, $installerPath, $manifestPath) | Sort-Object { Split-Path -Leaf $_ } | ForEach-Object {
    "{0} *{1}" -f (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLowerInvariant(), (Split-Path -Leaf $_)
} | Set-Content -LiteralPath $checksumsPath -Encoding ascii

& (Join-Path $PSScriptRoot "verify-windows-package.ps1") -ArtifactDirectory $dist -Version $Version -RunInstallerSmokeTest
if ($LASTEXITCODE -ne 0) {
    throw "Windows package verification failed with exit code $LASTEXITCODE"
}

Write-Host "Windows release artifacts are ready in $dist"
