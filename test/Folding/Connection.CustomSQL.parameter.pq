// What:  parameter query for the Custom SQL folding battery. Unlike Connection.parameter.pq (a
//        navigation via SingleStoreODBC.Contents), this calls SingleStoreODBC.Query with raw SQL.
// Notes: - SEPARATE file on purpose: PQTest keys credentials per (extension, parameter-query path),
//          so it gets its own `set-credential` in setup_folding_credentials.ps1.
//        - The trailing ";" below is deliberate: SingleStoreODBC.Query must strip it via
//          Helpers[StripTrailingSemicolons] before Value.NativeQuery (which errors on a trailing
//          ";"). If the strip regresses, evaluating this query fails outright.
//        - [EnableFolding = true] keeps folding on, so the WHERE/ORDER BY a case layers on top
//          folds INTO this native query (asserted by FailOnFoldingFailure=true).
//        - HOST / DATABASE are PLACEHOLDERS, substituted at runtime by setup_folding_credentials.ps1.
let
    Source = SingleStoreODBC.Query(
        "SINGLESTORE_HOST",
        "SINGLESTORE_DATABASE",
        "SELECT id, region, amount FROM folding_types;"
    )
in
    Source
