// What:     a projection folds to `SELECT id, payload, location, area` (not `SELECT *`) AND the
//           SingleStore-specific types (json / geographypoint / geography) round-trip.
// Notes:    exercises the `Helpers[FixOdbcColumnRow]` SQLColumns fixup (those three types treated
//           as 65535-char text) end-to-end against a live driver. Sorted by id for determinism.
//           FailOnFoldingFailure=true.
// Expected: golden pins the actual json/geography values surviving the round-trip.
(Source as table) as table =>
    let
        FoldingTypes = Source{[Name = "folding_types"]}[Data]
    in
        Table.Sort(
            Table.SelectColumns(FoldingTypes, {"id", "payload", "location", "area"}),
            {{"id", Order.Ascending}}
        )
