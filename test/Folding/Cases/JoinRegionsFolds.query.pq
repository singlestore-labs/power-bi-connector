// What:     an INNER JOIN folds to a single server-side JOIN
//           (`... FROM folding_types JOIN regions ON region = region_code`). Table.NestedJoin +
//           Table.ExpandTableColumn is what the engine emits for a Power BI relationship expand
//           (fact `folding_types.region` -> dim `regions.region_code`).
// Notes:    both tables come from the same navigation, so the join stays foldable. A non-folding
//           join would break relationship-based DirectQuery reports — hence FailOnFoldingFailure=true.
// Expected: 1:1 matching keys -> all 6 fact rows survive, enriched with region_name/country;
//           sorted by id.
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data],
        Regions = Source{[Name = "regions"]}[Data],
        Joined = Table.NestedJoin(
            FoldingTypes, {"region"},
            Regions, {"region_code"},
            "RegionData", JoinKind.Inner
        ),
        Expanded = Table.ExpandTableColumn(
            Joined, "RegionData", {"region_name", "country"}
        ),
        Projected = Table.SelectColumns(
            Expanded, {"id", "region", "amount", "region_name", "country"}
        ),
        Sorted = Table.Sort(Projected, {{"id", Order.Ascending}})
    in
        Sorted
