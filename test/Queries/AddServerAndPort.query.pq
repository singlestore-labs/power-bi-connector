// Pins the CURRENT behavior of Helpers[AddServerAndPort]. These tests document what the
// shipping connector actually does today, including its limitations (no whitespace trimming,
// no IPv6 support, no port-range validation) — not aspirational behavior.
// TODO: PLAT-8080
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Base = [Driver = "x"],
    Tests = {
        // host[:port] parsing
        Assert[Equal]("host:port keeps custom port", 5000, () => H[AddServerAndPort](Base, "h:5000")[Port]),
        Assert[Equal]("bare host defaults to 3306", 3306, () => H[AddServerAndPort](Base, "h")[Port]),
        Assert[Equal]("trailing colon defaults to 3306", 3306, () => H[AddServerAndPort](Base, "h:")[Port]),
        Assert[Equal]("server field is set to host", "myhost", () => H[AddServerAndPort](Base, "myhost:1")[Server]),
        Assert[Equal]("bare host is stored as server", "onlyhost", () => H[AddServerAndPort](Base, "onlyhost")[Server]),

        // No port-range validation: any Int32 is accepted verbatim.
        Assert[Equal]("port zero is accepted as-is", 0, () => H[AddServerAndPort](Base, "h:0")[Port]),
        Assert[Equal]("negative port is accepted as-is", -1, () => H[AddServerAndPort](Base, "h:-1")[Port]),
        Assert[Equal]("port above 65535 is accepted as-is", 65536, () => H[AddServerAndPort](Base, "h:65536")[Port]),

        // Malformed input errors with the connector's message.
        Assert[ErrorMessage]("empty host errors", "Invalid server address provided", () => H[AddServerAndPort](Base, "")),
        Assert[ErrorMessage]("too many colons errors", "Invalid server address provided", () => H[AddServerAndPort](Base, "a:b:c")),

        // IPv6 is NOT supported: extra colons trip the ">2 parts" guard, bracketed or not.
        Assert[ErrorMessage]("unbracketed IPv6 errors", "Invalid server address provided", () => H[AddServerAndPort](Base, "2001:db8::1")),
        Assert[ErrorMessage]("bracketed IPv6 errors", "Invalid server address provided", () => H[AddServerAndPort](Base, "[2001:db8::1]:4406"))
    }
in
    Assert[Run]("AddServerAndPort", Tests)
