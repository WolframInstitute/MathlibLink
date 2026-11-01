---
Template: Symbol
Name: MathlibNames
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/MathlibNames
RelatedGuides: [MathlibLink]
SeeAlso: [MathlibDeclaration, StartMathlibSession]
RelatedTutorials: [GettingStarted]
---

## Usage

<code>[MathlibNames]()[*session*]</code> gives the declaration names in a session.

<code>[MathlibNames]()[*session*, *pattern*]</code> gives the names matching a string pattern.

<!-- #| annotation: Names are read from the loaded Lean environment, including generated declarations, rather than maintained as a bridge-specific catalog. -->

## Details & Options

- Patterns use wildcard strings such as "Nat.*" and "*sqrt*".
- Names include functions, theorem statements, structures, constructors and instances.
- A default session imports the whole mathlib library. A session with selected imports lists only that environment's declarations.
- Declaration names preserve their Lean namespaces and spelling. Generated internal names can appear in the inventory without being accessible as ordinary Lean source identifiers.

## Basic Examples

Find the declarations related to natural-number square roots:

```wl
WithCleanup[session = StartMathlibSession[], MathlibNames[session, "Nat.*sqrt*"], DeleteObject[session]]
```

## Scope

Look up an exact theorem name:

```wl
WithCleanup[session = StartMathlibSession[], MathlibNames[session, "Real.exp_add"], DeleteObject[session]]
```

Count all available declarations:

```wl
WithCleanup[session = StartMathlibSession[], Length[MathlibNames[session]], DeleteObject[session]]
```

## Applications

Compare the number of declarations in four namespaces:

```wl
WithCleanup[session = StartMathlibSession[], BarChart[Length[MathlibNames[session, # <> ".*"]] & /@ {"Nat", "Int", "Real", "Complex"}, ChartLabels -> {"Nat", "Int", "Real", "Complex"}, AxesLabel -> {"Namespace", "Declarations"}], DeleteObject[session]]
```

This counts declarations in the installed environment, including generated
ones. It does not measure mathematical depth or computational cost.
