let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal]("varchar(255) shortens to varchar", "varchar", () => H[RenameOdbcType]("varchar(255)")),
        Assert[Equal]("int unsigned is preserved", "int unsigned", () => H[RenameOdbcType]("int unsigned")),
        Assert[Equal]("bigint(20) unsigned shortens and keeps unsigned", "bigint unsigned", () => H[RenameOdbcType]("bigint(20) unsigned")),
        Assert[Equal]("json stays json", "json", () => H[RenameOdbcType]("json")),
        Assert[Equal]("decimal(10,2) shortens to decimal", "decimal", () => H[RenameOdbcType]("decimal(10,2)")),
        // Matching is case-sensitive: uppercase "UNSIGNED" is not detected, and only the first
        // token (up to "(" or space) is kept, so "BIGINT" comes back with no unsigned suffix.
        Assert[Equal]("uppercase UNSIGNED is not detected", "BIGINT", () => H[RenameOdbcType]("BIGINT(20) UNSIGNED")),
        // Leading whitespace is not trimmed: the split on space yields an empty first token.
        Assert[Equal]("leading whitespace yields empty token", "", () => H[RenameOdbcType]("  GEOGRAPHY  "))
    }
in
    Assert[Run]("RenameOdbcType", Tests)
