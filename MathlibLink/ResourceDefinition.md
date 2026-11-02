---
Template: Paclet
ResourceType: Paclet
Name: WolframInstitute/MathlibLink
Context: WolframInstitute`MathlibLink`
ContextPath: [Wolfram`LeanLink`]
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

[InstallMathlib]() prepares the runtime and [MathlibInstallation]() gives its
project directory. Import that project with [LeanImport](paclet:Wolfram/LeanLink/ref/LeanImport),
evaluate with [LeanEvaluate](paclet:Wolfram/LeanLink/ref/LeanEvaluate) and verify
theorems with [LeanVerify](paclet:Wolfram/LeanLink/ref/LeanVerify).
The environment interface requires the accompanying LeanLink development branch;
existing MathlibLink session APIs remain supported.

## Basic Examples

Import a focused mathlib module:

```wl
env = LeanImport["Mathlib.Data.Nat.Choose.Basic", "ProjectDir" -> MathlibInstallation[]["Directory"]]
```

Compute an exact binomial coefficient:

```wl
LeanEvaluate[env["Nat.choose"], 10, 4]
```

Read a theorem's type:

```wl
env["Nat.add_comm"]["TypeForm"]
```

Release the environment:

```wl
LeanFreeEnvironment[env]
```
