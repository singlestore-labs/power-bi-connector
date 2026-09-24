// Pins the credential -> CredentialConnectionString mapping used by GetODBCDataSource.
// Each auth kind maps to a specific set of ODBC connection-string fields:
//   UsernamePassword -> UID/PWD, Windows -> Trusted_Connection, Key (access token) -> JWT only.
// The Key case emits the token via the driver's dedicated JWT= property (not PWD) and sends no
// UID at all: the server resolves the user from the token's claims.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal](
            "UsernamePassword maps to UID/PWD",
            [ UID = "alice", PWD = "secret" ],
            () => H[BuildCredentialConnectionString]([ AuthenticationKind = "UsernamePassword", Username = "alice", Password = "secret" ])
        ),
        Assert[Equal](
            "Windows maps to Trusted_Connection",
            [ Trusted_Connection = "Yes" ],
            () => H[BuildCredentialConnectionString]([ AuthenticationKind = "Windows" ])
        ),
        Assert[Equal](
            "Key maps the access token to JWT= only (no UID)",
            [ JWT = "the.jwt.token" ],
            () => H[BuildCredentialConnectionString]([ AuthenticationKind = "Key", Key = "the.jwt.token" ])
        ),
        Assert[ErrorMessage](
            "unhandled auth kind errors",
            "Unhandled authentication kind: Anonymous",
            () => H[BuildCredentialConnectionString]([ AuthenticationKind = "Anonymous" ])
        )
    }
in
    Assert[Run]("BuildCredentialConnectionString", Tests)
