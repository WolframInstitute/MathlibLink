---
Template: Symbol
Name: MathlibSession
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/MathlibSession
RelatedGuides: [MathlibLink]
SeeAlso: [StartMathlibSession, MathlibObject, MathlibNames]
RelatedTutorials: [GettingStarted]
---

## Usage

<code>[MathlibSession]()[*…*]</code> represents a mathlib session.

<!-- #| annotation: Session identifiers refer to resources in the current Wolfram kernel. They are not portable serialized runtimes. -->

## Details & Options

- Create a session with [StartMathlibSession]().
- `session["Status"]` gives the session state.
- `session["Directory"]` gives its runtime directory.
- `session["Imports"]` gives its selected Lean modules.
- `session["DeclarationCount"]` gives the number of available declarations.
- The expandable summary shows the session state and declaration count, with its imports and directory under the opener.
- [DeleteObject]() closes the session. Its retained [MathlibObject]() values then become unavailable.

## Basic Examples

Create a session:

```wl
session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Sqrt"}]
```

Inspect its state:

```wl
session["Status"]
```

Read its imports:

```wl
session["Imports"]
```

Count the declarations available through those imports:

```wl
session["DeclarationCount"]
```

Close the session:

```wl
DeleteObject[session]
```

## Scope

Create another session:

```wl
session = StartMathlibSession["Imports" -> {"Init"}]
```

Close it:

```wl
DeleteObject[session]
```

Inspect its final state:

```wl
session["Status"]
```
