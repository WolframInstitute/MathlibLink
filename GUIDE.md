# Code and documentation conventions

Use StructuredPackageFormat with one public context,
`` WolframInstitute`MathlibLink` ``. Follow PARILink's explicit sessions,
structured arguments, exact values and session-owned objects. Use tabs in
Wolfram Language, short usage messages and local helpers. Loading the paclet
must not install software or start an external computation.

Markdown under docs/en is authoritative. PacletPage builds the notebooks and
publishes the resource and documentation site. Keep the maintained scripts to
check.wls, test.wls and docs.wls. Temporary probes, rendered figures, cached
results and coverage records belong under build.

Read the local skills for [reference pages](.agent-skills/wolfram-symbol-page/SKILL.md),
[guides](.agent-skills/wolfram-guide-page/SKILL.md),
[tutorials](.agent-skills/wolfram-tech-note/SKILL.md), and
[computational essays](.agent-skills/computational-essay/SKILL.md).
Use flat Publisher/Paclet/ref/Symbol URIs and reciprocal related-page links.
Context names need double-backtick Markdown spans. A symbol's Usage section
contains its construction signatures; instance properties belong in Details.
Options tables in reference pages have empty header cells.

Apply [the example-style skill](.agent-skills/wolfram-example-style/SKILL.md):
one expression per Input cell, one line where practical, a caption ending in
a colon, no unnecessary display options, and no explicit ItemSize in a
walkthrough. Use standard Input cells, never Code-style cells. Let useful
orientation and concise data keep figures compact.

Examples are independent across headings and separators in reference pages.
Tutorials can thread a session through page order. Use WithCleanup for short
self-contained session examples; longer demonstrations create the session in
one cell and close it after the last use. Examples do not install libraries;
installation cells use the converter's eval: false directive.

Preserve the distinction between values and proofs. MathlibEvaluate computes
Lean expressions; a computed True is not a theorem. ProveMathlib checks a
proof, including its kernel replay and axiom dependencies. Show theorem types
and hypotheses accurately. Noncomputable definitions and theorem statements
are accessible even when they have no executable numerical interpretation.
State the installed Lean/mathlib version when a claim depends on it. Live
upstream documentation can describe a newer release.

Run every example against the source paclet and retain actual outputs.
Inspect the built output cells. Render every changed figure in light and dark
appearance, using a one-cell notebook with LightDark set explicitly, and
check scales, labels and clipping. Do not infer success from Markdown
conversion alone. Use native Grid and plotting functions directly.

Run make check and make test for changes, and make check-publish for a complete
archive check. Publishing is a separate cloud release action. Keep test
results and full-namespace coverage evidence separate from claims about
which arbitrary mathematical expressions terminate or have numerical values.
