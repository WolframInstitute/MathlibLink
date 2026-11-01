# MathlibLink development

Read docs/architecture.md before changing installation, sessions or values.
Follow PARILink's explicit sessions and structured failures. MathlibLink is
independent of projects that use it. Loading the paclet must not start Lean,
install software or access the network.

Use one public context, StructuredPackageFormat, tab indentation and short
usage messages. Preserve exact types and values. Do not interpret returned
Lean source as Wolfram Language. The generic namespace and expression APIs
must remain open to every declaration in imported mathlib modules.

Computational evaluation is not proof checking. Proof verification must
check the kernel result and the actual axiom dependencies. Do not accept
sorryAx, native_decide bypasses, or arbitrary user axioms as verified proofs.

Use Markdown documentation and PacletPage. Read the relevant .agent-skills
playbook before editing documentation. Keep examples concise and one line
where practical, with no unnecessary presentation options.

Keep only scripts/check.wls, scripts/test.wls and scripts/docs.wls. Run
make check and make test for code changes, make test-mathlib for live bridge
changes and make check-publish for documentation and packaging. Temporary
experiments and logs belong in ignored build/. Keep runtime caches outside
the paclet. Do not publish or push without an explicit release instruction.

Commit focused verified changes using type(scope): short description.
