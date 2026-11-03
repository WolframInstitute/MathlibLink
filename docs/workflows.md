# CI and releases

MathlibLink runs locally on Linux x86-64, Windows x86-64 and macOS ARM64.
GitHub hosts release archives; the installer downloads the pinned Lean and
mathlib runtime, the latest published LeanLink and missing command-line tools.
Computations and proof checks run on the user's machine.

## Workflows

| Workflow | Trigger | Required result |
| --- | --- | --- |
| [Repository checks](../.github/workflows/pull-request.yml) | Pull requests; called by CI | Whitespace, JSON manifests and pinned actionlint checks |
| [CI](../.github/workflows/ci.yml) | Push to `main`; manual dispatch from `main` | Native Lean/mathlib checks on three platforms; complete Wolfram tests, documentation, archive and installed-paclet checks in Linux |
| [Release](../.github/workflows/release.yml) | `vX.Y.Z` tag; manual retry from `main` | Successful CI for the exact commit, publication through PacletPage, then GitHub release assets |

The pipeline follows [PARILink](https://github.com/WolframInstitute/PARILink/blob/main/.github/workflows/ci.yml):
external runtimes are checked on their native platforms; Wolfram tests,
documentation and packaging use the official Linux Wolfram Engine container.
No desktop Wolfram installer is downloaded by CI.

## Hosted checks

| Check | Runner | Coverage |
| --- | --- | --- |
| Native Lean and mathlib | `ubuntu-24.04`, `windows-2025`, `macos-15` | Pinned toolchain and mathlib revision; exact computations and checked proofs |
| Wolfram interface and paclet | `ubuntu-24.04`, official Wolfram Engine 15.0 container | Source and local tests; all live bridge tests; documentation; archive installation and public-interface checks |

The native jobs use the same runtime manifest as `InstallMathlib[]`. They
verify the elan archive checksum, cache the pinned Lean toolchain, preserve
mathlib's dependency manifest, and compile
[Runtime.lean](../MathlibLink/Tests/Runtime.lean) with warnings treated as errors.
Mathlib supplies its compiled module cache. These jobs exercise the external
runtime directly; they do not claim Wolfram bridge coverage on Windows or macOS.

The Linux Wolfram job exercises the actual installer and LeanLink bridge.
Independent live-test phases and documentation pages run in fresh kernels to
release native imports. Full-import correctness checks use an unlimited
computation budget inside the job timeout; separate tests enforce short time
limits. The installed-paclet check confirms that the public interface loads
from the archive and verifies computation, proof checking and admission rejection.

PacletPage builds and checks the documentation and archive, then a clean-checkout
dry run verifies that publication can reuse the same archive. The CI badge
covers both native runtime jobs and the complete Wolfram job. Any failed job
blocks release.

Documentation tools are fetched from fixed source commits:

| Tool | Pinned source |
| --- | --- |
| PacletPage 0.3.42 | [ad583493](https://github.com/WolframInstitute/PacletPage/commit/ad583493187194eeaa22d7e774a30ca475934aa4) |
| MarkdownToNotebook | [c2b5703c](https://github.com/WolframInstitute/MarkdownToNotebook/commit/c2b5703cc813ef620dd744fca82353bfbfb6ca6f) |
| WolframParser | [0697ceb7](https://github.com/sw1sh/WolframParser/commit/0697ceb787111be04f0d9f043d7674ee146c76c2) |

Public pull requests run repository checks with read-only tokens and no secrets.
Wolfram CI and release dispatches require `main`. No custom runner registration
or separate GitHub publishing environment is required.

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

The Wolfram container jobs require the entitlement secret and fail before running
the kernel if it is missing. Native Lean runtime jobs do not need a Wolfram license. Local `make` commands can still use an existing
license. [WolframScript](https://reference.wolfram.com/language/ref/program/wolframscript.html)
uses the entitlement to license each container kernel. As in PARILink and Ruliology, `scripts/docs.wls`
routes PacletPage's fresh `WolframKernel -script` processes through
`wolframscript`, retaining the selected kernel executable and process options.
The scoped adapter recognizes Linux/macOS executable paths and Windows `.exe`
paths, including spaces. Other subprocesses and the package runtime are
unchanged.

## Release and publish

1. Merge the version change and `docs/releases/X.Y.Z.md` release notes into
   `main`, then wait for every CI job to pass.
2. Create `vX.Y.Z` at that exact commit, matching `MathlibLink/PacletInfo.wl`.
3. The Release workflow verifies the tag and successful CI, publishes the
   verified archive through PacletPage, then creates the GitHub release.

This is one release pipeline, following
[PARILink's release workflow](https://github.com/WolframInstitute/PARILink/blob/main/.github/workflows/release.yml).
A matching tag publishes both the Wolfram Cloud resource/documentation and
GitHub assets. To retry an existing tag, dispatch **Release** from `main`.

The workflow downloads that commit's `MathlibLink-verified` artifact, checks
its provenance and SHA-256 digests, and restores its PacletPage build.
`scripts/docs.wls publish` checks the restored archive, uses PacletPage with
both build stages disabled, then requires successful deployment and site checks.
Cloud credentials are supplied only to that publishing step. Publication does
not submit to the Wolfram Paclet Repository.

The GitHub release contains the `.paclet`, `SHA256SUMS`, `build.json` provenance
and `pacletpage-build.tar.gz`. It uses the verified commit's release notes and
becomes public only after all assets are attached. A retry accepts identical
assets and refuses to overwrite changed ones. CI artifacts expire after 30
days; create the release within that window.

For local verification, run `make check-publish`. Run `make publish` only from
the intended release checkout and publishing account. A changed source tree,
missing build stamp or mismatched archive fails before publication. Do not
reuse a published version for another commit.
