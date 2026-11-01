---
Template: Symbol
Name: InstallMathlib
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/InstallMathlib
RelatedGuides: [MathlibLink]
SeeAlso: [MathlibInstallation, StartMathlibSession]
RelatedTutorials: [GettingStarted]
---

## Usage

<code>[InstallMathlib]()[]</code> installs the pinned mathlib runtime.

<code>[InstallMathlib]()["Directory" -> *directory*]</code> installs it in a specified directory.

<!-- #| annotation: Runtime setup is explicit, following PARILink's separation between loading a paclet and preparing its external runtime. Mathlib is versioned with Lean because compiled modules are toolchain-specific. -->

## Details & Options

- The runtime pins Lean 4.35.0 and mathlib commit `56a005855ea17e0b0958f73ec801ae140b0a1679`, corresponding to v4.35.0.
- Setup uses elan and Git, installs the compatible LeanLink release when needed, downloads the mathlib build cache and checks the resulting installation.
- The complete mathlib import is installed, including declarations outside the examples in this paclet.
- Installation does not change elan's global default toolchain.
- Loading MathlibLink and checking [MathlibInstallation]() do not install software.
- A failed installation gives [Failure]() with diagnostic information.

| | | |
| --- | --- | --- |
| "Directory" | Automatic | location of the pinned runtime |

## Basic Examples

Install the runtime once:

```wl
#| eval: false
InstallMathlib[]
```

Inspect the installation status:

```wl
MathlibInstallation[]
```

## Options

### Directory

Choose a directory for the runtime:

```wl
#| eval: false
InstallMathlib["Directory" -> FileNameJoin[{$UserBaseDirectory, "MathlibRuntime"}]]
```

## Possible Issues

The mathlib build cache is a substantial download. Setup reports missing tools
and failed downloads through its result. Inspect that result before opening a
session.
