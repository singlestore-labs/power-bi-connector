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

Windows release artifacts are signed via Azure Artifact Signing (Trusted Signing) using Workload Identity Federation.

### What is signed

| Artifact | Signed by | How |
| --- | --- | --- |
| `singlestore-power-bi-bundle-<pbi>-pbi__<odbc>-odbc.exe` (customer download) | SingleStore, Inc. | Azure Artifact Signing, in this repo's `sign` job. The Burn engine inside the bundle is signed separately, then the bundle itself. |
| `power_bi_connector_installer.msi` (embedded in the bundle) | SingleStore, Inc. | Same, signed before the bundle is built |
| `singlestore-connector-odbc.msi` (embedded in the bundle) | SingleStore, Inc. | Signed upstream by the ODBC driver's own release pipeline. CI **verifies** it and never re-signs it. |
| `SingleStoreODBC.mez` | nobody | Not signed. It is a custom connector; Power BI Desktop loads it only with custom connectors enabled. This is also the Microsoft handoff artifact. |

### Required GitHub Actions secrets

| Secret | Description |
| --- | --- |
| `AZURE_CLIENT_ID` | Application (client) ID of `github-singlestore-signing` |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID used for signing |

### Required GitHub Actions variables

| Variable | Example value |
| --- | --- |
| `AZURE_SIGNING_ENDPOINT` | `https://eus.codesigning.azure.net` |
| `AZURE_SIGNING_ACCOUNT`  | `SingleStore` |
| `AZURE_SIGNING_PROFILE`  | `ConnectorsReleaseProfile` |

## Updating the built-in connector (Microsoft)

The **built-in** connector inside Power BI Desktop is maintained by Microsoft. To get it updated, **we share only the `SingleStoreODBC.mez` file** with the Microsoft team responsible for connector integrations and wait for their review and release.

- The `.mez` is the compiled connector **only** (no ODBC driver). Grab it from the `build` job artifacts (`SingleStoreODBC.mez`) or from the `.mez` attached to the corresponding GitHub Release.
- Microsoft reviews and ships it as part of a future Power BI Desktop update. This step is a manual handoff with no CI automation.
