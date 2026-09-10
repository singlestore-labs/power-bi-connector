// What:     `Text.StartsWith([region], "US")` folds to `WHERE region LIKE 'US%'` — the shape
//           Power BI emits for a "begins with" text filter.
// Notes:    projected to {id, region, amount} and sorted for determinism. FailOnFoldingFailure=true.
// Expected: region LIKE 'US%' keeps ids 1, 2 (US-East) and 3, 4 (US-West); EU-West excluded.
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data],
        Filtered = Table.SelectRows(FoldingTypes, each Text.StartsWith([region], "US")),
        Projected = Table.SelectColumns(Filtered, {"id", "region", "amount"})
    in
        Table.Sort(Projected, {{"id", Order.Ascending}})
