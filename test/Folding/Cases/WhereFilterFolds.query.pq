// What:     equality filter `region = 'US-East'` folds to a server-side WHERE. Baseline case.
// Notes:    PQTest binds the parameter query's navigation as `Source`. Trailing sort folds to
//           ORDER BY (keeps golden order deterministic; doesn't affect the WHERE assertion).
//           FailOnFoldingFailure=true fails the run if the filter can't fold.
// Expected: the two matching rows, ids 1 and 2.
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data]
    in
        Table.Sort(
            Table.SelectRows(FoldingTypes, each [region] = "US-East"),
            {{"id", Order.Ascending}}
        )
