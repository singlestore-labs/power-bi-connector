// Pins the behavior of Helpers[BuildTokenRequestQuery]: the authorization_code grant sends "code"
// plus the PKCE code_verifier, the refresh_token grant sends "refresh_token" and no verifier.
// No client_secret is ever added (public client).
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    ClientId = "my-client",
    Redirect = "https://oauth.powerbi.com/views/oauthredirect.html",
    Tests = {
        Assert[Equal](
            "authorization_code grant sends code + code_verifier",
            [ client_id = ClientId, grant_type = "authorization_code", redirect_uri = Redirect, code = "auth-code", code_verifier = "verifier" ],
            () => H[BuildTokenRequestQuery](ClientId, Redirect, "authorization_code", "auth-code", "verifier")
        ),
        Assert[Equal](
            "refresh_token grant sends refresh_token and no verifier",
            [ client_id = ClientId, grant_type = "refresh_token", redirect_uri = Redirect, refresh_token = "stored-refresh" ],
            () => H[BuildTokenRequestQuery](ClientId, Redirect, "refresh_token", "stored-refresh")
        ),
        Assert[Equal](
            "explicit null verifier is omitted",
            [ client_id = ClientId, grant_type = "refresh_token", redirect_uri = Redirect, refresh_token = "stored-refresh" ],
            () => H[BuildTokenRequestQuery](ClientId, Redirect, "refresh_token", "stored-refresh", null)
        ),
        Assert[Equal](
            "no client_secret is ever included",
            false,
            () => Record.HasFields(H[BuildTokenRequestQuery](ClientId, Redirect, "authorization_code", "auth-code", "verifier"), "client_secret")
        )
    }
in
    Assert[Run]("BuildTokenRequestQuery", Tests)
