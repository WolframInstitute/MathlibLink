---
Template: Symbol
Name: MathlibObject
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/MathlibObject
RelatedGuides: [MathlibLink]
SeeAlso: [MathlibDeclaration, MathlibEvaluate, ProveMathlib, MathlibSession]
RelatedTutorials: [ValuesAndProofs]
---

## Usage

<code>[MathlibObject]()[*…*]</code> represents a typed Lean declaration or expression retained by a session.

<!-- #| annotation: Session ownership follows PARIObject. Lean expression structure is preserved for terms without a lossless Wolfram value representation; display strings are never reparsed as Wolfram code. -->

## Details & Options

- [MathlibDeclaration](), [ProveMathlib]() and evaluation with "ReturnType" -> "Object" create these objects.
- Properties include "Name", "Kind", "Type", "TypeForm", "Term", "TermForm", "Axioms", "KernelCheck", "Module" and "DocumentationURL".
- "TypeForm" and "TermForm" use Lean's printer. "Type" and "Term" preserve the Lean expression structure.
- "Verified" is True for a theorem produced by [ProveMathlib](). Inspecting a declaration alone does not perform a new proof check.
- [Normal]() gives the underlying LeanLink term.
- The object belongs to its originating session and cannot be passed to another session.
- Closing the session invalidates its objects.

## Basic Examples

Retain an exact real expression:

```wl
session = StartMathlibSession[]
```

Construct the retained expression:

```wl
root = MathlibEvaluate[session, "Real.sqrt 2", "ReturnType" -> "Object"]
```

Inspect its type:

```wl
root["TypeForm"]
```

Inspect its defining term:

```wl
root["TermForm"]
```

Close the session:

```wl
DeleteObject[session]
```

## Scope

Inspect a theorem's originating module:

```wl
WithCleanup[session = StartMathlibSession[], MathlibDeclaration[session, "Real.exp_add"]["Module"], DeleteObject[session]]
```

## Properties and Relations

Use a retained natural number in another expression:

```wl
session = StartMathlibSession[]
```

Retain a typed natural number:

```wl
value = MathlibEvaluate[session, "(12 : Nat)", "ReturnType" -> "Object"]
```

Compute its successor in the same session:

```wl
MathlibCall[session, "Nat.succ", value]
```

Close the session:

```wl
DeleteObject[session]
```
