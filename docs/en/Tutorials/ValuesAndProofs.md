---
Template: TechNote
Name: ValuesAndProofs
Title: Values, Types and Checked Proofs
Description: Distinguish numerical evaluation, typed declarations and kernel-checked theorems
Context: WolframInstitute`MathlibLink`
ContextPath: [Wolfram`LeanLink`]
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
env = LeanImport["ProjectDir" -> MathlibInstallation[]["Directory"], "Imports" -> {"Mathlib.Tactic.Ring"}]
```

Evaluate one natural-number identity:

```wl
LeanEvaluate[env, "decide ((4 + 1)^2 = (4 : Nat)^2 + 2*4 + 1)"]
```

Prove the polynomial identity for every integer:

```wl
proofs = LeanImportString[env, "theorem squareIdentity (x : Int) : (x + 1)^2 = x^2 + 2*x + 1 := by ring"]
```

Check the theorem in Lean's kernel and audit its axiom dependencies:

```wl
LeanVerify[proofs["squareIdentity"]]
```

Read the theorem's complete type:

```wl
proofs["squareIdentity"]["TypeForm"]
```

Inspect its axiom dependencies:

```wl
proofs["squareIdentity"]["Axioms"]
```

[LeanVerify](paclet:Wolfram/LeanLink/ref/LeanVerify) accepts the theorem after kernel replay and checks its axiom
dependencies. The proof concerns the stated Lean proposition. It does not by
itself establish the correctness of a separate Wolfram implementation.

The theorem `mul_comm` applies to a type with commutative multiplication.
Inspect the type to see its algebraic assumptions:

```wl
env["mul_comm"]["TypeForm"]
```

Release these environments:

```wl
Scan[LeanFreeEnvironment, {proofs, env}]
```

## Typed expressions without numerical evaluation

Mathlib's real numbers support exact mathematical reasoning. Many definitions
involving them are noncomputable: they are well-typed mathematical objects
without an executable numerical implementation through Lean's evaluator.
Import real square roots:

```wl
env = LeanImport["ProjectDir" -> MathlibInstallation[]["Directory"], "Imports" -> {"Mathlib.Analysis.Real.Sqrt"}]
```

Retain the exact real square root of two:

```wl
roots = LeanImportString[env, "noncomputable def root : Real := Real.sqrt 2"]
```

Read its type:

```wl
roots["root"]["TypeForm"]
```

Inspect its defining expression:

```wl
roots["root"]["TermForm"]
```

Keeping the term does not replace it with a machine-precision approximation.
Inspect mathlib's theorem for the square of a real square root:

```wl
rootIdentity = env["Real.sq_sqrt"]
```

Read its nonnegativity hypothesis and conclusion:

```wl
rootIdentity["TypeForm"]
```

Release the square-root environments:

```wl
Scan[LeanFreeEnvironment, {roots, env}]
```

Lean uses a theorem's type to infer its implicit arguments and typeclass
instances. Existing mathlib theorems can be used in the source passed to
[LeanImportString](paclet:Wolfram/LeanLink/ref/LeanImportString).

## Rejected admissions

Lean's core module suffices for this example:

```wl
env = LeanImport["ProjectDir" -> MathlibInstallation[]["Directory"], "Imports" -> {"Init"}]
```

Lean source can contain `sorry`, which admits a proposition without supplying
a proof. The proof interface rejects such a result:

```wl
admitted = LeanImportString[env, "theorem admitted : False := by sorry"]
```

```wl
LeanVerify[admitted["admitted"]]
```

A timeout is also a failed observation, not evidence that the proposition is
false. It may require a different proof or a larger resource budget.

Release these environments:

```wl
Scan[LeanFreeEnvironment, {admitted, env}]
```
