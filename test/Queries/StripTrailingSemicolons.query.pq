// Pins the CURRENT behavior of Helpers[StripTrailingSemicolons] = Text.TrimEnd(query, ";").
// It trims only trailing ";" characters — never whitespace — so any trailing space or newline
// stops the trim.
// TODO: PLAT-8080
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal]("single trailing semicolon is stripped", "SELECT 1", () => H[StripTrailingSemicolons]("SELECT 1;")),
        Assert[Equal]("multiple trailing semicolons are stripped", "SELECT 1", () => H[StripTrailingSemicolons]("SELECT 1;;")),
        Assert[Equal]("query without semicolon is unchanged", "SELECT 1", () => H[StripTrailingSemicolons]("SELECT 1")),
        Assert[Equal]("embedded semicolon is preserved", "SELECT a; SELECT b", () => H[StripTrailingSemicolons]("SELECT a; SELECT b;")),
        // Whitespace is NOT trimmed: a trailing space or newline after the ";" stops the trim.
        Assert[Equal]("trailing spaces after semicolon are left intact", "SELECT 1;   ", () => H[StripTrailingSemicolons]("SELECT 1;   ")),
        Assert[Equal]("trailing newline after semicolon is left intact", "SELECT 1;#(cr)#(lf)", () => H[StripTrailingSemicolons]("SELECT 1;#(cr)#(lf)")),
        Assert[Equal]("trailing whitespace without semicolon is left intact", "SELECT 1   ", () => H[StripTrailingSemicolons]("SELECT 1   ")),
        Assert[Equal]("null remains null", null, () => H[StripTrailingSemicolons](null)),
        Assert[Equal]("empty string remains empty", "", () => H[StripTrailingSemicolons](""))
    }
in
    Assert[Run]("StripTrailingSemicolons", Tests)
