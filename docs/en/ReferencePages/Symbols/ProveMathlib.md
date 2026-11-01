---
Template: Symbol
Name: ProveMathlib
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/ProveMathlib
RelatedGuides: [MathlibLink]
SeeAlso: [MathlibDeclaration, MathlibEvaluate, MathlibObject]
RelatedTutorials: [ValuesAndProofs]
---

## Usage

<code>[ProveMathlib]()[*session*, *statement*, *proof*]</code> checks a Lean proof of a statement and gives its retained theorem.

<!-- #| annotation: Successful elaboration alone is insufficient: Lean permits admitted declarations. This interface additionally replays the declaring module in the kernel and inspects the theorem's axiom dependencies. -->

## Details & Options

- *statement* and *proof* are Lean source strings.
- The result is a [MathlibObject]() containing a theorem only after the proof passes kernel replay and its axiom check.
- The permitted foundational axioms are `propext`, `Quot.sound` and `Classical.choice`. Admitted proofs using `sorry` and additional axioms are rejected.
- The session's imports supply theorem names, tactics and typeclass instances.
- A rejected proof or exhausted budget gives [Failure](). The time limit is best effort while native elaboration or kernel replay is running.
- A checked theorem concerns its stated Lean proposition. It does not automatically verify a separate Wolfram implementation.

| | | |
| --- | --- | --- |
| TimeConstraint | 120 | time limit in seconds |

## Basic Examples

Prove an identity for every natural number:

```wl
session = StartMathlibSession["Imports" -> {"Init"}]
```

Construct the theorem:

```wl
proof = ProveMathlib[session, "∀ n : Nat, n + 0 = n", "by intro n; rfl"]
```

Read the checked statement:

```wl
proof["TypeForm"]
```

Inspect its axiom dependencies:

```wl
proof["Axioms"]
```

Close the session:

```wl
DeleteObject[session]
```

## Scope

Import the exponential function and its theorems:

```wl
session = StartMathlibSession["Imports" -> {"Mathlib.Analysis.Complex.Exponential"}]
```

Check a real-analysis law using a theorem from mathlib:

```wl
ProveMathlib[session, "∀ x y : Real, Real.exp (x + y) = Real.exp x * Real.exp y", "by intro x y; exact Real.exp_add x y"]
```

Close the session:

```wl
DeleteObject[session]
```

## Options

### TimeConstraint

Set a five-minute proof budget:

```wl
session = StartMathlibSession["Imports" -> {"Init"}]
```

Check the proposition with the selected budget:

```wl
ProveMathlib[session, "(2 : Nat) + 2 = 4", "by decide", TimeConstraint -> 300]
```

Close the session:

```wl
DeleteObject[session]
```

## Possible Issues

An admitted statement does not produce a checked theorem:

```wl
WithCleanup[session = StartMathlibSession["Imports" -> {"Init"}], ProveMathlib[session, "False", "by sorry"], DeleteObject[session]]
```
