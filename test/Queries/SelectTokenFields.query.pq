// Pins the behavior of Helpers[SelectTokenFields]: a success body is returned unchanged, an
// "error" body raises with the OAuth error code as reason and error_description as message,
// and a body without access_token raises.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal](
            "success body is returned unchanged",
            [ access_token = "jwt", refresh_token = "rt", expires_in = 3600, token_type = "Bearer" ],
            () => H[SelectTokenFields]([ access_token = "jwt", refresh_token = "rt", expires_in = 3600, token_type = "Bearer" ])
        ),
        Assert[Equal](
            "extra IdP fields (id_token, scope) are preserved",
            [ access_token = "jwt", id_token = "idt", scope = "openid offline_access" ],
            () => H[SelectTokenFields]([ access_token = "jwt", id_token = "idt", scope = "openid offline_access" ])
        ),
        Assert[Equal](
            "absent refresh_token stays absent rather than becoming null",
            false,
            () => Record.HasFields(H[SelectTokenFields]([ access_token = "jwt", expires_in = 3600 ]), "refresh_token")
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
        ),
        Assert[ErrorMessage](
            "body without access_token raises",
            "Token endpoint response did not include an access_token",
            () => H[SelectTokenFields]([ token_type = "Bearer", expires_in = 3600 ])
        )
    }
in
    Assert[Run]("SelectTokenFields", Tests)
