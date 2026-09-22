// Pins the RFC 4648 §5 base64url encoding used to build the PKCE code_challenge. It is standardAdd a comment on  lines R1 to R5Add diff commentMarkdown input:  edit mode selected.WritePreviewAdd a suggestionHeadingBold(control b) control⌃ bBItalic(control i) control⌃ iIQuote(control shift right angle bracket) control⌃ shift⇧ right angle bracket>Code(control e) control⌃ eELink(control k) control⌃ kKUnordered list(control 8) control⌃ 88Numbered list(control shift ampersand) control⌃ shift⇧ ampersand&Task list(control shift l) control⌃ shift⇧ lLMentionReferenceSlash commandsMore itemsSaved repliesAdd FilesPaste, drop, or click to add filesCancelCommentStart a review
// base64 with the "=" padding removed and the two URL-unsafe characters remapped ("+"->"-", "/"->"_").
// Byte vector {251,239,255} standard-encodes to "++//", exercising both remaps; the short inputs
// exercise 0/1/2 padding characters being stripped.
let
    H = SingleStoreODBCTests.Helpers,
    Assert = SingleStoreODBCTests.Assert,
    Tests = {
        Assert[Equal]("empty binary encodes to empty text", "", () => H[Base64UrlEncode](#binary({}))),
        Assert[Equal]("one byte drops the ""=="" padding", "Zg", () => H[Base64UrlEncode](#binary({102}))),
        Assert[Equal]("two bytes drop the ""="" padding", "Zm8", () => H[Base64UrlEncode](#binary({102, 111}))),
        Assert[Equal]("three bytes need no padding", "Zm9v", () => H[Base64UrlEncode](#binary({102, 111, 111}))),
        Assert[Equal]("""+"" and ""/"" are remapped to ""-"" and ""_""", "--__", () => H[Base64UrlEncode](#binary({251, 239, 255})))
    }
in
    Assert[Run]("Base64UrlEncode", Tests)
