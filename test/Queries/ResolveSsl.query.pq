let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal]("explicit false wins over encrypt true", false, () => H[ResolveSsl](false, true)),
        Assert[Equal]("explicit true wins over encrypt false", true, () => H[ResolveSsl](true, false)),
        Assert[Equal]("explicit true wins when encrypt is null", true, () => H[ResolveSsl](true, null)),
        Assert[Equal]("explicit false wins when encrypt is null", false, () => H[ResolveSsl](false, null)),
        Assert[Equal]("null option and null encrypt defaults to true", true, () => H[ResolveSsl](null, null)),
        Assert[Equal]("null option uses encrypt false", false, () => H[ResolveSsl](null, false)),
        Assert[Equal]("null option uses encrypt true", true, () => H[ResolveSsl](null, true))
    }
in
    Assert[Run]("ResolveSsl", Tests)
