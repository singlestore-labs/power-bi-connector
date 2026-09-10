# Tier 2 — query-folding tests

These tests confirm that the connector **folds** operations into SQL that runs on SingleStore, rather than pulling whole tables and processing them client-side. They run against a real, throwaway S2MS cluster that is **spun up and torn down on every run**, so — unlike the Tier 1 unit tests — the `Query folding (Tier 2)` job is kept off the plain master-push path. It runs on (see the `if:` on `test-folding` in `config.yml`):

- **pull requests into master** — not just when the PR opens, but on **every push to the PR branch** while it's open (the `synchronize` event). Each push re-provisions a fresh cluster and re-runs the full battery, so an open PR incurs one cluster spin-up per push.
- **version-tag pushes** (`refs/tags/v*`), where it gates the release.
- **manual `workflow_dispatch`**.

## Layout

| File | Role |
| --- | --- |
| `Connection.parameter.pq` | Shared **parameter query** for the navigation-based batteries. Placeholders (`SINGLESTORE_HOST`, `SINGLESTORE_DATABASE`) are substituted at runtime by `setup_folding_credentials.ps1`. PQTest evaluates it once and feeds its result into every case function. It returns the connection **navigation** (the result of `SingleStoreODBC.Contents`), so each case selects the table(s) it needs — one table for most cases, two for the JOIN case. |
| `Connection.CustomSQL.parameter.pq` | Separate **parameter query** for the Custom SQL battery. Calls `SingleStoreODBC.Query(...)` with a raw SQL string (`[EnableFolding=true]`) instead of a navigation. It's separate because PQTest keys credentials per `(extension, parameter-query path)`, so it gets its **own** `set-credential` call in `setup_folding_credentials.ps1`. Its SQL ends with a trailing `;` on purpose — the connector must strip it (`Helpers[StripTrailingSemicolons]`) or `Value.NativeQuery` errors. |
| `Cases/*.query.pq` | A **positive** folding case each, written as `(Source as table) as table => ...`. `Source` is the navigation; a case does e.g. `Source{[Name = "folding_types"]}[Data]`. These are expected to fold. |
| `NoFoldCases/*.query.pq` | A **negative** case each — operations that intentionally do NOT fold (e.g. `LIMIT`). |
| `*/*.query.pqout` | Golden **data** result (the rows the query returns). |

> **No folded-SQL goldens.** The pinned SDK (`pqtest` 2.155.2) `run-compare` has no diagnostic-channel flag, so we can't capture the emitted SQL into a `.diagnostics` file. Folding is instead enforced by `FailOnFoldingFailure` in the positive battery's settings — if a case that must fold doesn't, the run fails.

Two settings files drive two batteries, both against the real connector `bin/Release/SingleStoreODBC.mez` (not the Tier 1 test `.mez`), paths repo-root-relative because `run-compare` is invoked from the repo root:

| Settings | Folder | `FailOnFoldingFailure` | Purpose |
| --- | --- | --- | --- |
| `test/Settings/Folding.testsettings.json` | `Cases/` | `true` | Operations that must fold — a fold failure fails the job. |
| `test/Settings/Folding.NoFold.testsettings.json` | `NoFoldCases/` | `false` | Operations that must NOT fold — fold failure is expected, so it doesn't fail the job; the `.pqout` still verifies the rows are correct. |
| `test/Settings/Folding.CustomSQL.testsettings.json` | `CustomSQLCases/` | `true` | Operations layered on top of a `SingleStoreODBC.Query` custom SQL must still fold. Uses `Connection.CustomSQL.parameter.pq`. |

### Cases

Positive (`Cases/`):
- **WhereFilterFolds** — `WHERE region = 'US-East'` pushes down.
- **GroupByRegionFolds** — `WHERE` + `GROUP BY` + `SUM`/`COUNT` push down.
- **SelectSingleStoreTypesFolds** — projection folds and the SingleStore-specific types (`json` / `geographypoint` / `geography`, fixed up by `Helpers[FixOdbcColumnRow]`) round-trip.
- **JoinRegionsFolds** — an INNER JOIN of `folding_types` to the `regions` dimension (a Power BI relationship expand) pushes down to a single server-side `JOIN`.
- **InequalityFilterFolds** — `amount > 150.25 AND amount <> 500` folds the comparison / not-equal operators to a server-side `WHERE`.
- **InListFilterFolds** — `List.Contains({...}, [region])` (a multi-select / "is one of" slicer) folds to `region IN (...)`.
- **StartsWithFilterFolds** — `Text.StartsWith([region], "US")` (a "begins with" text filter) folds to `region LIKE 'US%'`.
- **NullCheckFilterFolds** — `[note] <> null` folds to `note IS NOT NULL`, using the dedicated `nullable_probe` table (whose `note` column actually contains NULLs).
- **AggregatesFold** — whole-table `MIN`/`MAX`/`AVG` of `amount` fold to a single-row aggregate.
- **DistinctCountFold** — `List.Count(List.Distinct([region]))` (a DISTINCTCOUNT measure) folds to `COUNT(DISTINCT region)`.

Custom SQL (`CustomSQLCases/`):
- **CustomSqlFilterFolds** — a `WHERE`/`ORDER BY` layered on top of a `SingleStoreODBC.Query(..., [EnableFolding=true])` native query folds into it (not client-side). The parameter query's trailing `;` also proves `Helpers[StripTrailingSemicolons]` runs. Uses `Connection.CustomSQL.parameter.pq` + its own credential.

Negative (`NoFoldCases/`):
- **LimitDoesNotFold** — `Table.FirstN` (row limit) does not fold; `ORDER BY` folds but no `LIMIT`.
- **OffsetDoesNotFold** — `Table.Range` (skip/take, i.e. `LIMIT ... OFFSET`) does not fold either; the OFFSET sibling of LimitDoesNotFold.
