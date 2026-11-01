# Design

MathlibLink connects Wolfram Language to the complete declaration namespace
of a pinned mathlib release. It follows PARILink's explicit sessions,
structured arguments, retained objects and error handling. It is independent
of Recursor, PureMath and other consumers.

LeanLink supplies the native Lean environment, elaboration, evaluation and
kernel-checking operations. MathlibLink supplies a reproducible mathlib setup,
session-owned object lifetimes, generic calls, declaration discovery and
upstream documentation links. There is no hand-maintained function whitelist.
The default session imports Mathlib; smaller import lists reduce startup cost.
Definitions, theorems, typeclasses and noncomputable declarations remain Lean
objects when they cannot be copied as Wolfram values.

Loading the paclet performs no installation or network access. InstallMathlib
explicitly installs the pinned Lean toolchain, LeanLink and mathlib. Elan's
global default is not changed. Mathlib lives in the user's application-data
directory; the paclet carries only the small version manifest. Setup downloads
the complete cache to make all modules available and builds the Mathlib target.
The upstream lake-manifest.json is preserved; setup never runs lake update,
which would advance dependencies beyond the pinned release.
Existing unrelated directories and other revisions are rejected rather than
reset or overwritten. Interrupted setup can be rerun at the same revision.

Sessions borrow LeanLink's cached import environments. Closing one session
invalidates its objects without freeing another session's shared environment.
Compiled expression and proof environments are unique and are freed when the
owning object or session closes. Cached imported modules remain under LeanLink's
ownership. Session and object identifiers are valid only in the creating kernel.

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
