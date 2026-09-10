// What:     `List.Contains({...}, [region])` folds to `WHERE region IN ('US-East', 'EU-West')` —
//           the shape Power BI emits for a multi-select slicer / "is one of" filter.
// Notes:    projected to {id, region, amount} and sorted for determinism. FailOnFoldingFailure=true.
// Expected: region IN ('US-East', 'EU-West') keeps ids 1, 2 (US-East) and 5, 6 (EU-West).
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data],
        Filtered = Table.SelectRows(
            FoldingTypes, each List.Contains({"US-East", "EU-West"}, [region])
        ),
        Projected = Table.SelectColumns(Filtered, {"id", "region", "amount"})
    in
        Table.Sort(Projected, {{"id", Order.Ascending}})
