// Pins the behavior of Helpers[ParseOidcDiscovery]: extracts authorization_endpoint, token_endpoint
// and the optional end_session_endpoint from the discovery document; errors if authorize or token is missing.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Issuer = "https://authsvc.singlestore.com/auth/oidc/op/Customer",
    Discovery = [
        issuer = Issuer,
        authorization_endpoint = Issuer & "/authorize",
        token_endpoint = Issuer & "/token",
        end_session_endpoint = Issuer & "/end_session",
        jwks_uri = Issuer & "/jwks",
        response_types_supported = { "code" },
        code_challenge_methods_supported = { "S256" }
    ],
    Tests = {
        Assert[Equal](
            "authorize, token and end_session endpoints are extracted",
            [ authorize = Issuer & "/authorize", token = Issuer & "/token", endSession = Issuer & "/end_session" ],
            () => H[ParseOidcDiscovery](Discovery)
        ),
        Assert[Equal](
            "missing end_session_endpoint yields null endSession",
            [ authorize = Issuer & "/authorize", token = Issuer & "/token", endSession = null ],
            () => H[ParseOidcDiscovery](Record.RemoveFields(Discovery, "end_session_endpoint"))
        ),
        Assert[ErrorMessage](
            "missing token_endpoint errors",
            "OIDC discovery document missing authorization_endpoint or token_endpoint",
            () => H[ParseOidcDiscovery](Record.RemoveFields(Discovery, "token_endpoint"))
        ),
        Assert[ErrorMessage](
            "missing authorization_endpoint errors",
            "OIDC discovery document missing authorization_endpoint or token_endpoint",
            () => H[ParseOidcDiscovery](Record.RemoveFields(Discovery, "authorization_endpoint"))
        ),
        Assert[ErrorMessage](
            "empty document errors",
            "OIDC discovery document missing authorization_endpoint or token_endpoint",
            () => H[ParseOidcDiscovery]([])
        )
    }
in
    Assert[Run]("ParseOidcDiscovery", Tests)
