# MathlibLink

[![CI](https://github.com/WolframInstitute/MathlibLink/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/WolframInstitute/MathlibLink/actions/workflows/ci.yml)
[![Release](https://github.com/WolframInstitute/MathlibLink/actions/workflows/release.yml/badge.svg)](https://github.com/WolframInstitute/MathlibLink/actions/workflows/release.yml)
[![Publish](https://github.com/WolframInstitute/MathlibLink/actions/workflows/publish.yml/badge.svg)](https://github.com/WolframInstitute/MathlibLink/actions/workflows/publish.yml)

MathlibLink connects Wolfram Language to [mathlib](https://leanprover-community.github.io/mathlib4_docs/),
Lean's mathematics library. It provides declaration lookup, typed objects,
exact computations and checked proofs through explicit sessions.

Requires Wolfram Language 15.0 or later.

## Get started

Load the source paclet from this repository:

```wl
PacletDirectoryLoad[FileNameJoin[{Directory[], "MathlibLink"}]]
Needs["WolframInstitute`MathlibLink`"]
```

Prepare the pinned runtime once. Missing prerequisites are installed locally:

```wl
InstallMathlib[]
```

Setup reuses working Git, curl and elan installations. See
[InstallMathlib](docs/en/ReferencePages/Symbols/InstallMathlib.md) for setup
options and progress reporting.

Open a session and compute a binomial coefficient:

```wl
session = StartMathlibSession[]
MathlibCall[session, "Nat.choose", 10, 4]
```

Inspect a theorem:

```wl
MathlibDeclaration[session, "mul_comm"]["TypeForm"]
```

Prove an identity:

```wl
proof = ProveMathlib[session, "∀ n : Nat, n + 0 = n", "by intro n; rfl"]
```

Close the session:

```wl
DeleteObject[session]
```

## Coverage

The default session imports `Mathlib` and exposes its complete declaration
namespace. Functions, theorems, structures and instances use the same lookup
interface. There is no hand-maintained list of supported function names.
Use `MathlibNames[session, "Nat.*"]` to browse names and
`MathlibDeclaration[session, name]` to inspect a declaration.
The [coverage report](docs/coverage.md) records the complete namespace check
and live verification results.

Computable expressions can produce Wolfram values. Noncomputable definitions
and proofs remain typed Lean objects. A finite computation and a
kernel-checked theorem establish different things; see
[values and proofs](docs/en/Tutorials/ValuesAndProofs.md).

## Documentation

- [Getting started](docs/en/Tutorials/GettingStarted.md)
- [Exact arithmetic patterns](docs/en/Tutorials/ArithmeticPatterns.md)
- [Partial computations](docs/en/Tutorials/PartialComputations.md)
- [Function guide](docs/en/Guides/MathlibLink.md)
- [Upstream mathlib documentation](https://leanprover-community.github.io/mathlib4_docs/)

The runtime pins Lean 4.35.0 and mathlib v4.35.0. The upstream documentation
tracks current mathlib and may describe a newer release.

## Development

| Command | Purpose |
| --- | --- |
| `make check` | Check sources and reference coverage |
| `make test` | Run local tests |
| `make test-mathlib` | Run tests against mathlib |
| `make notebooks` | Build documentation with PacletPage |
| `make check-publish` | Build and check the paclet archive |
| `make publish` | Publish the paclet and documentation |

See [GUIDE.md](GUIDE.md) for development conventions and
[CI and releases](docs/workflows.md) for the three-platform workflow and publishing setup.
