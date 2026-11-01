# Design

MathlibLink connects Wolfram Language to the complete declaration namespace
of a pinned mathlib release. It follows PARILink's explicit sessions,
structured arguments, retained objects and error handling. It is independent
of the applications that use it.

LeanLink supplies the native Lean environment, elaboration, evaluation and
kernel-checking operations. MathlibLink supplies a reproducible mathlib setup,
session-owned object lifetimes, generic calls, declaration discovery and
upstream documentation links. There is no hand-maintained function whitelist.
The default session imports Mathlib; smaller import lists reduce startup cost.
Definitions, theorems, typeclasses and noncomputable declarations remain Lean
objects when they cannot be copied as Wolfram values.

Loading the paclet performs no installation or network access. InstallMathlib
explicitly prepares elan, Git and curl when needed, then installs the pinned Lean
toolchain, LeanLink and mathlib. Elan's global default is not changed. Mathlib
lives in the user's application-data directory; the paclet carries only small
version manifests. Setup downloads
the complete cache to make all modules available and builds the Mathlib target.
The upstream lake-manifest.json is preserved; setup never runs lake update,
which would advance dependencies beyond the pinned release.
Readiness imports the pinned Lean Init module through LeanLink to check native
compatibility; it does not assume every newer LeanLink release uses the same ABI.
It also checks the checkout revision, manifest checksum and tracked-source diff.
Existing unrelated directories and other revisions are rejected rather than
reset or overwritten. Interrupted setup can be rerun at the same revision.

Sessions borrow LeanLink's cached import environments. Closing one session
invalidates its objects without freeing another session's shared environment.
Compiled expressions and proofs have unique environment handles, released when
the owning object or session closes. Cached imported modules remain under LeanLink's
ownership. Session and object identifiers are valid only in the creating kernel.

LeanLink 1.2.5 also retains native imported-module regions until the kernel exits;
freeing an environment handle does not reclaim those regions. Its
[environment loader](https://github.com/WolframInstitute/LeanLink/blob/8f9d43c5422b0514229a7fc3407a86b160f67423/Native/lib/LeanLink/EnvStore.lean#L49-L57)
documents this lifetime. Prefer explicit module imports for focused work.
Independent live-test phases run in fresh Wolfram kernels so repeated full
imports do not accumulate across the suite. Full-default namespace, call and
proof checks remain part of the live tests.

MathlibEvaluate runs Lean's evaluator and copies supported JSON values.
MathlibCall builds a Lean application from exact structured values and typed
source arguments. Neither operation is a theorem prover. ReturnType "Object"
elaborates and retains a typed Lean definition, including noncomputable terms.
ProveMathlib elaborates a theorem, checks its module in Lean's kernel and
rejects dependencies outside Lean's standard propext, Quot.sound and
Classical.choice axioms. A Lean source string is executable Lean code, not
a sandbox for untrusted input. Returned text is never evaluated as WL code.

A declaration's DocumentationURL links to the official mathlib documentation
module and anchor. The public website follows mathlib development; the local
runtime remains pinned, so source and type information from the session are
authoritative for that installation.

Tests separate local API behavior from live mathlib checks. Coverage records
compare the exposed namespace with the imported Lean environment and exercise
arithmetic, algebra, analysis, topology and computability. Coverage does not
claim that a theorem or noncomputable function can be evaluated numerically.
PacletPage is the sole documentation and archive pipeline; publishing is a
separate explicit action.

Timeouts and interruptions close the owning session for every execution path,
including retained expressions and proofs. LeanEvaluate bounds its subprocess.
TimeConstrained around LeanLink elaboration and native kernel checking is a
best-effort bound: an uninterruptible native call can return after the deadline.
A timeout is an incomplete check and never a successful proof.

Explicit installation accepts progress and cancellation callbacks. External
commands use StartProcess with both output streams drained while polling for
cancellation. Cleanup kills the owned process on cancellation, interruption or
callback failure. A cancelled new clone is removed only from a directory created
by that installation attempt. An existing checkout and completed caches remain.
PacletInstall and native readiness checks observe cancellation between stages;
their progress is never presented as a cancellable download.

The official elan installer is checksum-pinned and runs with --no-modify-path
and --default-toolchain none. ELAN_HOME is respected. Lake always uses elan's
proxy, so the explicit +toolchain argument cannot reach an unrelated native
Lake executable on PATH. Existing working Git is reused. On macOS, the Apple
Git launcher is checked through xcode-select before it can start a developer
tools prompt.

If Git or a suitable HTTPS curl is unavailable, a checksum-pinned micromamba
binary downloads an exact per-platform package lock from conda-forge. The tools
use separate prefixes, so preparing one does not shadow a working copy of the
other. A private configuration confines
package caches and environment files to MathlibLink's tools directory; normal
per-user environment registration is retained. Downloading packages and
offline installation are separate stages. Incomplete owned prefixes can be
cleaned up; completed or unrelated directories are never overwritten.
Public installation metadata supplies executable paths and required child
PATH directories without modifying the Wolfram process environment.
