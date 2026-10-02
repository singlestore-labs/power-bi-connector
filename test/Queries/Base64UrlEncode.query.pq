// Pins the RFC 4648 §5 base64url encoding used to build the PKCE code_challenge. It is standard
// base64 with the "=" padding removed and the two URL-unsafe characters remapped ("+"->"-", "/"->"_").
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal]("empty binary encodes to empty text", "", () => H[Base64UrlEncode](#binary({}))),
        Assert[Equal]("one byte drops the ""=="" padding", "Zg", () => H[Base64UrlEncode](#binary({102}))),
        Assert[Equal]("two bytes drop the ""="" padding", "Zm8", () => H[Base64UrlEncode](#binary({102, 111}))),
        Assert[Equal]("three bytes need no padding", "Zm9v", () => H[Base64UrlEncode](#binary({102, 111, 111}))),
        Assert[Equal]("""+"" and ""/"" are remapped to ""-"" and ""_""", "--__", () => H[Base64UrlEncode](#binary({251, 239, 255})))
    }
in
    Assert[Run]("Base64UrlEncode", Tests)
