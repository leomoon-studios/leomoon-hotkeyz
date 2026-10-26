[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ArtifactDirectory,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [switch]$RunInstallerSmokeTest
)

$ErrorActionPreference = "Stop"
$artifacts = (Resolve-Path -LiteralPath $ArtifactDirectory).Path
$portableName = "leomoon-hotkeyz-$Version-windows-x86-portable.zip"
$installerName = "leomoon-hotkeyz-$Version-windows-x86-setup.exe"
$expectedNames = @($portableName, $installerName, "release-manifest.json", "SHA256SUMS") | Sort-Object
$actualNames = @(Get-ChildItem -LiteralPath $artifacts -File | Select-Object -ExpandProperty Name | Sort-Object)
if (($expectedNames -join "`n") -ne ($actualNames -join "`n")) {
    throw "Artifact directory must contain only: $($expectedNames -join ', '). Found: $($actualNames -join ', ')"
}

$portablePath = Join-Path $artifacts $portableName
$installerPath = Join-Path $artifacts $installerName
$manifestPath = Join-Path $artifacts "release-manifest.json"
$checksumsPath = Join-Path $artifacts "SHA256SUMS"
$checksumLines = @(Get-Content -LiteralPath $checksumsPath)
if ($checksumLines.Count -ne 3) {
    throw "SHA256SUMS must contain exactly three entries"
}
$checksumNames = @()
foreach ($line in $checksumLines) {
    if ($line -notmatch '^([0-9a-f]{64}) \*(.+)$') {
        throw "Invalid SHA256SUMS entry: $line"
    }
    $checksumNames += $Matches[2]
    $checksumTarget = Join-Path $artifacts $Matches[2]
    if (-not (Test-Path -LiteralPath $checksumTarget -PathType Leaf)) {
        throw "Checksum target is missing: $($Matches[2])"
    }
    $actualHash = (Get-FileHash -LiteralPath $checksumTarget -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $Matches[1]) {
        throw "Checksum mismatch for $($Matches[2])"
    }
}
$expectedChecksumNames = @($portableName, $installerName, "release-manifest.json") | Sort-Object
if (($expectedChecksumNames -join "`n") -ne (($checksumNames | Sort-Object) -join "`n")) {
    throw "SHA256SUMS does not describe exactly the portable ZIP, installer, and manifest"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.application -ne "LeoMoon HotKeyz" -or $manifest.version -ne $Version -or $manifest.fileVersion -ne "$Version.0") {
    throw "Release manifest metadata does not match version $Version"
}
if ($manifest.platform -ne "windows" -or $manifest.architecture -ne "x86" -or $manifest.signed -ne $false) {
    throw "Release manifest platform metadata is invalid"
}
$manifestArtifactNames = (@($manifest.artifacts) | Sort-Object) -join "`n"
$expectedManifestArtifactNames = (@($portableName, $installerName) | Sort-Object) -join "`n"
if ($manifestArtifactNames -ne $expectedManifestArtifactNames) {
    throw "Release manifest artifact list is invalid"
}

function Assert-X86Application {
    param([Parameter(Mandatory = $true)][string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 64 -or [System.Text.Encoding]::ASCII.GetString($bytes, 0, 2) -ne "MZ") {
        throw "$Path is not a PE executable"
    }
    $peOffset = [System.BitConverter]::ToInt32($bytes, 0x3c)
    $machine = [System.BitConverter]::ToUInt16($bytes, $peOffset + 4)
    if ($machine -ne 0x014c) {
        throw "$Path is not an x86 executable"
    }
    $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Path)
    if ($versionInfo.FileVersion -ne "$Version.0" -or $versionInfo.ProductVersion -ne "$Version.0") {
        throw "$Path does not contain version $Version.0"
    }
}

function Invoke-CheckedProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [int]$TimeoutSeconds = 600
    )

    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -PassThru
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        throw "$FilePath did not finish within $TimeoutSeconds seconds"
    }
    if ($process.ExitCode -ne 0) {
        throw "$FilePath failed with exit code $($process.ExitCode)"
    }
}

$installerVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($installerPath)
$expectedInstallerVersion = [System.Version]::Parse("$Version.0")
$installerFileVersion = [System.Version]::new($installerVersion.FileMajorPart, $installerVersion.FileMinorPart, $installerVersion.FileBuildPart, $installerVersion.FilePrivatePart)
$installerProductVersion = [System.Version]::new($installerVersion.ProductMajorPart, $installerVersion.ProductMinorPart, $installerVersion.ProductBuildPart, $installerVersion.ProductPrivatePart)
if ($installerFileVersion -ne $expectedInstallerVersion -or $installerProductVersion -ne $expectedInstallerVersion) {
    throw "Installer version mismatch. Expected $expectedInstallerVersion, file version $installerFileVersion, product version $installerProductVersion"
}

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "leomoon-hotkeyz-package-$([System.Guid]::NewGuid().ToString('N'))"
$portableExtract = Join-Path $temporaryRoot "portable"
$installDirectory = Join-Path $temporaryRoot "installed"
$uninstaller = Join-Path $installDirectory "unins000.exe"
$uninstallCompleted = $false
try {
    New-Item -ItemType Directory -Path $portableExtract -Force | Out-Null
    Expand-Archive -LiteralPath $portablePath -DestinationPath $portableExtract
    $portableFiles = @(Get-ChildItem -LiteralPath $portableExtract -File -Recurse)
    if ($portableFiles.Count -ne 1 -or $portableFiles[0].Name -ne "LeoMoon HotKeyz.exe") {
        throw "Portable ZIP must contain only LeoMoon HotKeyz.exe"
    }
    Assert-X86Application -Path $portableFiles[0].FullName

    if ($RunInstallerSmokeTest) {
        if (Get-Process -Name "LeoMoon HotKeyz" -ErrorAction SilentlyContinue) {
            throw "LeoMoon HotKeyz is already running, so installer isolation cannot be verified"
        }
        $installLog = Join-Path $temporaryRoot "install.log"
        $uninstallLog = Join-Path $temporaryRoot "uninstall.log"
        $installArguments = @(
            "/SP-",
            "/VERYSILENT",
            "/SUPPRESSMSGBOXES",
            "/NORESTART",
            "/TASKS=`"`"",
            "/LOG=`"$installLog`"",
            "/DIR=`"$installDirectory`""
        )
        Invoke-CheckedProcess -FilePath $installerPath -Arguments $installArguments
        $installedApplication = Join-Path $installDirectory "LeoMoon HotKeyz.exe"
        if (-not (Test-Path -LiteralPath $installedApplication -PathType Leaf)) {
            throw "Silent installation did not install LeoMoon HotKeyz.exe"
        }
        if (Get-Process -Name "LeoMoon HotKeyz" -ErrorAction SilentlyContinue) {
            throw "Silent installation unexpectedly launched LeoMoon HotKeyz"
        }
        Assert-X86Application -Path $installedApplication
        if (-not (Test-Path -LiteralPath $uninstaller -PathType Leaf)) {
            throw "Silent installation did not create an uninstaller"
        }
        Invoke-CheckedProcess -FilePath $uninstaller -Arguments @(
            "/VERYSILENT",
            "/SUPPRESSMSGBOXES",
            "/NORESTART",
            "/LOG=`"$uninstallLog`""
        )
        $uninstallCompleted = $true
        $deadline = [DateTime]::UtcNow.AddSeconds(60)
        while (Test-Path -LiteralPath $installDirectory) {
            if ([DateTime]::UtcNow -ge $deadline) {
                throw "Installation directory remains after uninstall"
            }
            Start-Sleep -Milliseconds 200
        }
    }
} finally {
    if ($RunInstallerSmokeTest -and -not $uninstallCompleted -and (Test-Path -LiteralPath $uninstaller -PathType Leaf)) {
        try {
            Invoke-CheckedProcess -FilePath $uninstaller -Arguments @("/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART")
        } catch {
            Write-Warning "Cleanup uninstall failed: $($_.Exception.Message)"
        }
    }
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Verified Windows portable and installer artifacts for version $Version"
