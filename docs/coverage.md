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
All 58 local tests pass, including rejection of modified tracked mathlib sources,
preserved caller contexts and selection of private or existing curl ahead of an
older copy beside Git. The 22 live checks were repeated successfully after the
automatic curl bootstrap was added.
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

The 16 documentation pages contain 123 executable inputs. The initial 122
were checked against the pinned runtime; exact comparisons returned True,
and the intentional admitted proofs were rejected. After the local installer
update, all 20 inputs on its three affected pages were freshly evaluated,
including the new cancellation example. The other 103 inputs retained their
verified outputs from commit `af7e39b`. Their Markdown, input expressions,
output counts and the evaluation, object and session source files were
checked against that baseline before reuse.

The resource definition adds two verified examples. All 17 notebooks match
their authored input expressions and expected output counts, with no message
cells or Code-style cells. Fresh metadata includes the executable paths;
cancellation gives its expected diagnostic. The refreshed tutorial's integer
square root and binomial row were checked exactly.

After curl setup was added, the same three pages were rebuilt with all 20
inputs freshly evaluated. The other 13 pages retained their audited outputs
only after unchanged-source, exact-input and output-count checks. The updated
installation metadata includes Curl and passed light and dark rendering checks.

Nine computed figures and the session/object displays were rendered and
inspected in light and dark appearances. The refreshed setup metadata and
binomial plot passed the same visual check. The final proof tutorial was
assembled through the converter's evaluator interface from its recorded
outputs after license interruptions; every supplied input had to match its
verified source exactly. Raw outputs, provenance and notebook audits are
retained under build/.
