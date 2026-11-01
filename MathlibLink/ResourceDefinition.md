---
Template: Paclet
ResourceType: Paclet
Name: WolframInstitute/MathlibLink
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
Description: Connect Wolfram Language to mathlib for typed mathematics and checked proofs
ContributedBy: Wolfram Institute
Keywords: [Lean, mathlib, formal proof, exact arithmetic]
MainGuide: Documentation/English/Guides/MathlibLink.nb
License: MIT
WolframVersion: 15.0+
Categories: [Mathematics]
---

## Details & Options

- Explicit sessions expose mathlib's complete imported declaration namespace.
- Functions, theorems, structures and instances share a declaration interface.
- Exact supported values can be copied to Wolfram Language; other expressions remain typed Lean objects.
- Proof construction includes kernel replay and axiom checks.
- The external runtime pins Lean 4.35.0 and mathlib v4.35.0. Setup is explicit.
- Loading the paclet installs nothing.

## Usage

[StartMathlibSession]() opens a session. [MathlibCall]() applies a named
function, [MathlibDeclaration]() inspects a declaration, and [ProveMathlib]()
checks a theorem. [InstallMathlib]() prepares the external runtime.

## Basic Examples

Compute an exact binomial coefficient:

```wl
WithCleanup[session = StartMathlibSession[], MathlibCall[session, "Nat.choose", 10, 4], DeleteObject[session]]
```

Read a theorem from real analysis:

```wl
WithCleanup[session = StartMathlibSession[], MathlibDeclaration[session, "Real.exp_add"]["TypeForm"], DeleteObject[session]]
```
