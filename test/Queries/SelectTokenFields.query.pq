// Pins how a parsed token-endpoint response becomes the credential record Power BI stores. The
// access_token field is what GetODBCDataSource later injects as JWT=, so it must survive as-is;
// refresh_token / expires_in / token_type ride along (Power BI keeps them in the credential's
// Properties) and default to null when the IdP omits them. An "error" body becomes an M error whose
// reason is the OAuth error code, so sign-in failures surface with the IdP's own wording.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal](
            "full response keeps all four fields",
            [ access_token = "jwt", refresh_token = "rt", expires_in = 3600, token_type = "Bearer" ],
            () => H[SelectTokenFields]([ access_token = "jwt", refresh_token = "rt", expires_in = 3600, token_type = "Bearer" ])
        ),
        Assert[Equal](
            "response without refresh_token yields null refresh_token",
            [ access_token = "jwt", refresh_token = null, expires_in = 3600, token_type = "Bearer" ],
            () => H[SelectTokenFields]([ access_token = "jwt", expires_in = 3600, token_type = "Bearer" ])
        ),
        Assert[Equal](
            "extra IdP fields are dropped",
            [ access_token = "jwt", refresh_token = null, expires_in = null, token_type = null ],
            () => H[SelectTokenFields]([ access_token = "jwt", id_token = "idt", scope = "openid" ])
        ),
        Assert[ErrorMessage](
            "error body raises with the error_description",
            "The provided authorization grant is invalid",
            () => H[SelectTokenFields]([ error = "invalid_grant", error_description = "The provided authorization grant is invalid" ])
        ),
        Assert[Equal](
            "error body without description still raises with the error code as reason",
            "invalid_client",
            () => (try H[SelectTokenFields]([ error = "invalid_client" ]))[Error][Reason]
        )
    }
in
    Assert[Run]("SelectTokenFields", Tests)
