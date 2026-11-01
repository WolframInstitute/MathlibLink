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
| [Publish](../.github/workflows/publish.yml) | Manual dispatch from `main`, with a release tag | Verified GitHub release, publication of the same archive with PacletPage and a successful site check |

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

Each runner needs Wolfram Language 15, `wolframscript`, Git, Bash,
GNU make and Python 3.12 or later on `PATH`. On Windows, provide Bash through
Git for Windows and ensure `make`, `python3` and `wolframscript` are visible in
that shell. Keep the Actions runner current for the pinned Node-based actions.
Allow at least 16 GB RAM and 30 GB free disk space for the full mathlib build.
Use an existing runner license or the optional entitlement secret described
below. The license must permit PacletPage's child kernels for the duration of
the documentation job.

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
boundary.
See GitHub's [runner group access](https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/manage-runners/self-hosted-runners/manage-access)
and [secure use guidance](https://docs.github.com/en/actions/reference/security/secure-use).

## License and credentials

This follows [Ruliology's entitlement setup](https://github.com/WolframInstitute/Ruliology/blob/main/scripts/entitlement.wl).
In a Wolfram notebook connected to the account that will pay for CI, run:

```wl
entitlement = CreateLicenseEntitlement[<|"StandardKernelLimit" -> 32, "ParallelKernelLimit" -> 32, "LicenseExpiration" -> Quantity[1, "Hours"], "EntitlementExpiration" -> Quantity[1, "Years"]|>]
CopyToClipboard[entitlement["EntitlementID"]]
```

These are Ruliology's exact settings: up to 32 regular kernels and 32 parallel
kernels, a one-hour lifetime for each license and a one-year entitlement.
Creating the entitlement does not spend Service Credits; activated kernels
charge usage to its owner's balance. Increase `"LicenseExpiration"` if an
individual documentation build needs more than one hour; a workflow timeout
does not extend the license. See
[CreateLicenseEntitlement](https://reference.wolfram.com/language/ref/CreateLicenseEntitlement.html).

In a terminal, store the copied ID and the publishing account's credentials.
Each command prompts for its value:

```bash
gh secret set WOLFRAMSCRIPT_ENTITLEMENTID --repo WolframInstitute/MathlibLink
gh secret set WOLFRAM_CLOUD_USER --repo WolframInstitute/MathlibLink
gh secret set WOLFRAM_CLOUD_PASSWORD --repo WolframInstitute/MathlibLink
```

`WOLFRAM_CLOUD_USER` is the Wolfram ID of the account authorized to publish
under `WolframInstitute`; `WOLFRAM_CLOUD_PASSWORD` is that account's password.
Authenticate the GitHub CLI with `gh auth login` first if needed. No separate
GitHub environment is required.

The entitlement secret is optional. Without it, runners use their existing
license. With it, [WolframScript](https://reference.wolfram.com/language/ref/program/wolframscript.html)
licenses each native kernel. As in PARILink and Ruliology, `scripts/docs.wls`
routes PacletPage's fresh `WolframKernel -script` processes through
`wolframscript`, retaining the selected kernel executable and process options.
The scoped adapter recognizes Linux/macOS executable paths and Windows `.exe`
paths, including spaces. Other subprocesses and the package runtime are
unchanged. The three native platform tests still run in full.

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

The workflow passes the repository's cloud credentials only to its final
publishing step. PacletPage manages resource deployment, documentation and the
site check after cloud authentication.

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
