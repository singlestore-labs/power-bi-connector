# Signs Windows artifacts with Azure Artifact Signing (Trusted Signing).
# Expects an Azure login (see the `sign` job in .github/workflows/config.yml) and the .NET Sign CLI
# to be available.
#
# Copied from memsql/singlestore-odbc-connector (.github/scripts/sign-windows.ps1) so both
# SingleStore installers are signed the same way, with the same account and certificate profile.
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Files
)

$ErrorActionPreference = "Stop"

foreach ($name in @("AZURE_SIGNING_ENDPOINT", "AZURE_SIGNING_ACCOUNT", "AZURE_SIGNING_PROFILE"))
{
    if (-not (Get-Item "env:$name" -ErrorAction SilentlyContinue).Value)
    {
        throw "$name must be set to sign Windows artifacts"
    }
}

# 'dotnet tool install -g' does not always update PATH of the running session
$signTool = (Get-Command sign -ErrorAction SilentlyContinue).Source
if (-not $signTool)
{
    $signTool = Join-Path $env:USERPROFILE ".dotnet\tools\sign.exe"
}
if (-not (Test-Path $signTool))
{
    throw "Sign CLI not found, install it with 'dotnet tool install -g sign --version <pinned version from config.yml>'"
}

$missing = $Files | Where-Object { -not (Test-Path $_) }
if ($missing)
{
    throw "Cannot sign files that do not exist: $($missing -join ', ')"
}

Write-Host "Signing with Azure Artifact Signing:"
$Files | ForEach-Object { Write-Host "  $_" }

& $signTool code artifact-signing `
    --artifact-signing-endpoint "$ENV:AZURE_SIGNING_ENDPOINT" `
    --artifact-signing-account "$ENV:AZURE_SIGNING_ACCOUNT" `
    --artifact-signing-certificate-profile "$ENV:AZURE_SIGNING_PROFILE" `
    --timestamp-url "http://timestamp.acs.microsoft.com" `
    @Files

if ($LASTEXITCODE -ne 0)
{
    throw "Signing failed with exit code $LASTEXITCODE"
}
