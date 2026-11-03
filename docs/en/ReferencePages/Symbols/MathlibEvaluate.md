---
Template: Symbol
Name: MathlibEvaluate
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/MathlibEvaluate
RelatedGuides: [MathlibLink]
SeeAlso: [MathlibCall, MathlibExpression, MathlibObject, ProveMathlib]
RelatedTutorials: [ArithmeticPatterns, ValuesAndProofs, PartialComputations]
---

## Usage

<code>[MathlibEvaluate]()[*session*, *expression*]</code> evaluates a Lean expression given as a string.

<!-- #| annotation: Expression evaluation delegates to Lean and preserves the distinction between runtime computation and kernel proof checking. Explicit source strings are Lean code; returned text is never evaluated as Wolfram Language code. -->

## Details & Options

- Expressions use the namespaces and instances supplied by the session's imports.
- "ReturnType" -> Automatic copies values supported by Lean's JSON representation, including integers, Boolean values, strings, lists and arrays.
- "ReturnType" -> "Object" keeps a typed Lean expression as a [MathlibObject](). It also supports noncomputable definitions.
- Runtime evaluation is not a proof. Use [ProveMathlib]() for a checked theorem.
- Evaluation failures and time limits give [Failure]().
- "Isolated" -> True evaluates copied values in a separate Lean process, which is stopped on timeout or abort. It cannot be combined with "ReturnType" -> "Object".
- With "Isolated" -> False, compiled Lean code may continue after a timeout, and a native crash can terminate the Wolfram kernel. Isolation protects the kernel from such failures; it is not a sandbox.
- The time limit for retained-object elaboration is best effort while native Lean code is running.

| | | |
| --- | --- | --- |
| TimeConstraint | 120 | time limit in seconds |
| "ReturnType" | Automatic | copied value or retained "Object" |
| "Isolated" | False | evaluate copied values in a separate Lean process |

## Basic Examples

Compute exact squares in Lean:

```wl
WithCleanup[session = StartMathlibSession["Imports" -> {"Init"}], MathlibEvaluate[session, "(List.range 8).map (fun n => n * n)"], DeleteObject[session]]
```

## Scope

Evaluate an explicitly typed expression:

```wl
WithCleanup[session = StartMathlibSession["Imports" -> {"Init"}], MathlibEvaluate[session, "(7 : Int) - 12"], DeleteObject[session]]
```

## Options

### ReturnType

Retain a noncomputable real expression:

```wl
session = StartMathlibSession["Imports" -> {"Mathlib.Analysis.Real.Sqrt"}]
```

Construct the retained expression:

```wl
root = MathlibEvaluate[session, "Real.sqrt 2", "ReturnType" -> "Object"]
```

Read its type:

```wl
root["TypeForm"]
```

Close the session:

```wl
DeleteObject[session]
```

### Isolated

Evaluate in a separate Lean process:

```wl
WithCleanup[session = StartMathlibSession["Imports" -> {"Init"}], MathlibEvaluate[session, "(2 : Nat) ^ 100", "Isolated" -> True], DeleteObject[session]]
```

### TimeConstraint

Use a five-minute budget:

```wl
WithCleanup[session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Choose.Basic"}], MathlibEvaluate[session, "Nat.choose 40 20", TimeConstraint -> 300], DeleteObject[session]]
```

## Applications

Plot Euler's totient for integers 1 through 64:

```wl
WithCleanup[session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Totient"}], ListPlot[MathlibEvaluate[session, "(List.range 64).map (fun n => Nat.totient (n + 1))"], DataRange -> {1, 64}, AxesLabel -> {"n", "Totient"}], DeleteObject[session]]
```

---

Display Pascal's triangle modulo two:

```wl
WithCleanup[session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Choose.Basic"}], ArrayPlot[Reverse[MathlibEvaluate[session, "(List.range 32).map (fun n => (List.range 32).map (fun k => Nat.choose n k % 2))"]], DataRange -> {{0, 31}, {0, 31}}, FrameTicks -> Automatic, FrameLabel -> {"Row n", "Column k"}], DeleteObject[session]]
```
