Needs["WolframInstitute`MathlibLink`"]

VerificationTest[MathlibInstallation["Directory" -> 42]["Tag"], "MathlibInvalidOption", TestID -> "directory-type-checked"]
VerificationTest[InstallMathlib["Unknown" -> True]["Tag"], "MathlibInvalidOption", TestID -> "installer-rejects-unknown-options"]
VerificationTest[MathlibInstallation[]["Toolchain"], "leanprover/lean4:v4.35.0", TestID -> "toolchain-pinned"]
VerificationTest[MathlibInstallation[]["Revision"], "56a005855ea17e0b0958f73ec801ae140b0a1679", TestID -> "mathlib-pinned"]
VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibVersionQ @@@ {{"1.2.5", "1.2.5"}, {"1.2.10", "1.2.5"}, {"1.2.4", "1.2.5"}},
	{True, True, False}, TestID -> "versions-compare-numerically"
]
