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

MathlibLink prepares mathlib for use through LeanLink. Imported functions,
theorems, structures and instances are available as Lean terms. Computable
expressions return Wolfram values; noncomputable definitions remain typed terms.
The environment interface requires the accompanying LeanLink development branch.

## Functions

### Setup

- `InstallMathlib` install the pinned Lean and mathlib runtime
- `MathlibInstallation` inspect its status, directory and versions

### Working through LeanLink

- [LeanImport](paclet:Wolfram/LeanLink/ref/LeanImport) import mathlib modules
- [LeanEnvironment](paclet:Wolfram/LeanLink/ref/LeanEnvironment) hold their declarations
- [LeanTerm](paclet:Wolfram/LeanLink/ref/LeanTerm) inspect a declaration's type, definition and axioms
- [LeanEvaluate](paclet:Wolfram/LeanLink/ref/LeanEvaluate) evaluate expressions and apply imported functions
- [LeanImportString](paclet:Wolfram/LeanLink/ref/LeanImportString) compile additional definitions and theorems
- [LeanVerify](paclet:Wolfram/LeanLink/ref/LeanVerify) check a theorem in Lean's kernel and audit its axioms
- [LeanFreeEnvironment](paclet:Wolfram/LeanLink/ref/LeanFreeEnvironment) release an environment and stop its evaluator

### Compatibility sessions

Existing session-based code remains supported, including with released LeanLink
versions. With the new environment interface, these calls delegate to LeanLink.

- `StartMathlibSession` open a compatibility session
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
