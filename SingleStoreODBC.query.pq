// Use this file to write queries to test your data connector
let
    result = SingleStoreODBC.Contents("127.0.0.1", "test"),
    db = result{[Name="welldata"]}[Data],
    allViews = db{[Name="welltest"]}[Data],
    first = Table.FirstN(allViews,1)
in
    //allViews
    //Table.RowCount(allViews)
    //Table.Group(first, "bitstatus", {"Total", each List.Sum([blockheight])})
    //Table.RowCount(allViews)
    Table.RowCount(Table.Distinct(allViews))
