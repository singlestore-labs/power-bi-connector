# Fails unless every file carries a valid, timestamped Authenticode signature whose signer
# subject contains -Subject. Two independent checks run on each file:
#   1. Get-AuthenticodeSignature (status, signer, timestamp), with the certificate details logged.
#   2. signtool verify /pa /all /v from the Windows SDK, which walks every signature in the file.
#
# Used in CI for the upstream ODBC driver MSI and for our own outputs after signing.
#
# The leaf certificate thumbprint is logged but deliberately NOT enforced: Azure Artifact Signing
# rotates leaf certificates daily, so only the subject and chain validity are stable.
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Files,
    [string]$Subject = "Singlestore, Inc."
)

$ErrorActionPreference = "Stop"

function Find-SignTool
{
    $cmd = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($cmd)
    {
        return $cmd.Source
    }
    # Windows SDK layout: ...\Windows Kits\10\bin\<sdk version>\x64\signtool.exe. Prefer the newest SDK.
    $kits = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10\bin"
    $candidates = Get-ChildItem -Path $kits -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*\x64\signtool.exe" } |
        Sort-Object -Property FullName -Descending
    if ($candidates)
    {
        return $candidates[0].FullName
    }
    throw "signtool.exe not found; the Windows SDK is required for signature verification"
}

$signTool = Find-SignTool
Write-Host "Using signtool: $signTool"

$failed = @()

foreach ($f in $Files)
{
    if (-not (Test-Path $f))
    {
        throw "Cannot verify a file that does not exist: $f"
    }

    Write-Host ""
    Write-Host "== $f"

    $sig  = Get-AuthenticodeSignature -FilePath $f
    $cert = $sig.SignerCertificate
    $subj = if ($cert) { $cert.Subject } else { "<none>" }

    Write-Host "  status     : $($sig.Status) - $($sig.StatusMessage)"
    Write-Host "  signer     : $subj"
    if ($cert)
    {
        Write-Host "  issuer     : $($cert.Issuer)"
        Write-Host "  valid      : $($cert.NotBefore.ToUniversalTime().ToString('u')) .. $($cert.NotAfter.ToUniversalTime().ToString('u'))"
        Write-Host "  thumbprint : $($cert.Thumbprint) (informational, rotates daily)"
    }
    if ($sig.TimeStamperCertificate)
    {
        Write-Host "  timestamp  : $($sig.TimeStamperCertificate.Subject)"
    }
    else
    {
        Write-Host "  timestamp  : NOT timestamped"
    }

    $ok = $true
    if ($sig.Status -ne 'Valid')
    {
        Write-Host "  FAIL: signature status is $($sig.Status)"
        $ok = $false
    }
    if ($subj -notlike "*$Subject*")
    {
        Write-Host "  FAIL: signer subject does not contain '$Subject'"
        $ok = $false
    }
    # A missing timestamp is a failure: Artifact Signing certificates are valid for 72 hours, so
    # an untimestamped signature stops validating within days.
    if (-not $sig.TimeStamperCertificate)
    {
        Write-Host "  FAIL: signature is not timestamped"
        $ok = $false
    }

    # /pa = Default Authenticode verification policy, /all = verify every signature in the file,
    # /v = print signer and timestamp chains (including the timestamp time).
    & $signTool verify /pa /all /v $f
    if ($LASTEXITCODE -ne 0)
    {
        Write-Host "  FAIL: signtool verify exited with $LASTEXITCODE"
        $ok = $false
    }

    if (-not $ok)
    {
        $failed += $f
    }
}

Write-Host ""
if ($failed)
{
    throw "Signature check failed for: $($failed -join ', ')"
}
Write-Host "All signatures valid."
