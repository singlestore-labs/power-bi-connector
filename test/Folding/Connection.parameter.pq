// What:  shared parameter query for the navigation-based folding batteries. PQTest evaluates it
//        once and feeds its result in as each case's `Source`.
// Notes: - Returns the connection NAVIGATION (SingleStoreODBC.Contents), not a single table, so a
//          case navigates to what it needs, e.g. `Source{[Name = "folding_types"]}[Data]` (or both
//          folding_types and regions for the JOIN). The navigation is lazy, so single-table cases
//          fold as if bound to the table directly.
//        - HOST / DATABASE are PLACEHOLDERS; setup_folding_credentials.ps1 substitutes the real
//          S2MS endpoint at runtime (not known until the cluster is spun).
//        - The credential is keyed to (extension, THIS file), set once and reused across the
//          battery — see the `pqtest-credentials-out-of-band` note.
let
    Source = SingleStoreODBC.Contents("SINGLESTORE_HOST", "SINGLESTORE_DATABASE")
in
    Source
