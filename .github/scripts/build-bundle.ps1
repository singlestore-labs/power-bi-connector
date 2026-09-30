# Builds the Burn bundle .exe from the two MSIs in the working directory.
#
# Bundle.wxs references singlestore-connector-odbc.msi and power_bi_connector_installer.msi by
# bare filename, so run this from the repo root with both files present. Used by the `build` job
# (unsigned bundle, for PR/master validation) and by the `sign` job (bundle from signed MSIs).
param(
    [Parameter(Mandatory = $true)] [string]$ConnectorVersion,
    [Parameter(Mandatory = $true)] [string]$DriverVersion,
    [string]$WixBin = "C:\Program Files (x86)\WiX Toolset v3.14\bin",
    [string]$OutDir = "bin"
)

$ErrorActionPreference = "Stop"

foreach ($msi in @("singlestore-connector-odbc.msi", "power_bi_connector_installer.msi"))
{
    if (-not (Test-Path $msi))
    {
        throw "Missing bundle input: $msi"
    }
}
New-Item -ItemType Directory -Force -Path $OutDir, "power-bi-bundle-installer\obj" | Out-Null

& "$WixBin\candle.exe" ".\power-bi-bundle-installer\Bundle.wxs" -o ".\power-bi-bundle-installer\obj\" -ext WixBalExtension
if ($LASTEXITCODE -ne 0)
{
    throw "candle failed ($LASTEXITCODE)"
}

# The .exe suffix carries both component versions so a downloaded file self-identifies.
$bundleName = "singlestore-power-bi-bundle-$ConnectorVersion-pbi__$DriverVersion-odbc.exe"
& "$WixBin\light.exe" ".\power-bi-bundle-installer\obj\Bundle.wixobj" -o "$OutDir\$bundleName" -ext WixBalExtension
if ($LASTEXITCODE -ne 0)
{
    throw "light failed ($LASTEXITCODE)"
}

Write-Host "Bundle: $OutDir\$bundleName"
if ($env:GITHUB_OUTPUT)
{
    "bundle-path=$OutDir\$bundleName" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}
