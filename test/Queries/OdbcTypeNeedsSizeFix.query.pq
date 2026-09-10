// Pins the CURRENT behavior of Helpers[OdbcTypeNeedsSizeFix]: true only for an exact,
// lowercase match of "json", "geographypoint", or "geography"; false for anything else.
// Matching is case-sensitive and exact (no substring), so "JSON" and "json(1)" are false.
// TODO: PLAT-8080
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal]("json needs size fix", true, () => H[OdbcTypeNeedsSizeFix]("json")),
        Assert[Equal]("geography needs size fix", true, () => H[OdbcTypeNeedsSizeFix]("geography")),
        Assert[Equal]("geographypoint needs size fix", true, () => H[OdbcTypeNeedsSizeFix]("geographypoint")),
        Assert[Equal]("varchar does not need size fix", false, () => H[OdbcTypeNeedsSizeFix]("varchar")),
        Assert[Equal]("int does not need size fix", false, () => H[OdbcTypeNeedsSizeFix]("int")),
        Assert[Equal]("uppercase JSON is not matched", false, () => H[OdbcTypeNeedsSizeFix]("JSON")),
        Assert[Equal]("whitespace and case are not normalized", false, () => H[OdbcTypeNeedsSizeFix]("  Geography  "))
    }
in
    Assert[Run]("OdbcTypeNeedsSizeFix", Tests)
