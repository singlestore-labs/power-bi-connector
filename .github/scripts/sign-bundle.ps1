# Signs a WiX v3 Burn bundle (.exe) with Azure Artifact Signing.
#
# The Burn engine is a separate PE that Burn extracts and caches at install time, so it must be
# signed on its own: detach it with insignia, sign it, reattach it, then sign the outer bundle
# last. Anything changed inside the bundle after signing invalidates the outer signature, which
# is why the MSIs must already be signed before the bundle is built (see build-bundle.ps1).
# See https://wixtoolset.org/docs/v3/overview/insignia/
param(
    [Parameter(Mandatory = $true)] [string]$Bundle,
    [string]$WixBin = "C:\Program Files (x86)\WiX Toolset v3.14\bin"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Bundle))
{
    throw "Bundle not found: $Bundle"
}
$insignia   = Join-Path $WixBin "insignia.exe"
$signScript = Join-Path $PSScriptRoot "sign-windows.ps1"
$bundlePath = (Resolve-Path $Bundle).Path
$engine     = Join-Path (Split-Path $bundlePath -Parent) "burn-engine.exe"

Write-Host "Detaching Burn engine from $bundlePath"
& $insignia -ib $bundlePath -o $engine
if ($LASTEXITCODE -ne 0)
{
    throw "insignia -ib failed ($LASTEXITCODE)"
}

& $signScript -Files $engine

Write-Host "Reattaching signed engine"
& $insignia -ab $engine $bundlePath -o $bundlePath
if ($LASTEXITCODE -ne 0)
{
    throw "insignia -ab failed ($LASTEXITCODE)"
}

& $signScript -Files $bundlePath

# The detached engine is an intermediate; leave only the bundle in the output directory.
Remove-Item $engine -Force
Write-Host "Signed bundle: $bundlePath"
