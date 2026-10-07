// Pins the behavior of Helpers[ParseOidcDiscovery]: extracts authorization_endpoint and
// token_endpoint from the discovery document and errors if either is missing.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Issuer = "https://authsvc.singlestore.com/auth/oidc/op/Customer",
    Discovery = [
        issuer = Issuer,
        authorization_endpoint = Issuer & "/authorize",
        token_endpoint = Issuer & "/token",
        jwks_uri = Issuer & "/jwks",
        response_types_supported = { "code" },
        code_challenge_methods_supported = { "S256" }
    ],
    Tests = {
        Assert[Equal](
            "authorize and token endpoints are extracted",
            [ authorize = Issuer & "/authorize", token = Issuer & "/token" ],
            () => H[ParseOidcDiscovery](Discovery)
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
