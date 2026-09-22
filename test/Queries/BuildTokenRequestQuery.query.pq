// Pins the form body TokenMethod POSTs to the token endpoint. One helper serves both OAuth grants:
// the initial exchange sends the authorization code as "code" together with the PKCE code_verifier,
// while a refresh sends the stored token as "refresh_token" and no verifier. Nothing else (client
// secret in particular) is ever added — this is a public PKCE client.
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
