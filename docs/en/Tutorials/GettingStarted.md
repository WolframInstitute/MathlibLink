---
Template: TechNote
Name: GettingStarted
Title: Getting Started with MathlibLink
Description: Import mathlib, inspect declarations and compute exact values
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/tutorial/GettingStarted
Keywords: [mathlib, Lean, imports, declarations]
RelatedGuides: [MathlibLink]
RelatedTutorials: [ArithmeticPatterns, ValuesAndProofs, PartialComputations]
---

## Import mathlib

Mathlib contains definitions and theorems in algebra, analysis, geometry,
number theory, topology and computability. MathlibLink prepares its runtime
and uses LeanLink to import declarations, evaluate expressions and check proofs.

Install the pinned runtime once if needed:

```wl
#| eval: false
InstallMathlib[]
```

Find the prepared project:

```wl
directory = MathlibInstallation[]["Directory"]
```

Import the modules used below:

```wl
session = StartMathlibSession["Directory" -> directory, "Imports" -> {"Mathlib.Data.Nat.Sqrt", "Mathlib.Data.Nat.Choose.Basic"}]
```

Selected imports reduce startup time and memory use. To explore the entire
library, use `"Imports" -> {"Mathlib"}` instead.

## Find and use a declaration

Find natural-number square-root declarations:

```wl
MathlibNames[session, "Nat.*sqrt*"]
```

Read the square-root function's type:

```wl
MathlibDeclaration[session, "Nat.sqrt"]["TypeForm"]
```

Compute the integer square root of 12345:

```wl
MathlibCall[session, "Nat.sqrt", 12345]
```

Compare with Wolfram Language:

```wl
Floor[Sqrt[12345]]
```

The session keeps the selected declarations available for later calls.
MathlibLink uses LeanLink for both named functions and Lean expressions.

## Compute a family of values

One Lean expression can return an entire list. Compute row ten of Pascal's
triangle:

```wl
row = MathlibEvaluate[session, "(List.range 11).map (fun k => Nat.choose 10 k)"]
```

Plot the exact values:

```wl
ListPlot[row, DataRange -> {0, 10}, AxesLabel -> {"k", "Binomial coefficient"}]
```

Batching related calculations reduces the number of transfers between the
two languages. It does not change the mathematical algorithm.

## Inspect a theorem

Read a theorem's statement without evaluating it:

```wl
MathlibDeclaration[session, "Nat.add_comm"]["TypeForm"]
```

[Values and proofs](paclet:WolframInstitute/MathlibLink/tutorial/ValuesAndProofs)
shows how to add and verify a theorem using the same session.

Close the session:

```wl
DeleteObject[session]
```

The installed runtime pins Lean 4.35.0 and mathlib v4.35.0. The
[upstream reference](https://leanprover-community.github.io/mathlib4_docs/)
tracks current mathlib and may describe a newer version.
