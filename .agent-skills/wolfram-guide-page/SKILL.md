---
name: wolfram-guide-page
description: Create or revise a paclet guide with coherent topic organization, real symbol links and reachable tutorial navigation.
---

# Guide pages

Adapted from Ruliology's guide conventions.
Use Template: Guide under docs/en/Guides, with Name, Title, Description,
Context, Paclet, URI, Keywords and applicable related-page metadata.

Organize by the user's computational task, from inspecting declarations to evaluating expressions and checking proofs. Use a short topics-focused abstract.
A function bullet starts with its symbol in backticks and a short description.
List only implemented exports. Relevant built-ins can appear with a (WL) marker;
verify that the installed kernel provides them. Do not invent wrappers for
standard plotting or mathematical functions.

The root guide's linked subsection headings are navigation edges to its
children. Keep every guide reachable, with reciprocal RelatedGuides links,
no cycles and no missing targets. Link computational essays from both their
owning guides and relevant symbol pages. Keep flat documentation URIs even
when source files are grouped in directories.

Build with `make notebooks`, inspect the resulting guide and its links, and
run `make check-publish` for release validation. See the local symbol-page
skill and GUIDE.md for shared formatting and example rules.

Sources: [Ruliology](https://github.com/WolframInstitute/Ruliology/blob/main/GUIDE.md).

Apply [wolfram-example-style](../wolfram-example-style/SKILL.md) to every
example, including notebook companions. It overrides older styling advice.
