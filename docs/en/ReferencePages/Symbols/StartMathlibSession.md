---
Template: Symbol
Name: StartMathlibSession
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/StartMathlibSession
RelatedGuides: [MathlibLink]
SeeAlso: [MathlibSession, MathlibCall, MathlibDeclaration, InstallMathlib]
RelatedTutorials: [GettingStarted, ValuesAndProofs]
---

## Usage

<code>[StartMathlibSession]()[]</code> opens a session over the installed mathlib library.

<!-- #| annotation: Sessions follow PARILink's explicit resource ownership. The default import covers Mathlib as a whole; selected imports reduce loading cost without introducing a function whitelist. -->

## Details & Options

- The result is a [MathlibSession]() object.
- The default import is "Mathlib", exposing the full imported declaration namespace.
- "Imports" selects smaller Lean modules and their dependencies, reducing startup time and memory use.
- With LeanLink's environment evaluator, new imports prepare evaluation while loading the modules.
- Setup must be completed with [InstallMathlib]() before opening a session.
- [DeleteObject]() closes a session and invalidates its retained objects. Imported modules remain cached until the kernel exits.
- A failure to open the selected runtime gives [Failure]().

| | | |
| --- | --- | --- |
| "Directory" | Automatic | installed runtime to use |
| "Imports" | {"Mathlib"} | Lean modules available in the session |

## Basic Examples

Open a session:

```wl
session = StartMathlibSession[]
```

Compute a binomial coefficient:

```wl
MathlibCall[session, "Nat.choose", 10, 4]
```

Close the session:

```wl
DeleteObject[session]
```

## Options

### Imports

Open only the integer square-root module and its dependencies:

```wl
session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Sqrt"}]
```

Compute an integer square root:

```wl
MathlibCall[session, "Nat.sqrt", 12345]
```

Close the session:

```wl
DeleteObject[session]
```

### Directory

Use the default runtime directory explicitly:

```wl
WithCleanup[session = StartMathlibSession["Directory" -> MathlibInstallation[]["Directory"], "Imports" -> {"Init"}], session["Status"], DeleteObject[session]]
```
