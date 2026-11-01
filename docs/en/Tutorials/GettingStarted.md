---
Template: TechNote
Name: GettingStarted
Title: Getting Started with MathlibLink
Description: Open a mathlib session, find declarations and compute exact values
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/tutorial/GettingStarted
Keywords: [mathlib, Lean, session, declarations]
RelatedGuides: [MathlibLink]
RelatedTutorials: [ArithmeticPatterns, ValuesAndProofs, PartialComputations]
---

## Open a session

Mathlib contains definitions and theorems in algebra, analysis, geometry,
number theory, topology and computability. MathlibLink uses one interface for
the entire imported namespace. A declaration does not need a separate
Wolfram wrapper before it can be inspected or used in a Lean expression.

Install the pinned runtime once, if it is not already present. Setup reuses
working Git, curl and elan installations and installs missing prerequisites in
user directories:

```wl
#| eval: false
InstallMathlib[]
```

Inspect the local installation:

```wl
MathlibInstallation[]
```

The result separates overall readiness from the discovered tools.
"Executables" gives the Elan, Lake, Git and Curl paths; "PathDirectories" gives
the runtime directories to prepend when starting a child process.

Open the full library:

```wl
session = StartMathlibSession[]
```

The default session exposes the whole library. For a focused computation,
"Imports" can select smaller modules to reduce startup time and memory use;
the following tutorials demonstrate this choice.

## Find a declaration

Search for natural-number square-root declarations:

```wl
MathlibNames[session, "Nat.*sqrt*"]
```

Inspect the square-root function:

```wl
squareRoot = MathlibDeclaration[session, "Nat.sqrt"]
```

Read its type:

```wl
squareRoot["TypeForm"]
```

Lean's `Nat` corresponds to exact nonnegative integers. Compute the integer
square root of 12345:

```wl
MathlibCall[session, "Nat.sqrt", 12345]
```

Compare the result with a Wolfram computation:

```wl
Floor[Sqrt[12345]]
```

## Inspect a theorem

The same declaration interface gives a theorem from real analysis:

```wl
exponentialLaw = MathlibDeclaration[session, "Real.exp_add"]
```

Read its quantified statement:

```wl
exponentialLaw["TypeForm"]
```

Find its upstream documentation:

```wl
Hyperlink["Exponential of a sum", exponentialLaw["DocumentationURL"]]
```

The installed runtime pins Lean 4.35.0 and mathlib v4.35.0. The linked
[upstream reference](https://leanprover-community.github.io/mathlib4_docs/)
tracks current mathlib; names or statements there can differ from the pinned
runtime. The declaration's type in the active session is the one used by
local computations and proofs.

## Compute a family of values

One Lean expression can produce an entire list. Compute binomial
coefficients along row ten of Pascal's triangle:

```wl
row = MathlibEvaluate[session, "(List.range 11).map (fun k => Nat.choose 10 k)"]
```

Plot the exact values:

```wl
ListPlot[row, DataRange -> {0, 10}, AxesLabel -> {"k", "Binomial coefficient"}]
```

Inspect the continuity-of-composition theorem from topology:

```wl
MathlibDeclaration[session, "Continuous.comp"]["TypeForm"]
```

The theorem remains accessible as a typed statement even though it is not a
list-producing numerical computation. [Values and proofs](paclet:WolframInstitute/MathlibLink/tutorial/ValuesAndProofs)
shows how these two uses fit together.

Close the session after its last use:

```wl
DeleteObject[session]
```
