// What:     comparison / not-equal predicates (`>`, `<>`) fold to a server-side WHERE.
//           `amount > 150.25 AND amount <> 500`.
// Notes:    WhereFilterFolds covers `=`; this covers the range operators Power BI emits for numeric
//           filters. Projected to {id, region, amount} and sorted for determinism.
//           FailOnFoldingFailure=true.
// Expected: amount > 150.25 keeps 200.00 (2), 300.75 (3), 500.00 (5), 250.50 (6); `<> 500` drops
//           id 5 -> ids 2, 3, 6.
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data],
        Filtered = Table.SelectRows(FoldingTypes, each [amount] > 150.25 and [amount] <> 500),
        Projected = Table.SelectColumns(Filtered, {"id", "region", "amount"})
    in
        Table.Sort(Projected, {{"id", Order.Ascending}})
