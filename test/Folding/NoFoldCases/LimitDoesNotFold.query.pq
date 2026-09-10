// What:     NEGATIVE case — a row limit (`Table.FirstN`) intentionally does NOT fold.
// Notes:    SingleStore uses LIMIT not TOP, and Power BI only folds TOP, so Config_SupportsTop=false
//           and the limit stays client-side (documented README limitation). Lives in NoFoldCases/
//           under Folding.NoFold.testsettings.json (FailOnFoldingFailure=false), so the expected
//           fold-failure isn't a test failure; the ORDER BY still folds. Pins the behavior so a
//           change can't silently start/stop folding limits.
// Expected: sorted first, then top 3 -> ids 1, 2, 3.
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data]
    in
        Table.FirstN(
            Table.Sort(FoldingTypes, {{"id", Order.Ascending}}),
            3
        )
