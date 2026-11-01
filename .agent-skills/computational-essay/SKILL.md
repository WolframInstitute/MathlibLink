---
name: computational-essay
description: Investigate a concrete mathematical question with reproducible experiments and scientific visuals in a paclet tutorial.
---

# Computational essays

Adapted from Ruliology's ruliology-computational-essay playbook. Read the local
tech-note skill, GUIDE.md, relevant API documentation and tests.

Choose a question that the available implementation can answer. State the
expression or theorem, input range, resource budgets, stopping rule
and observation. Start with an independently checkable small case, then vary
one factor or sample a declared ensemble. Use the bridge APIs; do not reproduce bridge internals in an essay.

For stochastic claims, give seeds and sample count and use several runs when
showing variation. A selected successful run demonstrates possibility, not
success probability. Report a budget-limited evaluation as unfinished, not as
nonterminating or a missing solution. Preserve qualifiers when comparing a
finite sample with a theorem.

Generate each figure from the displayed experiment. Prefer behavior curves,
residue arrays, completion maps, syntax graphs, trajectories and ensemble
comparisons over long output lists. Keep scales comparable and color keys
explicit. Explain what the computation establishes and what it does not.

Store the essay as a TechNote under docs/en/Tutorials and link it from guides
and reference-page Applications. Keep version/seed/budget evidence under
build and state the reproducibility details in the essay. Cite a source
when reproducing an external result and identify changed parameters.

Run all cells, inspect the built notebook and render all figures in light and
dark appearances. Record failures and fix them before describing a page as
verified. Publication remains a separate explicitly requested action.

Source: [Ruliology](https://github.com/WolframInstitute/Ruliology/blob/main/.agent-skills/ruliology-computational-essay/SKILL.md).

For a runnable notebook companion, use Input cells and section groups. Inspect complete outputs, not only the first screenful. Native Grid tables suit compact research summaries.
Distinguish computation from proof: numerical samples are finite evidence.
A Lean theorem has a type, proof term, axiom dependencies and kernel status.
Do not claim that every declaration can execute: noncomputable definitions and
theorems remain accessible as typed objects.

Apply [wolfram-example-style](../wolfram-example-style/SKILL.md) to every
example, including notebook companions. It overrides older styling advice.
