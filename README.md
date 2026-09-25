# SingleStore Direct Query Connector for Power BI

A [Power BI](https://powerbi.microsoft.com/) / Power Query custom connector that lets you **DirectQuery** and **Import** data from a [SingleStore](https://www.singlestore.com/) (formerly MemSQL) database. It is built with the [Power Query Data Connector SDK](https://github.com/microsoft/DataConnectors) as a thin layer over the [SingleStore ODBC driver](https://github.com/memsql/singlestore-odbc-connector).

The connector supports:

- **DirectQuery and Import** storage modes.
- **Native Query** with query folding enabled.
- **SSL/TLS** encrypted connections.
- **Username/Password**, **Windows**, and **Access token (JWT)** authentication.

## Prerequisites

1. [Power BI Desktop](https://powerbi.microsoft.com/en-us/desktop/) (latest version recommended).
2. The [SingleStore ODBC driver](https://github.com/memsql/singlestore-odbc-connector/releases) (64-bit — `...win64.msi`). This is installed for you if you use the **bundle installer** below.

## Install

There are two ways to get the connector. Understand the difference before choosing.

### Option A — Built-in to Power BI connector

Power BI Desktop ships with a built-in **SingleStore Direct Query Connector**. It is certified by Microsoft and requires no custom-connector setup, but you must install the [SingleStore ODBC driver](https://github.com/memsql/singlestore-odbc-connector/releases) yourself.

> **Trade-off:** the built-in connector is updated only when Microsoft accepts and ships a new version, **which can take a long time**. If you need a newer version than Microsoft has shipped, use Option B.

### Option B — GitHub release (this repo)

We publish new versions on the [Releases](../../releases) page ahead of Microsoft.

**Bundle installer** — a single `.exe` that installs **both** the SingleStore ODBC driver **and** the Power BI connector.

> **⚠️ Not Microsoft-certified.** GitHub releases have **not** been reviewed or signed by Microsoft, even though they pass Microsoft's required connector test suite. Because they are unsigned custom connectors, you must **enable custom connectors** (below) — and Power BI enforces this **every time** you use a connector that isn't a built-in one.

### Enable custom connectors (Option B only)

Required whenever you use a non-built-in connector:

**File → Options and settings → Options → Security → Data Extensions → *(Not recommended) Allow any extension to load without validation or warning*.**

Restart Power BI Desktop.

## Usage

1. On the **Home** ribbon, choose **Get Data → More**, then select **SingleStore Direct Query Connector**.
2. In the dialog, enter:
   - **Server** — your SingleStore hostname/IP as `host` or `host:port` (default port `3306`).
   - **Database** — the database to connect to.
   - **Data Connectivity mode** — **Import** or **DirectQuery**.
   - **Native query** (optional) — a read-only SQL query to ingest data directly. DDL is not supported.
3. In the left pane choose an authentication method, then **Connect**:
   - **Basic** (username/password) — SingleStore Helios supports **Basic** only.
   - **Windows** authentication.
   - **Access token (JWT)** — paste a SingleStore access token instead of a password (see below).
4. Choose tables in the **Navigator** (or confirm your native-query preview), then **Load**, or **Transform Data** to edit first.

To change saved credentials later: **File → Options and settings → Data source settings →** select the connector **→ Edit Permissions**.

> 📖 Full walkthrough with screenshots: [Connect Power BI Desktop to SingleStore](https://docs.singlestore.com/cloud/query-data/connect-with-analytics-and-bi-tools/connect-with-power-bi/connect-power-bi-desktop-to-singlestore/).

### Access token (JWT) authentication

If your SingleStore instance is configured for [JWT authentication](https://docs.singlestore.com/cloud/security/database-access/authenticate-via-jwt/) (users created `IDENTIFIED WITH authentication_jwt`), you can connect with an access token instead of a password:

1. In the sign-in dialog, choose **Access token (JWT)**.
2. Paste your JWT into the **Access token** field and **Connect**.

Notes:

- The token is passed to the driver's dedicated `JWT=` connection property — not the password field. You do **not** enter a username and the connector sends none: the server resolves it from the token's claims.
- JWT users are created `REQUIRE SSL`, so the connector **always encrypts** this connection regardless of the **Use SSL** option.
- The token is used as-is; the connector does not acquire or refresh it. When it expires, edit the saved credential (**Data source settings → Edit Permissions**) and paste a fresh token.

## Power BI Service (on-premises data gateway)

To refresh reports in the Power BI Service, connect through an [on-premises data gateway](https://learn.microsoft.com/data-integration/gateway/service-gateway-onprem):

1. Install the SingleStore ODBC driver and the **Power BI on-premises data gateway** on the gateway machine, and register the gateway with your Microsoft account.
2. In the Service, under **Settings → Manage gateways**, enable **Allow user's custom data connectors to refresh through this gateway cluster** for the cluster.
3. Add a **New data source** with **Data source type = SingleStore database**, fill in **Server** and **Database**, choose **Basic** authentication (Helios supports Basic only), and add it. Use **Skip Test Connection** if a test error blocks you.

The connector exposes a `TestConnection` handler so the gateway can validate credentials.

> **Access token (JWT) on the gateway:** the connector uses the pasted token as-is and does not refresh it, so scheduled refresh will fail once the token expires. Re-enter a fresh token on the gateway data source before it lapses, or use Basic authentication for unattended refresh.

> 📖 Full walkthrough with screenshots: [Connect Power BI Service to SingleStore via the Power BI gateway](https://docs.singlestore.com/cloud/query-data/connect-with-analytics-and-bi-tools/connect-with-power-bi/connect-power-bi-service-to-singlestore-via-power-bi-gateway/).

## Build

Development, building, and testing require **Windows** (the Power Query SDK, MSBuild, and Power BI Desktop do not run on Linux/macOS). Source edits can be made anywhere.

1. Install the [Power Query SDK](https://learn.microsoft.com/power-query/install-sdk) (VS Code extension, or the legacy Visual Studio extension).

2. Build with MSBuild:

   ```powershell
   msbuild ".\SingleStore Direct Query.sln" -p:Configuration=Release
   ```

   Output: `bin\Release\SingleStoreODBC.mez`.

CI (GitHub Actions, on Windows) fetches the latest SingleStore ODBC driver, builds the `.mez`, and produces the connector `.msi` and the bundle `.exe` on every push. Pushing a version tag (`v*`) additionally publishes a GitHub Release with the bundle installer attached. See [`RELEASE.md`](RELEASE.md) for how releases are produced and how the `.mez` is handed off to Microsoft for the built-in connector.

## Behavior notes

A few connector behaviors are worth knowing up front:

- **Some queries do not fold** due to a mix of Power BI support and SingleStore ODBC compliance. For example, ranges and limits do not fold: Power BI only folds `TOP` SQL statements, not the `LIMIT` statements SingleStore uses.
- **Server-side prepared statements are disabled** (`no_ssps=1`) for compatibility with SingleStore. Since SingleStore already compiles and parametrizes its queries, this has minimal performance impact.

## Documentation

- [Connect Power BI Desktop to SingleStore](https://docs.singlestore.com/cloud/query-data/connect-with-analytics-and-bi-tools/connect-with-power-bi/connect-power-bi-desktop-to-singlestore/)
- [Connect Power BI Service to SingleStore via the Power BI gateway](https://docs.singlestore.com/cloud/query-data/connect-with-analytics-and-bi-tools/connect-with-power-bi/connect-power-bi-service-to-singlestore-via-power-bi-gateway/)

## License

See [`LICENSE`](LICENSE).
