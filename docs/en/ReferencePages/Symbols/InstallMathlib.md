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
- Setup reuses working elan and Git installations, or prepares them locally. It installs the compatible LeanLink release when needed, downloads the mathlib build cache and checks the resulting installation.
- The automatic installers and Git packages are pinned by version and SHA256 checksum. They require no system package manager or administrator access.
- Elan uses ELAN_HOME when set, otherwise the user's .elan directory. A private Git runtime lives under Wolfram's user application-data directory.
- The complete mathlib import is installed, including declarations outside the examples in this paclet.
- Installation does not change shell profiles, the process PATH or elan's global default toolchain.
- Loading MathlibLink and checking [MathlibInstallation]() do not install software.
- A failed installation gives [Failure]() with diagnostic information.
- ProgressFunction receives a stage string and a download fraction. The fraction is None when the operation does not report a total.
- CancellationFunction is polled during downloads and owned external processes. Returning True stops them and gives Failure["MathlibInstallCancelled", ...]. Incomplete files and a new clone are removed; verified downloads and an existing checkout are kept for retry.
- Paclet installation and native readiness checks finish their current operation before observing cancellation. An abort also cleans up the owned external process.

| | | |
| --- | --- | --- |
| "Directory" | Automatic | location of the pinned runtime |
| "ProgressFunction" | Null & | function called with the stage and fraction |
| "CancellationFunction" | False & | function returning whether setup should stop |

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

### ProgressFunction

Report installation stages:

```wl
#| eval: false
InstallMathlib["ProgressFunction" -> Function[{stage, fraction}, Print[stage]]]
```

### CancellationFunction

Stop before any installation starts:

```wl
InstallMathlib["CancellationFunction" -> (True &)]
```

## Possible Issues

The mathlib build cache is a substantial download. Setup reports unavailable
platform installers and failed downloads through its result. Inspect that
result before opening a session.
