[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ToolsDirectory,

    [string]$GitHubOutputPath = $env:GITHUB_OUTPUT
)

$ErrorActionPreference = "Stop"

$autoItUrl = "https://www.autoitscript.com/autoit3/files/archive/autoit/autoit-v3.3.18.0.zip"
$autoItSha256 = "ceb666a993a9f62621c3a0d4ee602774b2e7f543de1f08ec0380632ee3f89beb"
$sciTeUrl = "https://www.autoitscript.com/autoit3/scite/download/SciTE4AutoIt3_Portable.zip"
$sciTeSha256 = "9e41b60753b566af3333601a9720607fbf71a248c2e7225b5ee1fec0ca852722"
$innoSetupUrl = "https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe"
$innoSetupSha256 = "9c73c3bae7ed48d44112a0f48e66742c00090bdb5bef71d9d3c056c66e97b732"

function Get-VerifiedDownload {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256
    )

    Invoke-WebRequest -Uri $Uri -OutFile $Destination
    $actualSha256 = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSha256 -ne $ExpectedSha256) {
        throw "Checksum mismatch for $Uri. Expected $ExpectedSha256 but received $actualSha256"
    }
}

function Write-GitHubOutput {
    param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][string]$Value)

    if (-not [string]::IsNullOrWhiteSpace($GitHubOutputPath)) {
        "$Name=$Value" | Out-File -FilePath $GitHubOutputPath -Encoding utf8 -Append
    }
}

$tools = [System.IO.Path]::GetFullPath($ToolsDirectory)
$toolsRoot = [System.IO.Path]::GetPathRoot($tools)
if ($tools -eq $toolsRoot) {
    throw "Refusing to use a filesystem root as the tools directory: $tools"
}

New-Item -ItemType Directory -Path $tools -Force | Out-Null
$downloads = Join-Path $tools "downloads"
$autoItRoot = Join-Path $tools "autoit-v3.3.18.0"
$sciTeRoot = Join-Path $tools "scite4autoit3-v21.316.1639.0"
$innoRoot = Join-Path $tools "inno-setup-6.7.3"
New-Item -ItemType Directory -Path $downloads -Force | Out-Null

$autoItArchive = Join-Path $downloads "autoit-v3.3.18.0.zip"
$sciTeArchive = Join-Path $downloads "SciTE4AutoIt3-v21.316.1639.0-Portable.zip"
$innoInstaller = Join-Path $downloads "innosetup-6.7.3.exe"

Get-VerifiedDownload -Uri $autoItUrl -Destination $autoItArchive -ExpectedSha256 $autoItSha256
Get-VerifiedDownload -Uri $sciTeUrl -Destination $sciTeArchive -ExpectedSha256 $sciTeSha256
Get-VerifiedDownload -Uri $innoSetupUrl -Destination $innoInstaller -ExpectedSha256 $innoSetupSha256

foreach ($directory in @($autoItRoot, $sciTeRoot, $innoRoot)) {
    if (Test-Path -LiteralPath $directory) {
        Remove-Item -LiteralPath $directory -Recurse -Force
    }
}

Expand-Archive -LiteralPath $autoItArchive -DestinationPath $autoItRoot
Expand-Archive -LiteralPath $sciTeArchive -DestinationPath $sciTeRoot

$innoArguments = @(
    "/SP-",
    "/VERYSILENT",
    "/SUPPRESSMSGBOXES",
    "/NORESTART",
    "/PORTABLE=1",
    "/DIR=`"$innoRoot`""
)
$innoProcess = Start-Process -FilePath $innoInstaller -ArgumentList $innoArguments -Wait -PassThru
if ($innoProcess.ExitCode -ne 0) {
    throw "Inno Setup installation failed with exit code $($innoProcess.ExitCode)"
}

$autoItDirectory = Join-Path $autoItRoot "install"
$autoItExe = Join-Path $autoItDirectory "AutoIt3.exe"
$checkerPath = Join-Path $autoItDirectory "Au3Check.exe"
$wrapperPath = Join-Path $sciTeRoot "AutoIt3Wrapper\AutoIt3Wrapper.au3"
$iscc = Get-ChildItem -LiteralPath $innoRoot -Filter "ISCC.exe" -File -Recurse | Select-Object -First 1

foreach ($requiredPath in @($autoItExe, $checkerPath, $wrapperPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required build tool was not found: $requiredPath"
    }
}
if (-not $iscc) {
    throw "ISCC.exe was not found under $innoRoot"
}

Write-GitHubOutput -Name "autoit_directory" -Value $autoItDirectory
Write-GitHubOutput -Name "autoit3wrapper_path" -Value $wrapperPath
Write-GitHubOutput -Name "iscc_path" -Value $iscc.FullName

Write-Host "AutoIt directory: $autoItDirectory"
Write-Host "AutoIt3Wrapper: $wrapperPath"
Write-Host "Inno Setup compiler: $($iscc.FullName)"
