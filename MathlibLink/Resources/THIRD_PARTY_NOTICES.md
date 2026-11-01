# Third-party components

MathlibLink uses LeanLink, Lean and mathlib without including their runtimes
in its paclet archive. Explicit setup downloads pinned releases and preserves
their upstream license files. LeanLink uses the MIT license; Lean and mathlib
use the Apache License 2.0. Mathlib's Lake dependencies retain their own
license files in the installed checkout.

When these tools are missing, explicit setup downloads
[elan 4.2.4](https://github.com/leanprover/elan/tree/v4.2.4), licensed under
Apache License 2.0, and
[micromamba 2.10.0](https://github.com/mamba-org/mamba), licensed under
BSD 3-Clause. Micromamba installs checksum-pinned conda-forge Git packages
into a private prefix. [Git](https://github.com/git/git/tree/v2.56.0) uses
GPL version 2; its packaged components and dependencies retain their own
license notices in the prefix and package cache. The
[conda-forge recipe](https://github.com/conda-forge/git-feedstock/tree/71aa484678c3d0372e48ad8053b1ce6411f20b80)
records the packaged license terms and corresponding source locations.
No third-party executable is included in the MathlibLink paclet archive.

Setup can also prepare [curl 8.23.0](https://curl.se/docs/copyright.html) and
its pinned conda-forge dependencies in a separate private prefix. Curl uses
the curl license. Its packaged notices and dependency licenses remain in the
installed prefix and package cache.
