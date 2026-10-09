// Pins the behavior of Helpers[PreserveRefreshToken]: a refresh response that carries a new
// refresh_token is returned as-is; one without it gets the current refresh_token added back so the
// stored credential never loses the ability to refresh.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal](
            "rotated refresh_token in the response is kept",
            [ access_token = "new-jwt", refresh_token = "new-rt", expires_in = 3600 ],
            () => H[PreserveRefreshToken]([ access_token = "new-jwt", refresh_token = "new-rt", expires_in = 3600 ], "old-rt")
        ),
        Assert[Equal](
            "response without refresh_token retains the old one",
            [ access_token = "new-jwt", expires_in = 3600, refresh_token = "old-rt" ],
            () => H[PreserveRefreshToken]([ access_token = "new-jwt", expires_in = 3600 ], "old-rt")
        )
    }
in
    Assert[Run]("PreserveRefreshToken", Tests)
