// What:     `each [note] <> null` folds to `WHERE note IS NOT NULL` (SQL null semantics) — the
//           shape Power BI emits for "remove empty" / "is not blank" filters.
// Notes:    uses the dedicated `nullable_probe` table, whose `note` column actually contains NULLs
//           (folding_types has none), so the filter returns a real subset. FailOnFoldingFailure=true.
// Expected: note IS NOT NULL keeps ids 1 ('alpha') and 3 ('gamma'); ids 2 and 4 are NULL.
(Source as table) as table =>
    let
        NullableProbe = Source{[Name = "nullable_probe"]}[Data],
        Filtered = Table.SelectRows(NullableProbe, each [note] <> null)
    in
        Table.Sort(Filtered, {{"id", Order.Ascending}})
