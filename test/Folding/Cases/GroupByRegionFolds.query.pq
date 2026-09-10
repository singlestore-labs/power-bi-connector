// What:     WHERE + GROUP BY + SUM/COUNT fold into one server-side aggregate query
//           (`SELECT region, SUM(amount), COUNT(*) ... WHERE amount >= 200 GROUP BY region`).
// Notes:    final sort by region folds to ORDER BY; GROUP BY alone doesn't guarantee order, so
//           the sort makes the golden deterministic. FailOnFoldingFailure=true.
// Expected: the amount >= 200 subset grouped by region; golden pins each region's total_amount
//           and row_count.
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data],
        Filtered = Table.SelectRows(FoldingTypes, each [amount] >= 200),
        Grouped = Table.Group(
            Filtered,
            {"region"},
            {
                {"total_amount", each List.Sum([amount]), type nullable number},
                {"row_count", each Table.RowCount(_), Int64.Type}
            }
        ),
        Sorted = Table.Sort(Grouped, {{"region", Order.Ascending}})
    in
        Sorted
