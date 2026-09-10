# Releasing the SingleStore Power BI Connector

This document describes how a release is produced, what it contains, and how to cut one. It covers **two distinct distribution channels** — they are versioned and shipped independently:

1. **GitHub Releases (this repo)** — the bundle `.exe` (ODBC driver + connector) that customers download directly. Automated by CI.
2. **Microsoft built-in connector** — the `.mez` file we hand off to Microsoft so they can update the connector that ships inside Power BI Desktop.

## Versions involved

Two versions move independently:

- **Connector version** — the Power Query connector itself. Kept in sync across three files by `scripts/check-version-sync.sh` (enforced in CI):
  - `[Version = "..."]` in `SingleStoreODBC.pq`
  - `connector-version:` in `.github/workflows/config.yml`
  - `<?define Version ...?>` in `power-bi-connector-installer/Power BI Connector.wxs`
- **Bundle version** — `<?define Version ...?>` in `power-bi-bundle-installer/Bundle.wxs`. Tracked independently of the connector and ODBC driver versions. It **must increase on every release** (including a driver-only refresh) and must **never drop below** the highest version already shipped — the bundle's `UpgradeCode` is fixed, so Burn treats any lower version as a downgrade.

The **ODBC driver version** is not maintained in this repo. CI fetches the *latest* SingleStore ODBC driver release at build time and records its version in the release notes and the bundle filename.

## Cutting a GitHub release

1. **Bump versions**:
   - Bump the **connector version** in all three files if the connector changed (run `scripts/check-version-sync.sh` locally to confirm they match).
   - Bump the **bundle version** in `power-bi-bundle-installer/Bundle.wxs` — always, on every release, even a driver-only refresh.
2. **Merge** the PR to `master` and confirm the `build` job is green.
3. **Tag and push** the release. Use a `v`-prefixed tag that matches the connector version:

   ```bash
   git checkout master && git pull
   git tag v1.1.0
   git push origin v1.1.0
   ```

4. The `release` job builds and publishes the [GitHub Release](../../releases) automatically. Review the generated notes and edit the release description if needed.

## Updating the built-in connector (Microsoft)

The **built-in** connector inside Power BI Desktop is maintained by Microsoft. To get it updated, **we share only the `SingleStoreODBC.mez` file** with the Microsoft team responsible for connector integrations and wait for their review and release.

- The `.mez` is the compiled connector **only** (no ODBC driver). Grab it from the `build` job artifacts (`SingleStoreODBC.mez`) or from the `.mez` attached to the corresponding GitHub Release.
- Microsoft reviews and ships it as part of a future Power BI Desktop update. This step is a manual handoff with no CI automation.
