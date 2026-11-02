# Changelog

## 0.1.1

- Use LeanLink's environment evaluator and proof checks when available, while preserving compatibility with released LeanLink.
- Prepare evaluation during module imports and share expression and proof cleanup.
- Show expandable notebook summaries for sessions, declarations, values and expressions.
- Read available installation output without unnecessary waits.

## 0.1.0

- Add pinned mathlib installation and explicit Lean sessions.
- Expose declarations, generic calls, typed objects and checked proofs.
- Link declarations to the official mathlib documentation.
- Prepare missing elan and Git tools locally with pinned downloads.
- Prepare a private HTTPS curl when the mathlib cache tool needs it.
- Add installation progress, cancellation and executable-path metadata.
