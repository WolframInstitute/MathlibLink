---
Template: Symbol
Name: MathlibCall
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/MathlibCall
RelatedGuides: [MathlibLink]
SeeAlso: [MathlibEvaluate, MathlibExpression, MathlibObject]
RelatedTutorials: [GettingStarted, ArithmeticPatterns]
---

## Usage

<code>[MathlibCall]()[*session*, *name*, *arguments*]</code> applies a named Lean function to structured arguments.

<!-- #| annotation: This is a generic named application, analogous to PARICall. Lean elaborates implicit arguments and typeclass instances; MathlibExpression supplies explicit Lean syntax when inference needs additional information. -->

## Details & Options

- *name* is a Lean declaration name, including its namespace when needed.
- Supported arguments include exact integers, rationals, Boolean values, strings and lists.
- [MathlibExpression]() supplies an explicit Lean expression, such as a type annotation or function.
- A [MathlibObject]() argument must belong to the same session.
- Lean infers implicit arguments and typeclass instances. Some applications require an explicit type or hypothesis.
- Noncomputable results can be retained with "ReturnType" -> "Object".
- Approximate Wolfram values and unsupported symbolic expressions are not silently converted.
- The time limit for retained-object elaboration is best effort while native Lean code is running.

| | | |
| --- | --- | --- |
| TimeConstraint | 120 | time limit in seconds |
| "ReturnType" | Automatic | copied value or retained "Object" |

## Basic Examples

Compute a binomial coefficient:

```wl
WithCleanup[session = StartMathlibSession[], MathlibCall[session, "Nat.choose", 10, 4], DeleteObject[session]]
```

## Scope

Find a greatest common divisor:

```wl
WithCleanup[session = StartMathlibSession[], MathlibCall[session, "Nat.gcd", 84, 30], DeleteObject[session]]
```

Supply a typed function argument:

```wl
WithCleanup[session = StartMathlibSession[], MathlibCall[session, "List.map", MathlibExpression["fun n : Nat => n * n"], Range[0, 5]], DeleteObject[session]]
```

## Options

### ReturnType

Keep a real square root as a typed expression:

```wl
session = StartMathlibSession[]
```

Construct the retained expression:

```wl
root = MathlibCall[session, "Real.sqrt", MathlibExpression["(2 : Real)"], "ReturnType" -> "Object"]
```

Inspect the retained expression:

```wl
root["TermForm"]
```

Close the session:

```wl
DeleteObject[session]
```

### TimeConstraint

Use a five-minute budget:

```wl
WithCleanup[session = StartMathlibSession[], MathlibCall[session, "Nat.choose", 40, 20, TimeConstraint -> 300], DeleteObject[session]]
```

## Applications

Compare integer square roots computed by Lean and Wolfram Language:

```wl
WithCleanup[session = StartMathlibSession[], MathlibCall[session, "List.map", MathlibExpression["Nat.sqrt"], Range[0, 32]] === Floor[Sqrt[Range[0, 32]]], DeleteObject[session]]
```

For larger sweeps, send one list-producing Lean expression through
[MathlibEvaluate]() to avoid repeated cross-language evaluations.
