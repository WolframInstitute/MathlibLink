# MathlibLink

[![CI](https://github.com/WolframInstitute/MathlibLink/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/WolframInstitute/MathlibLink/actions/workflows/ci.yml)
[![Release](https://github.com/WolframInstitute/MathlibLink/actions/workflows/release.yml/badge.svg)](https://github.com/WolframInstitute/MathlibLink/actions/workflows/release.yml)

MathlibLink connects Wolfram Language to [mathlib](https://leanprover-community.github.io/mathlib4_docs/),
Lean's mathematics library. MathlibLink prepares the runtime; LeanLink imports
its declarations, evaluates expressions and checks proofs.

Requires Wolfram Language 15.0 or later.

[Documentation](https://www.wolframcloud.com/obj/wolframinstitute/MathlibLink/) ·
[Wolfram resource](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/MathlibLink/) ·
[Releases](https://github.com/WolframInstitute/MathlibLink/releases)

## Get started

Install and load the paclet:

```wl
PacletInstall[ResourceObject["https://wolfr.am/1IuI3kKSs"]]
```

```wl
Needs["WolframInstitute`MathlibLink`"]
```

Prepare the pinned runtime once. Missing prerequisites are installed locally:

```wl
InstallMathlib[]
```

Setup reuses working Git, curl and elan installations. See
[InstallMathlib](https://www.wolframcloud.com/obj/wolframinstitute/MathlibLink/#ref/InstallMathlib) for setup
options and progress reporting.

The environment interface below requires the accompanying LeanLink
`feature/environment-evaluation` branch until its next release. Existing
`StartMathlibSession`, `MathlibCall` and `ProveMathlib` calls remain supported.

Load LeanLink:

```wl
Needs["Wolfram`LeanLink`"]
```

Import the binomial-coefficient module from the installed mathlib project:

```wl
env = LeanImport["Mathlib.Data.Nat.Choose.Basic", "ProjectDir" -> MathlibInstallation[]["Directory"], "PrepareEvaluation" -> True]
```

Apply an imported function:

```wl
LeanEvaluate[env["Nat.choose"], 10, 4]
```

Evaluate a family of inputs in one call:

```wl
LeanEvaluate[env, "(List.range 11).map (fun k => Nat.choose 10 k)"]
```

`"PrepareEvaluation" -> True` prepares the evaluator while importing modules.
Later calls reuse it; `Needs` alone starts no Lean process.
Batching inputs also reduces transfers between Wolfram Language and Lean.

Compile a theorem using the same imports:

```wl
proofs = LeanImportString[env, "theorem addZero (n : Nat) : n + 0 = n := by rfl"]
```

Check its proof and axiom dependencies:

```wl
LeanVerify[proofs["addZero"]]
```

Release the environments when finished:

```wl
Scan[LeanFreeEnvironment, {proofs, env}]
```

## Coverage

Use `LeanImport["Mathlib", "ProjectDir" -> directory]` for the full library,
or select modules to reduce startup time and memory use. `Keys[env]` lists
names; `env[name]` returns a Lean term whose type, definition and axioms can
be inspected. No function whitelist or separate mathlib evaluator is needed.

Computable expressions can produce Wolfram values. Noncomputable definitions
and proofs remain typed Lean terms. See [values and proofs](docs/en/Tutorials/ValuesAndProofs.md)
for examples, and the [coverage report](docs/coverage.md) for namespace and
live verification results.

## Documentation

- [Getting started](https://www.wolframcloud.com/obj/wolframinstitute/MathlibLink/#tutorial/GettingStarted)
- [Exact arithmetic patterns](https://www.wolframcloud.com/obj/wolframinstitute/MathlibLink/#tutorial/ArithmeticPatterns)
- [Partial computations](https://www.wolframcloud.com/obj/wolframinstitute/MathlibLink/#tutorial/PartialComputations)
- [Function guide](https://www.wolframcloud.com/obj/wolframinstitute/MathlibLink/#guide/MathlibLink)
- [Upstream mathlib documentation](https://leanprover-community.github.io/mathlib4_docs/)

The runtime pins Lean 4.35.0 and mathlib v4.35.0. The upstream documentation
tracks current mathlib and may describe a newer release.

## Development

Load the source paclet from this repository:

```wl
PacletDirectoryLoad[FileNameJoin[{Directory[], "MathlibLink"}]]
Needs["WolframInstitute`MathlibLink`"]
```

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
