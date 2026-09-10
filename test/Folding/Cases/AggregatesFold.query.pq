// What:     whole-table MIN/MAX/AVG of `amount` fold to a single-row aggregate
//           (`SELECT MIN(amount), MAX(amount), AVG(amount) FROM folding_types`). Empty group key
//           -> one row, the shape Power BI emits for card / summary visuals.
// Notes:    GroupByRegionFolds covers SUM/COUNT with a GROUP BY. Kept separate from
//           DistinctCountFold so a fold failure points at the right aggregate. FailOnFoldingFailure=true.
// Expected: from amounts {100.50, 200.00, 300.75, 150.25, 500.00, 250.50} -> MIN 100.50,
//           MAX 500.00, AVG 250.333333 (AVG renders at full float precision).
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data]
    in
        Table.Group(
            FoldingTypes,
            {},
            {
                {"min_amount", each List.Min([amount]), type nullable number},
                {"max_amount", each List.Max([amount]), type nullable number},
                {"avg_amount", each List.Average([amount]), type nullable number}
            }
        )
