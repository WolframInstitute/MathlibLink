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
their jobs. The workflows install their tools on GitHub-hosted runners; no
custom runner registration is required.

## Hosted runners

| Target | GitHub runner | Wolfram installation |
| --- | --- | --- |
| Linux x86-64 | `ubuntu-24.04` | Official `wolframresearch/wolframengine:15.0` container, pinned by digest |
| Windows x86-64 | `windows-2025` | Wolfram's 15.0.0 installer, pinned by SHA-256 |
| macOS ARM64 | `macos-15` | Wolfram's 15.0.1 desktop image, pinned by SHA-256 |

All three run the complete source, local and live mathlib checks, followed by
smoke tests of the installed release archive. Windows and macOS execute native
Wolfram kernels. Linux uses the official engine container, as PARILink and
Ruliology do. The setup action checks the actual Wolfram version and system ID;
it does not substitute another platform or skip unavailable tests.

The macOS image comes from the public
[Wolfram Download Center](https://www.wolfram.com/download-center/).
The setup action resolves its generated public link afresh and requires the
exact pinned version; it does not store a download signature or use account
credentials. Its SHA-256 is pinned from the official download; the action also
checks its version and Wolfram Research's Apple Developer ID signature before using
the bundled command-line executables. The app stays in the runner's temporary
directory. Windows uses the URL, checksum and silent installation switches in
[Microsoft's WinGet manifest](https://github.com/microsoft/winget-pkgs/blob/master/manifests/w/WolframResearch/WolframEngine/15.0.0/WolframResearch.WolframEngine.installer.yaml).
Installer transfers use bounded retries and resume partial downloads.
Python and GNU make are prepared automatically, and `InstallMathlib[]`
prepares the pinned local Lean, LeanLink and mathlib runtime.

PacletPage building and publishing run in the Linux container with its front
end configured for offscreen rendering. Documentation tools are fetched from
fixed source commits and installed within the job:

| Tool | Pinned source |
| --- | --- |
| PacletPage 0.3.42 | [ad583493](https://github.com/WolframInstitute/PacletPage/commit/ad583493187194eeaa22d7e774a30ca475934aa4) |
| MarkdownToNotebook | [c2b5703c](https://github.com/WolframInstitute/MarkdownToNotebook/commit/c2b5703cc813ef620dd744fca82353bfbfb6ca6f) |
| WolframParser | [0697ceb7](https://github.com/sw1sh/WolframParser/commit/0697ceb787111be04f0d9f043d7674ee146c76c2) |

Public pull requests run only repository checks, with read-only tokens and no
secrets. Wolfram jobs and manual publishing require `main`. Keep this separation
when changing the workflows; see GitHub's
[secure use guidance](https://docs.github.com/en/actions/reference/security/secure-use).

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

The hosted workflows require the entitlement secret and fail before installing
Wolfram if it is missing. Local `make` commands can still use an existing
license. [WolframScript](https://reference.wolfram.com/language/ref/program/wolframscript.html)
uses the entitlement to license each native kernel. As in PARILink and Ruliology, `scripts/docs.wls`
routes PacletPage's fresh `WolframKernel -script` processes through
`wolframscript`, retaining the selected kernel executable and process options.
The scoped adapter recognizes Linux/macOS executable paths and Windows `.exe`
paths, including spaces. Other subprocesses and the package runtime are
unchanged. The three native platform tests still run in full.

## Release an archive

1. Merge the version change and `docs/releases/X.Y.Z.md` release notes into
   `main`, then wait for all CI jobs to pass.
2. Create `vX.Y.Z` at that exact commit, matching `MathlibLink/PacletInfo.wl`.
3. The Release workflow downloads that commit's `MathlibLink-verified` artifact
   and verifies its commit, version, CI run and SHA-256 digests.

The GitHub release contains the `.paclet`, `SHA256SUMS`, `build.json` provenance
and `pacletpage-build.tar.gz` for publishing the already-built documentation.
It starts as a draft and becomes public only after all assets are attached.
A release uses the notes from its verified commit.
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
