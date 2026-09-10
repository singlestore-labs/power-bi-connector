// What:     NEGATIVE case — an OFFSET-style skip/take (`Table.Range(sorted, 2, 3)` = skip 2, take 3,
//           i.e. `LIMIT 3 OFFSET 2`) intentionally does NOT fold. OFFSET sibling of LimitDoesNotFold.
// Notes:    same reason as LimitDoesNotFold — Config_SupportsTop=false because Power BI only folds
//           TOP, so the range stays client-side even though AstVisitor.LimitClause could emit it.
//           Lives in NoFoldCases/ (FailOnFoldingFailure=false); the ORDER BY still folds.
// Expected: sorted first, skip ids 1, 2 -> return ids 3, 4, 5.
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data]
    in
        Table.Range(
            Table.Sort(FoldingTypes, {{"id", Order.Ascending}}),
            2,
            3
        )
