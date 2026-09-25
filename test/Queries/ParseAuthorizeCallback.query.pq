// Pins how FinishLogin reads the OAuth redirect. After the user signs in, the IdP sends the browser
// back to the fixed Power BI redirect URI with the result in the query string: "code" + "state" on
// success, or "error" when the user declined / the request was rejected. Missing parameters come
// back as null so the caller can branch on them without try/catch.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Redirect = "https://oauth.powerbi.com/views/oauthredirect.html",
    Tests = {
        Assert[Equal](
            "success callback yields code and state, no error",
            [ code = "abc123", state = "xyz", error = null ],
            () => H[ParseAuthorizeCallback](Redirect & "?code=abc123&state=xyz")
        ),
        Assert[Equal](
            "error callback yields error, no code",
            [ code = null, state = "xyz", error = "access_denied" ],
            () => H[ParseAuthorizeCallback](Redirect & "?error=access_denied&state=xyz")
        ),
        Assert[Equal](
            "callback without query yields all nulls",
            [ code = null, state = null, error = null ],
            () => H[ParseAuthorizeCallback](Redirect)
        ),
        Assert[Equal](
            "url-encoded code is decoded",
            "a b+c",
            () => H[ParseAuthorizeCallback](Redirect & "?code=a%20b%2Bc")[code]
        )
    }
in
    Assert[Run]("ParseAuthorizeCallback", Tests)
