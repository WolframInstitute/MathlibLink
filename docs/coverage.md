# Coverage and verification

Checked on 2026-11-01 with Wolfram Language 15.0 on macOS ARM64,
LeanLink 1.2.5, Lean 4.35.0 and mathlib commit
`56a005855ea17e0b0958f73ec801ae140b0a1679` (v4.35.0).

## Namespace coverage

A default session imports `Mathlib`. The imported environment contains
797,294 declaration names, including Lean, dependency and generated declarations.
The integration test compares the complete sorted result of `MathlibNames`
with LeanLink's native environment inventory, including internal names. The
sets are equal. This is a count of declarations, not a count of numerical
functions.

`MathlibCall` accepts a declaration name from that environment and builds a
Lean application. Lean resolves its types, implicit arguments and typeclass
instances. There is no per-function wrapper list or domain whitelist.
`MathlibExpression` supplies Lean syntax where structured values are not
sufficient. `MathlibEvaluate` accepts arbitrary Lean expressions.

Declarations that are noncomputable, proof-valued or lack a JSON conversion
remain available as typed `MathlibObject` values. Internal compiler artifacts
can have names that Lean's source parser or the native bridge cannot resolve
again from text; listing them does not make them public callable functions.
The official documentation website follows development, while local types
and source modules come from the pinned release.

## Live checks

The 22 integration checks cover:

- Exact equality of the complete imported namespace.
- Generic calls to `Nat.choose`, `Nat.sqrt`, `Nat.totient`, `Int.natAbs`
  and `List.reverse`.
- Exact transfer of `2^100` and Unicode, quoting and control characters.
- Evaluation of `Nat.Partrec.Code.evaln`.
- Typed declarations from algebra, analysis, topology and computability:
  `mul_comm`, `Real.exp_add`, `Continuous.comp` and
  `Nat.Partrec.Code.exists_code`.
- Links to the declaring modules in the official mathlib documentation.
- A universal natural-number theorem accepted by Lean's kernel.
- Rejection of `sorry`, a false theorem and a `native_decide` proof whose
  compiler-backed trust is outside this interface's accepted proof basis.
- Retaining a noncomputable function with its Lean type.
- Session ownership, independent closure of shared imports and timeout cleanup.

The separate local tests cover installation metadata, exact argument encoding,
option validation, unavailable objects, closure, interruption and timeout paths.
The maintained commands are `make check`, `make test` and `make test-mathlib`.
Raw reports and experiment logs are generated under ignored `build/`.

## Proof boundary

A computed value is not a checked theorem. `ProveMathlib` checks the generated
module in Lean's kernel and examines the theorem's axiom dependencies. It
accepts only Lean's standard `propext`, `Quot.sound` and `Classical.choice`
axioms. The installed Lean toolchain, imported libraries and LeanLink bridge
remain part of the trusted implementation. Namespace coverage does not claim
that every imported function was numerically tested or every imported theorem
was independently reproved by MathlibLink.
