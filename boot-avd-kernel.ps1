[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ArtifactDir,

    [string]$AvdName = "Pixel_9_KSUN_SUSFS",

    [string]$EmulatorPath
)

$ErrorActionPreference = "Stop"

$artifact = (Resolve-Path -LiteralPath $ArtifactDir).Path
$kernel = Get-ChildItem -LiteralPath $artifact -File -ErrorAction Stop |
    Where-Object { $_.Name -in @("bzImage", "Image") } |
    Select-Object -First 1

if ($null -eq $kernel) {
    throw "No bzImage or Image was found in $artifact"
}

if ([string]::IsNullOrWhiteSpace($EmulatorPath)) {
    $sdk = $env:ANDROID_SDK_ROOT
    if ([string]::IsNullOrWhiteSpace($sdk)) {
        $sdk = $env:ANDROID_HOME
    }
    if ([string]::IsNullOrWhiteSpace($sdk)) {
        $sdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
    }
    $EmulatorPath = Join-Path $sdk "emulator\emulator.exe"
}

if (-not (Test-Path -LiteralPath $EmulatorPath -PathType Leaf)) {
    throw "Android emulator executable was not found at $EmulatorPath"
}

$avds = & $EmulatorPath -list-avds
if ($LASTEXITCODE -ne 0) {
    throw "Could not query the Android emulator AVD list"
}
if ($avds -notcontains $AvdName) {
    throw "AVD '$AvdName' was not found. Available AVDs: $($avds -join ', ')"
}

Write-Host "Booting $AvdName with kernel override: $($kernel.FullName)"
Write-Host "The stock system image, kernel, and ramdisk will not be modified."

& $EmulatorPath `
    -avd $AvdName `
    -kernel $kernel.FullName `
    -no-snapshot-load `
    -show-kernel

exit $LASTEXITCODE

