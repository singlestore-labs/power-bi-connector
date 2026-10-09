// Pins the behavior of Helpers[ParseOidcDiscovery]: extracts authorization_endpoint, token_endpoint
// and the optional revocation_endpoint from the discovery document; errors if authorize or token is missing.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Issuer = "https://authsvc.singlestore.com/auth/oidc/op/Customer",
    Discovery = [
        issuer = Issuer,
        authorization_endpoint = Issuer & "/authorize",
        token_endpoint = Issuer & "/token",
        revocation_endpoint = Issuer & "/revoke",
        jwks_uri = Issuer & "/jwks",
        response_types_supported = { "code" },
        code_challenge_methods_supported = { "S256" }
    ],
    Tests = {
        Assert[Equal](
            "authorize, token and revocation endpoints are extracted",
            [ authorize = Issuer & "/authorize", token = Issuer & "/token", revocation = Issuer & "/revoke" ],
            () => H[ParseOidcDiscovery](Discovery)
        ),
        Assert[Equal](
            "missing revocation_endpoint yields null revocation",
            [ authorize = Issuer & "/authorize", token = Issuer & "/token", revocation = null ],
            () => H[ParseOidcDiscovery](Record.RemoveFields(Discovery, "revocation_endpoint"))
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
