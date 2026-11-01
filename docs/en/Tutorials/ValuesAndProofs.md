---
Template: TechNote
Name: ValuesAndProofs
Title: Values, Types and Checked Proofs
Description: Distinguish numerical evaluation, typed declarations and kernel-checked theorems
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/tutorial/ValuesAndProofs
Keywords: [Lean, types, kernel, proof, noncomputable]
RelatedGuides: [MathlibLink]
RelatedTutorials: [GettingStarted, ArithmeticPatterns, PartialComputations]
---

## A computation and a theorem

A numerical expression computes a value for its supplied inputs. A theorem
states a proposition and provides a proof term that Lean's kernel can check.
The distinction matters when moving from a tested example to a claim about
all inputs.

Open a session:

```wl
session = StartMathlibSession[]
```

Evaluate one natural-number identity:

```wl
MathlibEvaluate[session, "decide ((4 + 1)^2 = (4 : Nat)^2 + 2*4 + 1)"]
```

Prove the polynomial identity for every integer:

```wl
identity = ProveMathlib[session, "∀ x : Int, (x + 1)^2 = x^2 + 2*x + 1", "by intro x; ring"]
```

Read the theorem's complete type:

```wl
identity["TypeForm"]
```

Inspect its axiom dependencies:

```wl
identity["Axioms"]
```

[ProveMathlib]() accepts the theorem after kernel replay and checks its axiom
dependencies. The proof concerns the stated Lean proposition. It does not by
itself establish the correctness of a separate Wolfram implementation.

## Typed expressions without numerical evaluation

Mathlib's real numbers support exact mathematical reasoning. Many definitions
involving them are noncomputable: they are well-typed mathematical objects
without an executable numerical implementation through Lean's evaluator.
Retain the exact real square root of two:

```wl
root = MathlibEvaluate[session, "Real.sqrt 2", "ReturnType" -> "Object"]
```

Read its type:

```wl
root["TypeForm"]
```

Inspect its defining expression:

```wl
root["TermForm"]
```

Keeping the term does not replace it with a machine-precision approximation.
A declaration can still participate in a checked proof:

```wl
rootIdentity = ProveMathlib[session, "(Real.sqrt 2)^2 = 2", "by norm_num"]
```

## Generic mathematical hypotheses

The theorem `mul_comm` applies to a type equipped with the required
commutative multiplication structure. Its Lean type states those assumptions:

```wl
MathlibDeclaration[session, "mul_comm"]["TypeForm"]
```

Lean infers many implicit arguments and typeclass instances when a theorem is
used. Type annotations make a concrete instance explicit. Prove a law over
real numbers using an existing mathlib theorem:

```wl
exponentialLaw = ProveMathlib[session, "∀ x y : Real, Real.exp (x + y) = Real.exp x * Real.exp y", "by intro x y; exact Real.exp_add x y"]
```

Read the resulting statement:

```wl
exponentialLaw["TypeForm"]
```

## Rejected admissions

Lean source can contain `sorry`, which admits a proposition without supplying
a proof. The proof interface rejects such a result:

```wl
ProveMathlib[session, "False", "by sorry"]
```

A timeout is also a failed observation, not evidence that the proposition is
false. It may require a different proof or a larger resource budget.

Close the session:

```wl
DeleteObject[session]
```
