---
name: wolfram-example-style
description: Keep Markdown examples and runnable Wolfram notebooks concise, with one-line expressions where possible and no unnecessary presentation options.
---

# Concise Wolfram examples

Apply this skill to every reference page, guide, tutorial, computational essay
and walkthrough notebook in this project. This is the user's explicit policy,
from the supplied issue #7 screenshot, "Code examples should be one line, no
unnecessary options". It takes priority over older local styling advice.

- Write the shortest clear expression, on one line where practical. Let the
  notebook front end wrap it. Split complex work into named intermediate
  computations when that teaches the process; do not compress unrelated work
  into a CompoundExpression just to obtain one line.
- Remove every option the example does not need. Avoid ImageSize, ItemSize,
  ColorRules, ColorFunction, Mesh, AspectRatio, PlotTheme, Epilog, font, spacing,
  background and alignment settings added just to restyle each output.
- Do not put explicit ItemSize rules in the walkthrough. Do not replace them
  with hidden styling helpers or global SetOptions calls in the notebook.
- Keep semantic labels, legends, coordinate ranges, seeds, resource budgets,
  stopping conditions and experiment parameters when they explain the result.
  In an Options section, retain the option being demonstrated and minimize
  unrelated settings. Keep examples comparable to built-in WL documentation.
- A dedicated output-cell style may supply the user's preferred table theme.
  Never override the general Grid style: notebook toolbars also use grids.
  Apply the theme only to table outputs and preserve it on reevaluation with
  cell metadata. Keep ItemSize rules and styling setup out of the walkthrough.
- Use native Grid, Tree, Graph and plotting functions directly. Avoid generic
  presentation wrappers invented only to shorten example inputs. For small
  tables, data and column headings usually suffice.
- Fix an oversized figure through useful orientation, a smaller scientific
  example, or a reasonable default in the actual visualization implementation.
  Do not scatter sizing rules through examples. Re-render to verify the result.
- Walkthrough notebooks use Input cells, never Code-style cells, and may have
  Section/Subsection headings and real computed outputs. Prose belongs in the
  Markdown companion. Preserve numerical data separately from display forms.

Before finishing, inspect example inputs for unnecessary options and multiline
formatting, run them, and inspect the resulting figures and tables in light
and dark appearances. Use the existing three project scripts. Temporary QA
code belongs under build; do not add a fourth maintained script.
