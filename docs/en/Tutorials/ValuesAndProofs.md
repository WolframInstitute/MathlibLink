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

Import the ring tactic for this identity:

```wl
session = StartMathlibSession["Imports" -> {"Mathlib.Tactic.Ring"}]
```

Evaluate one natural-number identity:

```wl
MathlibEvaluate[session, "decide ((4 + 1)^2 = (4 : Nat)^2 + 2*4 + 1)"]
```

Prove the polynomial identity for every integer:

```wl
identity = ProveMathlib[session, "forall x : Int, (x + 1)^2 = x^2 + 2*x + 1", "by intro x; ring"]
```

Confirm that the proof passed kernel and axiom checks:

```wl
identity["Verified"]
```

Read the theorem's complete type:

```wl
identity["TypeForm"]
```

Inspect its axiom dependencies:

```wl
identity["Axioms"]
```

[ProveMathlib](paclet:WolframInstitute/MathlibLink/ref/ProveMathlib)
checks the theorem in Lean's kernel and audits its axiom dependencies. The
proof concerns the stated Lean proposition. It does not by itself establish the correctness of a separate Wolfram implementation.

The theorem `mul_comm` applies to a type with commutative multiplication.
Inspect the type to see its algebraic assumptions:

```wl
MathlibDeclaration[session, "mul_comm"]["TypeForm"]
```

Close the session:

```wl
DeleteObject[session]
```

## Typed expressions without numerical evaluation

Mathlib's real numbers support exact mathematical reasoning. Many definitions
involving them are noncomputable: they are well-typed mathematical objects
without an executable numerical implementation through Lean's evaluator.
Import real square roots:

```wl
session = StartMathlibSession["Imports" -> {"Mathlib.Analysis.Real.Sqrt"}]
```

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
Inspect mathlib's theorem for the square of a real square root:

```wl
rootIdentity = MathlibDeclaration[session, "Real.sq_sqrt"]
```

Read its nonnegativity hypothesis and conclusion:

```wl
rootIdentity["TypeForm"]
```

Close the square-root session:

```wl
DeleteObject[session]
```

Lean uses a theorem's type to infer its implicit arguments and typeclass
instances. Existing mathlib theorems can be used in proofs passed to
[ProveMathlib](paclet:WolframInstitute/MathlibLink/ref/ProveMathlib).

## Rejected admissions

Lean's core module suffices for this example:

```wl
session = StartMathlibSession["Imports" -> {"Init"}]
```

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
