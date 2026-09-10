<#
  Bridges the freshly spun S2MS cluster to PQTest for the Tier 2 folding battery.

  1. Reads the cluster endpoint from WORKSPACE_ENDPOINT_FILE (written by s2ms_cluster.py start).
  2. Substitutes the endpoint host + database into the shared parameter query (in place).
  3. Runs the out-of-band credential flow: credential-template -> replace placeholders ->
     set-credential, keyed to (extension, parameter query). run-compare then picks it up.
#>
param(
    [Parameter(Mandatory = $true)] [string] $PqTestExe,       # full path to PQTest.exe
    [Parameter(Mandatory = $true)] [string] $ExtensionPath,   # SingleStoreODBC.mez
    [Parameter(Mandatory = $true)] [string] $ParameterQuery,  # test/Folding/Connection.parameter.pq
    [Parameter(Mandatory = $true)] [string] $Database,        # DB name created by s2ms_cluster.py
    [string] $EndpointFile = "WORKSPACE_ENDPOINT_FILE",
    [string] $Username     = "admin",
    [string] $AuthKind     = "UsernamePassword"
)

$ErrorActionPreference = "Stop"

# --- Password comes from the environment (GitHub secret), never a parameter/log ---
$password = $env:SQL_USER_PASSWORD
if ([string]::IsNullOrEmpty($password)) {
    throw "SQL_USER_PASSWORD is not set; cannot configure PQTest credentials."
}

# --- 1. Endpoint host ---
if (-not (Test-Path $EndpointFile)) {
    throw "Endpoint file '$EndpointFile' not found. Did s2ms_cluster.py start run first?"
}
$endpoint = (Get-Content -Raw $EndpointFile).Trim()
if ([string]::IsNullOrEmpty($endpoint)) {
    throw "Endpoint file '$EndpointFile' is empty."
}
Write-Host "Cluster endpoint: $endpoint"

# --- 2. Substitute host + database into the parameter query (in place) ---
if (-not (Test-Path $ParameterQuery)) {
    throw "Parameter query '$ParameterQuery' not found."
}
$pq = Get-Content -Raw $ParameterQuery
$pq = $pq.Replace("SINGLESTORE_HOST", $endpoint)
$pq = $pq.Replace("SINGLESTORE_DATABASE", $Database)
# Write UTF-8 without BOM — PQTest's M parser chokes on a leading BOM.
[System.IO.File]::WriteAllText(
    (Resolve-Path $ParameterQuery), $pq, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Substituted endpoint/database into $ParameterQuery"

# --- 3. credential-template -> replace -> set-credential ---
# credential-template is keyed to (extension, query); we key it to the parameter query so the
# single credential is reused across the whole battery.
$template = & $PqTestExe credential-template -e $ExtensionPath -q $ParameterQuery -ak $AuthKind | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "credential-template failed (exit $LASTEXITCODE). Output:`n$template"
}

# The template ships placeholder tokens; the pipeline guide documents $$USERNAME$$ / $$PASSWORD$$.
# Guard against a placeholder-name change in a future SDK: fail loudly rather than set-credential
# with an unsubstituted token (which would silently auth-fail later).
$credential = $template.Replace('$$USERNAME$$', $Username).Replace('$$PASSWORD$$', $password)
if ($credential -match '\$\$[A-Z_]+\$\$') {
    throw ("credential-template contained unexpected placeholder(s) after substitution: " +
           "$($Matches[0]). Template was:`n$template")
}

# Pipe the filled template into set-credential (keyed to the same extension + query).
$credential | & $PqTestExe set-credential -e $ExtensionPath -q $ParameterQuery
if ($LASTEXITCODE -ne 0) {
    throw "set-credential failed (exit $LASTEXITCODE)."
}

# Confirm the credential landed (does not print secrets).
& $PqTestExe list-credential
Write-Host "Credential set for $ExtensionPath against $ParameterQuery."
