# CI and releases

MathlibLink runs locally on Linux x86-64, Windows x86-64 and macOS ARM64.
GitHub hosts release archives; the installer downloads the pinned Lean,
mathlib, LeanLink and missing command-line tools. Computations and proof checks
run on the user's machine.

## Workflows

| Workflow | Trigger | Required result |
| --- | --- | --- |
| [Repository checks](../.github/workflows/pull-request.yml) | Pull requests; called by CI | Whitespace, JSON manifests and pinned actionlint checks on a GitHub-hosted runner |
| [CI](../.github/workflows/ci.yml) | Push to `main`; manual dispatch from `main` | Source checks, local tests and live mathlib tests on all three platforms; PacletPage build; installed-archive smoke tests on all three platforms |
| [Release](../.github/workflows/release.yml) | `vX.Y.Z` tag; manual retry from `main` | Matching version, commit on `main`, successful CI for that exact commit and verified artifact checksums |
| [Publish](../.github/workflows/publish.yml) | Manual dispatch from `main`, with a release tag | Verified GitHub release, protected environment approval, publication of the same archive with PacletPage and a successful site check |

Repository checks do not execute Wolfram tests. The CI badge reports the full
native matrix. Missing licenses, tools, runtime downloads or failed tests fail
their jobs; unavailable native runners leave jobs queued. These workflows need
the runners below before a GitHub CI run can pass.

## Native runners

Create the organization runner group `mathliblink` with these labels:

| Target | Labels |
| --- | --- |
| Linux x86-64 | `self-hosted`, `linux`, `x64`, `wolfram-15` |
| Windows x86-64 | `self-hosted`, `windows`, `x64`, `wolfram-15` |
| macOS ARM64 | `self-hosted`, `macOS`, `ARM64`, `wolfram-15` |

Each runner needs licensed Wolfram Language 15, `wolframscript`, Git, Bash,
GNU make and Python 3.12 or later on `PATH`. On Windows, provide Bash through
Git for Windows and ensure `make`, `python3` and `wolframscript` are visible in
that shell. Keep the Actions runner current for the pinned Node-based actions.
Allow at least 16 GB RAM and 30 GB free disk space for the full mathlib build.
The license must permit the child kernels used by PacletPage for the duration
of the documentation job.

The macOS runner also needs a working Wolfram front end and
[WolframInstitute/PacletPage](https://github.com/WolframInstitute/PacletPage)
**0.3.42**. The setup action verifies that exact
version; provision it as the active PacletPage installation. Documentation
conversion uses PacletPage's MarkdownToNotebook dependency. CI calls the
existing `make` targets and `InstallMathlib[]`; it does not require a global
Lean or mathlib installation. Use dedicated runner accounts without cloud
publishing credentials. Runtime caches may persist in trusted runner images;
every CI run still checks the pin and executes the tests.

Use ephemeral runners and restrict the runner group to this repository and
these workflow refs:

```text
WolframInstitute/MathlibLink/.github/workflows/ci.yml@refs/heads/main
WolframInstitute/MathlibLink/.github/workflows/publish.yml@refs/heads/main
```

Public pull requests run only on GitHub-hosted runners with read-only tokens
and no secrets. Do not enable native jobs for `pull_request_target`, fork code
or arbitrary branches. Runner group restrictions enforce the trusted workflow
boundary; environment approval alone does not isolate a self-hosted machine.
See GitHub's [runner group access](https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/manage-runners/self-hosted-runners/manage-access)
and [secure use guidance](https://docs.github.com/en/actions/reference/security/secure-use).

## Release an archive

1. Merge the version change into `main` and wait for all CI jobs to pass.
2. Create `vX.Y.Z` at that exact commit, matching `MathlibLink/PacletInfo.wl`.
3. The Release workflow downloads that commit's `MathlibLink-verified` artifact
   and verifies its commit, version, CI run and SHA-256 digests.

The GitHub release contains the `.paclet`, `SHA256SUMS`, `build.json` provenance
and `pacletpage-build.tar.gz` for publishing the already-built documentation.
It starts as a draft and becomes public only after all assets are attached.
A retry accepts identical assets and refuses to overwrite changed ones.
The workflow uses its job-scoped GitHub token; no personal access token is
needed. CI artifacts expire after 30 days, so create the release within that
window. The attached release assets remain available for later cloud publishing.

Protect `main` and release tags against unreviewed changes. Require the hosted
repository check before merging; require successful native CI before creating
a release tag. Cloud publication is a separate manual operation.

## Publish with PacletPage

Create the `wolfram-publish` environment, restrict deployments to `main`, and
configure required reviewers. Add these environment secrets:

| Secret | Purpose |
| --- | --- |
| `WOLFRAM_CLOUD_USER` | Wolfram Cloud account authorized to publish under `WolframInstitute` |
| `WOLFRAM_CLOUD_PASSWORD` | That account's cloud password |

Native runners use their provisioned Wolfram license; no entitlement secret is
required by these workflows. The cloud secrets are passed only to the final
publishing step. GitHub documents the approval and secret rules in
[deployment environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments).

Dispatch **Publish** from `main` with an existing release tag. It checks that
release's recorded CI run, downloads its assets, verifies their hashes, and
restores the PacletPage build beside the tagged source. The existing
`scripts/docs.wls publish` command checks that the restored build matches the
archive in `dist`, then uses PacletPage with both build stages disabled. It
checks the archive hash again after publication and requires successful
resource deployment and site validation. It does not submit to the Wolfram
Paclet Repository.

For a local release, run `make check-publish` before `make publish`, and connect
to the intended Wolfram Cloud account in the publishing kernel. A changed
source tree or missing build stamp fails before publication. Do not replace
the verified archive or reuse its version for a different commit.
