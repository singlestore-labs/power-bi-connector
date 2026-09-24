// Pins the rule that the access-token (Key) auth path mandates SSL. SingleStore JWT users are
// created REQUIRE SSL, so GetODBCDataSource forces encryption on whenever this returns true,
// overriding the user's UseSSL / EncryptConnection choice for the Key auth path.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal]("Key auth requires SSL", true, () => H[TokenAuthRequiresSsl]("Key")),
        Assert[Equal]("UsernamePassword does not force SSL", false, () => H[TokenAuthRequiresSsl]("UsernamePassword")),
        Assert[Equal]("Windows does not force SSL", false, () => H[TokenAuthRequiresSsl]("Windows")),
        Assert[Equal]("null auth kind does not force SSL", false, () => H[TokenAuthRequiresSsl](null))
    }
in
    Assert[Run]("TokenAuthRequiresSsl", Tests)
