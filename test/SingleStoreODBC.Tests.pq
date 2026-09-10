// Test-only extension. It is never shipped.
// It loads the same Helpers.pqm file as the production connector and exports a small
// assertion API used by the independent PQ/PQOut test queries.
section SingleStoreODBCTests;

Extension.LoadFunction = (name as text) =>
    Expression.Evaluate(Text.FromBinary(Extension.Contents(name)), #shared);

Helpers = Extension.LoadFunction("Helpers.pqm");

Render = (value as any) as text =>
    if value = null then
        "null"
    else
        let
            Rendered = try Text.From(value, "en-US")
        in
            if Rendered[HasError] then "«complex value»" else Rendered[Value];

AssertEqual = (
    name as text,
    expected as any,
    evaluateActual as function
) as logical =>
    let
        Actual = try evaluateActual(),
        ErrorMessage =
            if Actual[HasError] then
                let Message = try Actual[Error][Message]
                in if Message[HasError] then "«missing error message»" else Message[Value]
            else
                null,
        Comparison = if Actual[HasError] then null else try Actual[Value] = expected
    in
        if Actual[HasError] then
            error Error.Record(
                "Assertion.Error",
                name & " threw unexpectedly: " & ErrorMessage,
                Actual[Error]
            )
        else if Comparison[HasError] then
            error Error.Record(
                "Assertion.Error",
                name & " could not be compared.",
                [Expected = expected, Actual = Actual[Value], ComparisonError = Comparison[Error]]
            )
        else if Comparison[Value] = true then
            true
        else
            error Error.Record(
                "Assertion.Error",
                name & " failed. Expected " & Render(expected) & ", actual " & Render(Actual[Value]) & ".",
                [Expected = expected, Actual = Actual[Value]]
            );

AssertErrorMessage = (
    name as text,
    expectedMessage as text,
    evaluateActual as function
) as logical =>
    let
        Actual = try evaluateActual(),
        MessageResult = if Actual[HasError] then try Actual[Error][Message] else null,
        ActualMessage =
            if not Actual[HasError] then
                null
            else if MessageResult[HasError] then
                "«missing error message»"
            else
                MessageResult[Value]
    in
        if not Actual[HasError] then
            error Error.Record(
                "Assertion.Error",
                name & " failed. Expected error message '" & expectedMessage & "', but no error was raised.",
                [ExpectedMessage = expectedMessage, Actual = Actual[Value]]
            )
        else if ActualMessage = expectedMessage then
            true
        else
            error Error.Record(
                "Assertion.Error",
                name & " failed. Expected error message '" & expectedMessage & "', actual '" & ActualMessage & "'.",
                [ExpectedMessage = expectedMessage, ActualMessage = ActualMessage, ActualError = Actual[Error]]
            );

RunAssertions = (suiteName as text, assertions as list) as text =>
    let
        Passed = List.AllTrue(assertions),
        Count = List.Count(assertions)
    in
        if Passed then
            suiteName & ": " & Text.From(Count) & " tests passed."
        else
            error Error.Record(
                "Assertion.Error",
                suiteName & " contained an assertion that returned false.",
                null
            );

shared SingleStoreODBCTests.Helpers = Helpers;
shared SingleStoreODBCTests.Assert = [
    Equal = AssertEqual,
    ErrorMessage = AssertErrorMessage,
    Run = RunAssertions
];

