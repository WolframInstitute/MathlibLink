---
Template: Symbol
Name: MathlibDeclaration
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/MathlibDeclaration
RelatedGuides: [MathlibLink]
SeeAlso: [MathlibNames, MathlibObject, ProveMathlib]
RelatedTutorials: [GettingStarted, ValuesAndProofs, PartialComputations]
---

## Usage

<code>[MathlibDeclaration]()[*session*, *name*]</code> gives the Lean declaration with the specified name.

<!-- #| annotation: A declaration remains a typed Lean object. The bridge does not generate a Wolfram wrapper per declaration or convert a proposition into a Boolean computation. -->

## Details & Options

- The result is a [MathlibObject]() owned by the session.
- The same interface accesses definitions, theorems, structures, constructors and instances.
- Properties include "Name", "Kind", "TypeForm", "TermForm", "Axioms", "KernelCheck", "Module" and "DocumentationURL".
- "Type" and "Term" preserve Lean's expression structure. "TypeForm" and "TermForm" give Lean's printed form.
- Declarations are available even when they are noncomputable or have no numerical value.
- Documentation links refer to the upstream module and declaration. The live site may describe a newer mathlib version.

## Basic Examples

Open a session:

```wl
session = StartMathlibSession[]
```

Inspect commutativity of multiplication:

```wl
declaration = MathlibDeclaration[session, "mul_comm"]
```

Read the theorem's hypotheses and conclusion:

```wl
declaration["TypeForm"]
```

Close the session:

```wl
DeleteObject[session]
```

## Scope

Inspect a theorem from real analysis:

```wl
WithCleanup[session = StartMathlibSession[], MathlibDeclaration[session, "Real.exp_add"]["TypeForm"], DeleteObject[session]]
```

Inspect continuity of composition:

```wl
WithCleanup[session = StartMathlibSession[], MathlibDeclaration[session, "Continuous.comp"]["TypeForm"], DeleteObject[session]]
```

Inspect the representation theorem for partial recursive functions:

```wl
WithCleanup[session = StartMathlibSession[], MathlibDeclaration[session, "Nat.Partrec.Code.exists_code"]["TypeForm"], DeleteObject[session]]
```

## Applications

Find the upstream page for a theorem:

```wl
WithCleanup[session = StartMathlibSession[], Hyperlink["Exponential of a sum", MathlibDeclaration[session, "Real.exp_add"]["DocumentationURL"]], DeleteObject[session]]
```

## Properties and Relations

Inspect the axioms used by the natural-number addition theorem:

```wl
WithCleanup[session = StartMathlibSession[], MathlibDeclaration[session, "Nat.add_comm"]["Axioms"], DeleteObject[session]]
```
