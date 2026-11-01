---
Template: Guide
Name: MathlibLink
Title: Mathlib from the Wolfram Language
Description: Inspect Lean declarations, compute exact values and check proofs using mathlib
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/guide/MathlibLink
Keywords: [Lean, mathlib, formal proof, mathematics]
RelatedTutorials: [GettingStarted, ArithmeticPatterns, ValuesAndProofs, PartialComputations]
---

## Abstract

MathlibLink connects Wolfram Language to mathlib through explicit Lean sessions.
The full declaration namespace is available for inspection, exact computation
and proof construction. Noncomputable definitions and theorems remain typed
Lean objects.

## Functions

### Setup and sessions

- `InstallMathlib` install the pinned Lean and mathlib runtime
- `MathlibInstallation` inspect its status and versions
- `StartMathlibSession` open a session with all of mathlib or selected imports
- `MathlibSession` represent the lifetime of a session and its objects

### Declarations and expressions

- `MathlibNames` find declaration names in the loaded environment
- `MathlibDeclaration` inspect a function, theorem, structure or instance
- `MathlibCall` apply a named function to structured arguments
- `MathlibEvaluate` evaluate a Lean expression
- `MathlibExpression` supply explicit Lean syntax in a structured argument
- `MathlibObject` retain a typed declaration or expression

### Proofs

- `ProveMathlib` construct a theorem with kernel replay and axiom checks

## Related Links

- [mathlib documentation](https://leanprover-community.github.io/mathlib4_docs/)
- [Lean reference manual](https://lean-lang.org/doc/reference/latest/)
- [mathlib v4.35.0 source](https://github.com/leanprover-community/mathlib4/tree/v4.35.0)
