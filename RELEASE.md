# Releasing the SingleStore Power BI Connector

This document describes how a release is produced, what it contains, and how to cut one. It covers **two distinct distribution channels** — they are versioned and shipped independently:

1. **GitHub Releases (this repo)** — the bundle `.exe` (ODBC driver + connector) that customers download directly. Automated and signed by CI.
2. **Microsoft built-in connector** — the `.mez` file we hand off to Microsoft so they can update the connector that ships inside Power BI Desktop.

## Versions involved

Three versions are tracked in this repo:

- **Connector version** — the Power Query connector itself. Kept in sync across three files by `scripts/check-version-sync.sh` (enforced in CI):
  - `[Version = "..."]` in `SingleStoreODBC.pq`
  - `connector-version:` in `.github/workflows/config.yml`
  - `<?define Version ...?>` in `power-bi-connector-installer/Power BI Connector.wxs`
- **Bundle version** — `<?define Version ...?>` in `power-bi-bundle-installer/Bundle.wxs`. Tracked independently of the connector and ODBC driver versions. It **must increase on every release** (including a driver-only refresh) and must **never drop below** the highest version already shipped — the bundle's `UpgradeCode` is fixed, so Burn treats any lower version as a downgrade.
- **ODBC driver version** — `odbc-driver-version:` in `.github/workflows/config.yml`. The driver is not built here; CI downloads exactly this release of the [SingleStore ODBC driver](https://github.com/memsql/singlestore-odbc-connector/releases) (`singlestore-connector-odbc-<version>-win64.msi`). It is pinned, not resolved to `latest`, so a tag fully defines the bytes that are tested, signed and shipped. The version appears in the release notes and in the bundle filename.

## Cutting a GitHub release

1. **Bump versions**:
   - Bump the **connector version** in all three files if the connector changed (run `scripts/check-version-sync.sh` locally to confirm they match).
   - Bump the **ODBC driver version** in `config.yml` if a newer driver should be bundled. The driver MSI must be signed by SingleStore (see [Signing](#signing)); CI refuses to build otherwise.
   - Bump the **bundle version** in `power-bi-bundle-installer/Bundle.wxs` — always, on every release, even a driver-only refresh.
2. **Merge** the PR to `master` and confirm the workflow is green.
3. **Tag and push** the release. Use a `v`-prefixed tag that matches the connector version:

   ```bash
   git checkout master && git pull
   git tag v1.1.0
   git push origin v1.1.0
   ```

4. The tag run rebuilds and re-tests everything, signs the installers (`sign` job), and the `release` job publishes the [GitHub Release](../../releases) with the signed bundle `.exe` and the `.mez` attached. Review the generated notes and edit the release description if needed.

The workflow refuses to publish if the ODBC driver MSI is not signed by SingleStore, if any signature it produced is invalid or not timestamped, or if any test tier fails. The `release` job downloads the signed bundle by exact artifact name, so the unsigned bundle built for validation in the `build` job can never reach a release.

## Signing

### What is signed

| Artifact | Signed by | How |
| --- | --- | --- |
| `singlestore-power-bi-bundle-<pbi>-pbi__<odbc>-odbc.exe` (customer download) | SingleStore, Inc. | Azure Artifact Signing, in this repo's `sign` job. The Burn engine inside the bundle is signed separately, then the bundle itself. |
| `power_bi_connector_installer.msi` (embedded in the bundle) | SingleStore, Inc. | Same, signed before the bundle is built |
| `singlestore-connector-odbc.msi` (embedded in the bundle) | SingleStore, Inc. | Signed upstream by the ODBC driver's own release pipeline. CI **verifies** it and never re-signs it. |
| `SingleStoreODBC.mez` | nobody | Not signed. It is a custom connector; Power BI Desktop loads it only with custom connectors enabled. This is also the Microsoft handoff artifact. |

Windows therefore shows *Verified publisher: Singlestore, Inc.* when the bundle runs, but the connector remains an unsigned custom connector inside Power BI. Signing the `.mez` (as a `.pqx`) would need a long-lived code-signing certificate whose private key SingleStore controls; Artifact Signing does not provide that (its certificates rotate daily) and is out of scope here.

### How it works

- Signing uses the same Azure Artifact Signing account, certificate profile and Entra App Registration as the SingleStore ODBC driver repo, with the same variable and secret names. `.github/scripts/sign-windows.ps1` is a copy of the ODBC repo's script.
- The `sign` job runs only for `v*` tags and for manual dry runs (`Run workflow` with `sign` ticked). It runs after `build`, `test` and `test-folding`, so a signature always means the exact artifact passed release validation. Pull request builds never get `id-token: write` or the Azure secrets.
- The ODBC MSI is verified as soon as it is downloaded, in the `odbc-driver` job that every other job depends on. Order inside `sign`: sign the connector MSI → build the bundle from the signed MSIs (`build-bundle.ps1`) → detach the Burn engine, sign it, verify it, reattach it, sign the bundle (`sign-bundle.ps1`) → verify the connector MSI, the ODBC MSI and the bundle (`verify-signature.ps1`, which runs both `Get-AuthenticodeSignature` and `signtool verify /pa /all /v`).
- Every signature is timestamped (`http://timestamp.acs.microsoft.com`). Artifact Signing leaf certificates are valid for 72 hours, so an untimestamped signature would stop validating within days; verification fails if the timestamp is missing.
- Azure authentication is OIDC via a federated identity credential on the App Registration. No client secret is stored anywhere.
- The .NET Sign CLI is pinned (`sign-cli-version` in `config.yml`). It has no stable release; do not install it unpinned.

### One-time setup

**GitHub (repository settings)**

- Secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` — the App Registration used for signing (same values as the ODBC repo).
- Variables: `AZURE_SIGNING_ENDPOINT` (e.g. `https://eus.codesigning.azure.net`), `AZURE_SIGNING_ACCOUNT`, `AZURE_SIGNING_PROFILE`.

**Entra (needs rights on the App Registration)**

The App Registration must hold the *Artifact Signing Certificate Profile Signer* role on the certificate profile (already the case if it is the ODBC repo's app) and must trust this repo's GitHub OIDC tokens through a federated identity credential.

This repository was created after 15 July 2026, so GitHub issues OIDC subjects in the **immutable format** that includes owner and repository IDs:

```
repo:singlestore-labs@79943160/power-bi-connector@1363583999:ref:refs/tags/v1.1.0
```

A name-only pattern such as `repo:singlestore-labs/power-bi-connector:...` never matches. The subject also changes per ref, so use Entra *flexible* federated identity credentials (claims-matching expressions, portal or Microsoft Graph only) rather than an exact subject. One credential per pattern; the expression language has no `or`:

| Purpose | Expression |
| --- | --- |
| Release tags | `claims['sub'] matches 'repo:singlestore-labs@79943160/power-bi-connector@1363583999:ref:refs/tags/v*' and claims['repository_owner_id'] eq '79943160'` |
| Manual dry runs from `master` (optional) | `claims['sub'] matches 'repo:singlestore-labs@79943160/power-bi-connector@1363583999:ref:refs/heads/master' and claims['repository_owner_id'] eq '79943160'` |

Issuer `https://token.actions.githubusercontent.com`, audience `api://AzureADTokenExchange`. The `sign` job prints the exact subject it presents (step *Print OIDC subject*) before logging in, so a failed login always shows what the credential has to match. If the repo is moved or renamed the IDs stay the same but the names in the subject change; update the expressions.

The branch credential is what allows anyone with write access to produce a signed dry run from that branch, so keep it pinned to a single branch name and delete it if dry runs are not needed.

### Dry run

Actions → *PowerBI Connector CI* → *Run workflow*, pick the branch, tick `sign`. The `release` job does not run (not a tag), so nothing is published. Download the `signed-bundle` artifact and check it:

- Windows: `Get-AuthenticodeSignature .\singlestore-power-bi-bundle-*.exe` must be `Valid` with signer `Singlestore, Inc.` and a timestamp. Extract the engine with `insignia -ib <bundle> -o engine.exe` and check it the same way. Running the installer must show *Verified publisher: Singlestore, Inc.* in the UAC prompt.
- Linux/macOS: `osslsigncode verify -in <bundle>` (it may warn that the Microsoft root is not in the local trust store; that is about local trust, not the signature).

### Troubleshooting

| Symptom | Cause |
| --- | --- |
| `azure/login` → `AADSTS7002131` "No matching federated identity record found" | The credential's expression does not match the printed subject: missing `@id` parts, wrong ref, or no credential for this ref type |
| `azure/login` → `AADSTS700016` | Wrong `AZURE_CLIENT_ID` / `AZURE_TENANT_ID` |
| Sign CLI → 403 / Forbidden | App Registration lacks *Artifact Signing Certificate Profile Signer* on this profile, or wrong endpoint/account/profile variables |
| Sign CLI → no matching certificate profile | `AZURE_SIGNING_PROFILE` typo or profile disabled |
| `verify-signature.ps1` fails on the ODBC MSI in the `odbc-driver` job | Upstream published an unsigned or differently signed driver build. Stop the release and raise it in the ODBC repo |
| `verify-signature.ps1` → valid but `NOT timestamped` | Timestamp server unreachable; re-run, never ship untimestamped |
| `fetch-odbc-driver` → asset not found | `odbc-driver-version` does not match an existing release tag/asset name |

## Updating the built-in connector (Microsoft)

The **built-in** connector inside Power BI Desktop is maintained by Microsoft. To get it updated, **we share only the `SingleStoreODBC.mez` file** with the Microsoft team responsible for connector integrations and wait for their review and release.

- The `.mez` is the compiled connector **only** (no ODBC driver). Grab it from the `build` job artifacts (`SingleStoreODBC.mez`) or from the `.mez` attached to the corresponding GitHub Release.
- Microsoft reviews and ships it as part of a future Power BI Desktop update. This step is a manual handoff with no CI automation.
