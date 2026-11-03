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

- MathlibLink prepares mathlib; LeanLink imports its complete declaration namespace.
- Functions, theorems, structures and instances share a declaration interface.
- Exact supported values can be copied to Wolfram Language; other expressions remain typed Lean objects.
- Proof construction includes kernel replay and axiom checks.
- The external runtime pins Lean 4.35.0 and mathlib v4.35.0. Setup is explicit.
- Loading the paclet installs nothing.

## Usage

[InstallMathlib]() prepares the runtime. [StartMathlibSession]() imports selected
modules through LeanLink. Use [MathlibEvaluate]() for expressions,
[MathlibCall]() for named functions and [ProveMathlib]() for checked proofs.

## Basic Examples

Import a focused mathlib module:

```wl
session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Choose.Basic"}]
```

Compute an exact binomial coefficient:

```wl
MathlibCall[session, "Nat.choose", 10, 4]
```

Read a theorem's type:

```wl
MathlibDeclaration[session, "Nat.add_comm"]["TypeForm"]
```

Close the session:

```wl
DeleteObject[session]
```
