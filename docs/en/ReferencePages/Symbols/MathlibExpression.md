---
Template: Symbol
Name: MathlibExpression
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/MathlibExpression
RelatedGuides: [MathlibLink]
SeeAlso: [MathlibCall, MathlibEvaluate]
RelatedTutorials: [ValuesAndProofs]
---

## Usage

<code>[MathlibExpression]()[*source*]</code> represents explicit Lean source for a structured function argument.

<!-- #| annotation: Strings ordinarily denote Lean string data. This separate head makes the distinction between data and explicitly requested Lean code visible in the Wolfram expression. -->

## Details & Options

- *source* is a Lean expression string.
- Use this form for type annotations, functions, hypotheses or values without an automatic Wolfram conversion.
- Constructing this expression does not run Lean. It is elaborated when used by [MathlibCall]().
- An ordinary Wolfram string argument remains string data.

## Basic Examples

Represent a typed Lean expression:

```wl
MathlibExpression["(2 : Real)"]
```

## Scope

Supply a function to a list operation:

```wl
WithCleanup[session = StartMathlibSession["Imports" -> {"Init"}], MathlibCall[session, "List.map", MathlibExpression["fun n : Nat => n + 1"], {2, 4, 8}], DeleteObject[session]]
```

## Properties and Relations

Pass ordinary text as data:

```wl
WithCleanup[session = StartMathlibSession["Imports" -> {"Init"}], MathlibCall[session, "String.length", "Nat.sqrt 16"], DeleteObject[session]]
```
