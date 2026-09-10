// Pins the CURRENT behavior of Helpers[FixOdbcColumnRow]: it renames TYPE_NAME via
// RenameOdbcType and, only for the size-less types (exact lowercase json/geography*),
// inflates the size fields. Note the size fix sets CHAR_OCTET_LENGTH to 3 (not 65535*3),
// and type matching is case-sensitive — uppercase "JSON" gets no fix.
// TODO: PLAT-8080
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    JsonRow = [
        TYPE_NAME = "json",
        COLUMN_SIZE = 10,
        BUFFER_LENGTH = 10,
        CHAR_OCTET_LENGTH = 1,
        ORDINAL_POSITION = 7
    ],
    VarcharRow = [
        TYPE_NAME = "varchar(255)",
        COLUMN_SIZE = 255,
        BUFFER_LENGTH = 256,
        CHAR_OCTET_LENGTH = 255,
        ORDINAL_POSITION = 8
    ],
    UppercaseJsonRow = [
        TYPE_NAME = "JSON",
        COLUMN_SIZE = 1,
        BUFFER_LENGTH = 1,
        CHAR_OCTET_LENGTH = 1
    ],
    GeographyRow = [
        TYPE_NAME = "geography",
        COLUMN_SIZE = 1,
        BUFFER_LENGTH = 1,
        CHAR_OCTET_LENGTH = 1
    ],
    FixedJson = H[FixOdbcColumnRow](JsonRow),
    FixedVarchar = H[FixOdbcColumnRow](VarcharRow),
    FixedUppercaseJson = H[FixOdbcColumnRow](UppercaseJsonRow),
    FixedGeography = H[FixOdbcColumnRow](GeographyRow),
    Tests = {
        Assert[Equal]("json row inflates COLUMN_SIZE", 65535, () => FixedJson[COLUMN_SIZE]),
        Assert[Equal]("json row sets BUFFER_LENGTH to 65535*3+1", 196606, () => FixedJson[BUFFER_LENGTH]),
        Assert[Equal]("json row sets CHAR_OCTET_LENGTH to 3", 3, () => FixedJson[CHAR_OCTET_LENGTH]),
        Assert[Equal]("json row keeps canonical TYPE_NAME", "json", () => FixedJson[TYPE_NAME]),
        Assert[Equal]("json row preserves unrelated metadata", 7, () => FixedJson[ORDINAL_POSITION]),
        Assert[Equal]("varchar row shortens TYPE_NAME", "varchar", () => FixedVarchar[TYPE_NAME]),
        Assert[Equal]("varchar row leaves COLUMN_SIZE unchanged", 255, () => FixedVarchar[COLUMN_SIZE]),
        Assert[Equal]("varchar row leaves BUFFER_LENGTH unchanged", 256, () => FixedVarchar[BUFFER_LENGTH]),
        Assert[Equal]("varchar row preserves unrelated metadata", 8, () => FixedVarchar[ORDINAL_POSITION]),
        // Type matching is case-sensitive: "JSON" is NOT size-fixed and TYPE_NAME is left as-is.
        Assert[Equal]("uppercase JSON is not size-fixed", 1, () => FixedUppercaseJson[COLUMN_SIZE]),
        Assert[Equal]("uppercase JSON TYPE_NAME is left unchanged", "JSON", () => FixedUppercaseJson[TYPE_NAME]),
        Assert[Equal]("geography row sets CHAR_OCTET_LENGTH to 3", 3, () => FixedGeography[CHAR_OCTET_LENGTH])
    }
in
    Assert[Run]("FixOdbcColumnRow", Tests)
