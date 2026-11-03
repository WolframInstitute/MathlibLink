---
Template: Symbol
Name: MathlibInstallation
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/ref/MathlibInstallation
RelatedGuides: [MathlibLink]
SeeAlso: [InstallMathlib, StartMathlibSession]
RelatedTutorials: [GettingStarted]
---

## Usage

<code>[MathlibInstallation]()[]</code> gives the status and version information of the default runtime.

<code>[MathlibInstallation]()["Directory" -> *directory*]</code> checks a specified runtime directory.

<!-- #| annotation: Installation information is a local readiness check. It must not download a toolchain or conflate the existence of a directory with a usable mathlib build. -->

## Details & Options

- The result includes "Status", "Directory", "Toolchain", "Revision", "LeanLinkVersion", "DocumentationURL", "Executables" and "PathDirectories".
- "Status" is "Ready", "Needs setup" or "Not installed". Readiness checks the pinned checkout, built library and compatible LeanLink runtime.
- "Executables" is an association with "Elan", "Lake", "Git" and "Curl" keys. Each value is an absolute executable path or Missing if no executable was found.
- "PathDirectories" lists existing runtime directories needed by child processes, including the helper and library directories of managed Git and curl installations. Prepend them to the child process's PATH when using these tools outside MathlibLink.
- Discovered executable paths alone do not establish that the complete runtime is ready.
- The revision identifies the mathlib source used by the runtime.
- The documentation link points to the upstream site, which may describe a newer version.
- Checking an installation does not install or update software.

| | | |
| --- | --- | --- |
| "Directory" | Automatic | runtime directory to inspect |

## Basic Examples

Inspect the runtime:

```wl
MathlibInstallation[]
```

Read its pinned toolchain:

```wl
MathlibInstallation[]["Toolchain"]
```

## Options

### Directory

Inspect an explicitly selected directory:

```wl
MathlibInstallation["Directory" -> FileNameJoin[{$UserBaseDirectory, "MathlibRuntime"}]]
```

## Applications

Open the upstream reference index:

```wl
Hyperlink["mathlib documentation", MathlibInstallation[]["DocumentationURL"]]
```
