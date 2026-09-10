// What:     `List.Count(List.Distinct([region]))` folds to `SELECT COUNT(DISTINCT region)` — the
//           shape Power BI emits for a DISTINCTCOUNT measure.
// Notes:    kept separate from AggregatesFold because COUNT(DISTINCT) is the aggregate most likely
//           to not fold cleanly through the ODBC layer. FailOnFoldingFailure=true.
// Expected: 3 distinct regions (US-East, US-West, EU-West) -> distinct_regions = 3.
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data]
    in
        Table.Group(
            FoldingTypes,
            {},
            {
                {"distinct_regions", each List.Count(List.Distinct([region])), Int64.Type}
            }
        )
