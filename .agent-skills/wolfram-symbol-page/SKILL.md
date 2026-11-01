---
name: wolfram-symbol-page
description: Author and verify Markdown reference pages for implemented symbols in this paclet, including scope, option examples and visual applications.
---

# Symbol reference pages

Adapted from Ruliology's symbol-page playbook. Read the local GUIDE.md and the symbol's implementation and tests.

Use docs/en/ReferencePages/Symbols/<Symbol>.md, Template: Symbol, the paclet
context, and a flat Publisher/Paclet/ref/Symbol URI. Link it from its owning
guide and supply reciprocal RelatedGuides and relevant SeeAlso entries.

Use real Usage signatures, for example
`<code>[MathlibDeclaration]()[*session*, *name*]</code> gives a declaration.`
Put options, value shapes, binding conventions, failure behavior and scope in
Details & Options. Options tables have an empty header row, then option,
default and description. Link other symbols as `[Symbol]()` outside code spans.

Start Basic Examples with the smallest direct use and its actual result.
Follow with a meaningful variation and a useful computed visual. Metadata
constants do not need artificial plots. Cover each signature and option.
Use Scope, Options, Applications, Properties and Relations and Possible Issues
for distinct reader questions. Give more than one concrete application when
it teaches different uses; make computed figures the main output there.

One demonstration per fenced wl cell, with a brief caption ending in a colon.
Separate independent examples with `---`. A heading or separator resets a
reference page's bindings, so repeat local setup or keep dependent cells in
one group. Use a separate seed cell for a stochastic example.

Run examples against the source paclet, retain actual outputs, then build with
`make notebooks`. Inspect output cells and rendered figures before claiming
completion. `make check-publish` checks the archive. Follow GUIDE.md for visual
QA. Do not invent output hints or treat a finite run as a general proof.

Keep developer rationale in an annotation above Details & Options or in
local design notes; keep observable behavior in the visible documentation.
The project uses three scripts, so do not copy upstream lint/pod infrastructure.

Sources: [Ruliology](https://github.com/WolframInstitute/Ruliology/blob/main/.agent-skills/ruliology-symbol-page/SKILL.md),
[converter conventions](https://github.com/WolframInstitute/MarkdownToNotebook/blob/main/docs/doc-pages.md).

Apply [wolfram-example-style](../wolfram-example-style/SKILL.md) to every
example, including notebook companions. It overrides older styling advice.
