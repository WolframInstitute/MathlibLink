---
name: wolfram-tech-note
description: Write and verify a worked Markdown tutorial with executable computations, scientific figures and a coherent teaching progression.
---

# Worked tutorials

Adapted from Ruliology's tutorial conventions.
Use Template: TechNote in docs/en/Tutorials, a readable Title, the paclet
context and tutorial URI. Add reciprocal links in related guides and tutorials.

Build an arc around one task: inspect a declaration, compute an exact example,
compare a variation, then explain the measured result. Show objects and
figures where introduced. Keep theory in a linked companion when it would
interrupt a practical investigation. Avoid API catalogs disguised as prose.

Each wl block is one captioned expression with one main output. A caption
ends in a colon. Tutorials may thread named results in page order; the build
uses EvaluateSeparator -> None for TechNote pages. Reference pages do not
share this behavior. Bind a result in its own cell rather than hiding multiple
steps inside a CompoundExpression. Load the paclet through Context metadata.

Use actual paclet APIs and built-in plotting tools. Label axes, state seeds,
inputs, evaluation budgets and observation windows. Show censored results
explicitly. More scientific plots, program graphs and comparisons than bare
lists are appropriate for applications; metadata checks need no decoration.

Evaluate the entire page from a clean kernel with the source paclet loaded.
Check claims against outputs, save a reproducible record under build, build
with `make notebooks`, then inspect every figure in light and dark appearance.
The local GUIDE.md gives the rendering method. Keep examples small enough for
interactive reading; do not hide a long search in Basic Examples.

The upstream remote-pod restrictions are deployment-specific and are not
adopted here. Local builds use the three existing scripts. Creating a tutorial
does not itself publish it; `make publish` is the explicit cloud release step.

Sources: [Ruliology](https://github.com/WolframInstitute/Ruliology/blob/main/.agent-skills/ruliology-tech-note/SKILL.md).

Apply [wolfram-example-style](../wolfram-example-style/SKILL.md) to every
example, including notebook companions. It overrides older styling advice.
