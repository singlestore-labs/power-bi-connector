#!/usr/bin/env bash
# Verifies the CONNECTOR version is identical across the 3 files that carry it, and reports the
# BUNDLE version. This guard fails CI if the connector version drifts, or if either version can't be read.
#
# Usage: scripts/check-version-sync.sh
# Exit:  0 = connector version in sync + bundle version present, 1 = mismatch or missing.

set -euo pipefail
cd "$(dirname "$0")/.."

extract() {
  # $1 = file, $2 = sed regex capturing the version into \1
  sed -nE "s/.*${2}.*/\1/p" "$1" | head -n1
}

# The connector version lives in these 3 files, all kept identical.
connector_files=(
  "pq|SingleStoreODBC.pq|\\[Version = \"([0-9]+\\.[0-9]+\\.[0-9]+)\"\\]"
  "gha|.github/workflows/config.yml|connector-version: *([0-9]+\\.[0-9]+\\.[0-9]+)"
  "connector_wxs|power-bi-connector-installer/Power BI Connector.wxs|<\\?define Version = \"([0-9]+\\.[0-9]+\\.[0-9]+)\" \\?>"
)
# The bundle has its OWN version (independent of the connector).
bundle_file="power-bi-bundle-installer/Bundle.wxs"
bundle_regex='<\?define Version = "([0-9]+\.[0-9]+\.[0-9]+)" \?>'

declare -A versions
fail=0
echo "Connector version by file:"
for entry in "${connector_files[@]}"; do
  IFS='|' read -r key path regex <<<"$entry"
  if [[ ! -f "$path" ]]; then
    printf '  %-16s %s\n' "$key" "<file missing: $path>"
    fail=1
    continue
  fi
  versions[$key]=$(extract "$path" "$regex")
  printf '  %-16s %s\n' "$key" "${versions[$key]:-<not found>}"
done

reference="${versions[pq]:-}"
if [[ -z "$reference" ]]; then
  echo "ERROR: could not read connector version from SingleStoreODBC.pq" >&2
  exit 1
fi
for key in gha connector_wxs; do
  if [[ "${versions[$key]:-}" != "$reference" ]]; then
    echo "MISMATCH: $key = '${versions[$key]:-<not found>}' (expected '$reference')" >&2
    fail=1
  fi
done

# Bundle version: report only, not compared to the connector (it is intentionally independent).
if [[ ! -f "$bundle_file" ]]; then
  echo "ERROR: bundle file missing: $bundle_file" >&2
  exit 1
fi
bundle_version=$(extract "$bundle_file" "$bundle_regex")
echo "Bundle version (independent): ${bundle_version:-<not found>}"
if [[ -z "$bundle_version" ]]; then
  echo "ERROR: could not read bundle version from $bundle_file" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "Version check failed. Connector version must match across its 3 file." >&2
  exit 1
fi
echo "OK: connector version $reference in sync; bundle version $bundle_version."
