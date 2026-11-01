# Coverage and verification

Checked on 2026-11-01 with Wolfram Language 15.0 on macOS ARM64,
LeanLink 1.2.5, Lean 4.35.0 and mathlib commit
`56a005855ea17e0b0958f73ec801ae140b0a1679` (v4.35.0).

## Namespace coverage

A default session imports `Mathlib`. The imported environment contains
797,294 declaration names, including Lean, dependency and generated declarations.
The integration test compares the complete sorted result of `MathlibNames`
with LeanLink's native environment inventory, including internal names. The
sets are equal. This is a count of declarations, not a count of numerical
functions.

`MathlibCall` accepts a declaration name from that environment and builds a
Lean application. Lean resolves its types, implicit arguments and typeclass
instances. There is no per-function wrapper list or domain whitelist.
`MathlibExpression` supplies Lean syntax where structured values are not
sufficient. `MathlibEvaluate` accepts arbitrary Lean expressions.

Declarations that are noncomputable, proof-valued or lack a JSON conversion
remain available as typed `MathlibObject` values. Internal compiler artifacts
can have names that Lean's source parser or the native bridge cannot resolve
again from text; listing them does not make them public callable functions.
The official documentation website follows development, while local types
and source modules come from the pinned release.

## Live checks

The 22 integration checks cover:

- Exact equality of the complete imported namespace.
- Generic calls to `Nat.choose`, `Nat.sqrt`, `Nat.totient`, `Int.natAbs`
  and `List.reverse`.
- Exact transfer of `2^100` and Unicode, quoting and control characters.
- Evaluation of `Nat.Partrec.Code.evaln`.
- Typed declarations from algebra, analysis, topology and computability:
  `mul_comm`, `Real.exp_add`, `Continuous.comp` and
  `Nat.Partrec.Code.exists_code`.
- Links to the declaring modules in the official mathlib documentation.
- A universal natural-number theorem accepted by Lean's kernel.
- Rejection of `sorry`, a false theorem and a `native_decide` proof whose
  compiler-backed trust is outside this interface's accepted proof basis.
- Retaining a noncomputable function with its Lean type.
- Session ownership, independent closure of shared imports and timeout cleanup.

The separate local tests cover installation metadata, exact argument encoding,
option validation, unavailable objects, closure, interruption and timeout paths.
All 59 local tests pass on macOS ARM64, including rejection of modified tracked mathlib sources,
preserved caller contexts and selection of private or existing curl ahead of an
older copy beside Git. All 22 live checks pass in six fresh Wolfram processes.
The complete default namespace, a default-session call and a default-session
checked theorem remain covered. Negative proof checks require the specific
rejection and a usable session, so a timeout cannot satisfy those assertions.

Fresh processes prevent native imported-module regions from accumulating
between independent phases; see [the memory lifetime](architecture.md).
Identifier encoding was also checked after loading the package under Latin-1.
The maintained commands are `make check`, `make test` and `make test-mathlib`.
Raw reports and experiment logs are generated under ignored `build/`.

## Local prerequisite bootstrap

The local-tool bootstrap pins official micromamba 2.10.0 binaries, Git 2.56.0
and curl 8.23.0 package locks for six operating-system/architecture combinations. All binary
checksums were matched against the official release sidecars and release
metadata. The 193 package records pin exact conda-forge URLs and SHA-256 hashes;
installation does not resolve a moving package set.

On macOS ARM64, the installed 22-package inventory exactly matched its lock.
The private Git passed HTTPS `ls-remote` and shallow-clone checks with system
Git excluded from PATH. Both also passed with spaces in the installation and
checkout paths. A separate two-phase check downloaded packages first and
installed them offline with an unusable network proxy, then verified HTTPS
Git operation. Only each prototype's exact environment-registry entry was
removed afterward; other entries and user configuration were preserved.

The other five platform manifests were resolved and checked, but their
binaries were not executed on this macOS host. Installer regressions cover
reuse of working Git, the macOS developer-tools launcher, cancellation during
download and installation, and preservation of unrelated directories.
The curl locks contain 95 package records in addition to the unchanged 98 Git
records. On macOS ARM64, a separate 16-package curl prefix matched its exact
lock and fetched the pinned Lean toolchain file over HTTPS with only its own
bin directory on PATH. Installation downloaded first and linked offline.
Git and curl use separate prefixes so installing one preserves a working copy
of the other. Foreign-platform binaries have not been run on this host.

The actual Wolfram curl helper also passed download, offline installation,
HTTPS transfer, reuse and public executable-metadata checks. It installed no
Git copy and preserved the existing Git executable, process environment and
caller context. A ready installation still performs no downloads.

Fresh Wolfram-kernel probes also exercised the actual Git and elan bootstrap
helpers in isolated directories. Git passed HTTPS operation with a private-only
PATH, reuse and executable-metadata checks. Elan preserved the global default
toolchain. A real download task passed cancellation, partial-file cleanup,
retry and checksum verification. Running `InstallMathlib` against the ready
runtime performed no downloads and preserved its pins, the caller's context
path and process environment.

## Proof boundary

A computed value is not a checked theorem. `ProveMathlib` checks the generated
module in Lean's kernel and examines the theorem's axiom dependencies. It
accepts only Lean's standard `propext`, `Quot.sound` and `Classical.choice`
axioms. The installed Lean toolchain, imported libraries and LeanLink bridge
remain part of the trusted implementation. Namespace coverage does not claim
that every imported function was numerically tested or every imported theorem
was independently reproved by MathlibLink.

## Documentation checks

The 16 documentation pages and resource definition contain 132 authored inputs.
All 128 evaluable inputs were freshly evaluated; four installation examples
explicitly use `eval: false`. The 17 generated notebooks match their Markdown
inputs and contain 110 output groups, with no message cells, Code-style cells,
flagged pages or unexpected failures. Exact tutorial arithmetic was checked
independently. Nine figures were rendered and inspected in light and dark
appearances.

Each page is evaluated in a fresh Wolfram process through PacletPage. Focused
examples import the modules they use; the default-session and full-namespace
examples remain. The final build validates and assembles PacletPage's page
caches before producing the archive.

Uncached macOS measurements sampled the physical footprint of each complete
owned process tree every 0.5 seconds using `proc_pid_rusage`, including Lean
subprocesses. Peaks were 10.85 GiB for Values and Proofs, 8.65 GiB for
ProveMathlib and 4.02 GiB for Getting Started. These are local measurements,
not substitutes for the hosted platform checks. RSS alone can understate
memory retained in compressed or swapped native allocations.

Source hashes, actual outputs, notebook audits, renders and memory samples are
retained under ignored `build/`. The [CI workflow](workflows.md) checks the
native Lean runtime on all three platforms and the Wolfram interface and
installed release archive in Linux.
