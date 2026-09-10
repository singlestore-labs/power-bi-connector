// What:     a WHERE (amount >= 200) and ORDER BY (id) layered on top of a SingleStoreODBC.Query
//           custom SQL still fold INTO the native query, not client-side.
// Notes:    `Source` is the CustomSQL parameter query — Value.NativeQuery over
//           "SELECT id, region, amount FROM folding_types" with [EnableFolding=true]. This is the
//           payoff of Custom SQL under DirectQuery: a hand-written query downstream ops still
//           refine server-side. FailOnFoldingFailure=true in Folding.CustomSQL.testsettings.json.
// Expected: amount >= 200 keeps ids 2 (200.00), 3 (300.75), 5 (500.00), 6 (250.50); sorted by id.
(Source as table) as table =>
    Table.Sort(
        Table.SelectRows(Source, each [amount] >= 200),
        {{"id", Order.Ascending}}
    )
