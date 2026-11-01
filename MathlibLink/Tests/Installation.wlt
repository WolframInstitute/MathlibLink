Needs["WolframInstitute`MathlibLink`"]

VerificationTest[MathlibInstallation["Directory" -> 42]["Tag"], "MathlibInvalidOption", TestID -> "directory-type-checked"]
VerificationTest[InstallMathlib["Unknown" -> True]["Tag"], "MathlibInvalidOption", TestID -> "installer-rejects-unknown-options"]
VerificationTest[MathlibInstallation[]["Toolchain"], "leanprover/lean4:v4.35.0", TestID -> "toolchain-pinned"]
VerificationTest[MathlibInstallation[]["Revision"], "56a005855ea17e0b0958f73ec801ae140b0a1679", TestID -> "mathlib-pinned"]
VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibVersionQ @@@ {{"1.2.5", "1.2.5"}, {"1.2.10", "1.2.5"}, {"1.2.4", "1.2.5"}},
	{True, True, False}, TestID -> "versions-compare-numerically"
]

VerificationTest[
	Block[{WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = (Throw["Unexpected process lookup"] &)},
		InstallMathlib["CancellationFunction" -> (True &)]["Tag"]
	], "MathlibInstallCancelled", TestID -> "cancellation-before-setup-starts-no-work"
]

VerificationTest[
	InstallMathlib["ProgressFunction" -> 42]["Tag"], "MathlibInvalidOption",
	TestID -> "invalid-progress-function-rejected"
]

VerificationTest[
	InstallMathlib["CancellationFunction" -> (Missing["Unknown"] &)]["Tag"], "MathlibInvalidCallback",
	TestID -> "cancellation-callback-must-return-boolean"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = ("/tool" &),
		WolframInstitute`MathlibLink`PackageScope`mathlibEnsureElan = (<|"Elan" -> "/tool", "Lake" -> "/tool"|> &),
		WolframInstitute`MathlibLink`PackageScope`mathlibEnsureGit = ("/tool" &),
		WolframInstitute`MathlibLink`PackageScope`mathlibInstallationReadyQ = (True &),
		PacletFind = ({PacletObject[<|"Name" -> "Wolfram/LeanLink", "Version" -> "1.2.5"|>]} &),
		PacletInstall = (Throw["Unexpected installation"] &), StartProcess = (Throw["Unexpected process"] &)
	}, With[{result = Reap[InstallMathlib["ProgressFunction" -> Function[{stage, fraction}, Sow[{stage, fraction}]]]]},
		{MatchQ[First[result], _File], Last[result]}
	]], {True, {{{"Preparing...", None}, {"Checking...", None}}}},
	TestID -> "ready-runtime-reports-stages-without-installing"
]

VerificationTest[
	Module[{temporary = CreateDirectory[], target, result},
		target = FileNameJoin[{temporary, "mathlib"}];
		WithCleanup[
			result = Block[{
				WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = ("/tool" &),
				WolframInstitute`MathlibLink`PackageScope`mathlibEnsureElan = (<|"Elan" -> "/tool", "Lake" -> "/tool"|> &),
				WolframInstitute`MathlibLink`PackageScope`mathlibEnsureGit = ("/tool" &),
				WolframInstitute`MathlibLink`PackageScope`mathlibInstallationReadyQ = (False &),
				WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun =
					(Throw[Failure["MathlibInstallCancelled", <||>], "MathlibInstall"] &),
				PacletFind = ({PacletObject[<|"Name" -> "Wolfram/LeanLink", "Version" -> "1.2.5"|>]} &)
			}, InstallMathlib["Directory" -> target]];
			{result["Tag"], DirectoryQ[target]},
			DeleteDirectory[temporary, DeleteContents -> True]
		]
	], {"MathlibInstallCancelled", False}, TestID -> "cancelled-clone-removes-only-new-owned-directory"
]

(* The Unix process fixture creates both a child and a grandchild. Each PID is
   supplied by that owned process; cleanup never targets unrelated processes. *)
installerProcessFixture[mode_String] := Module[{directory = CreateDirectory[], files, started = AbsoluteTime[], result, pids = {}, stopped},
	files = FileNameJoin[{directory, #}] & /@ {"child", "grandchild"};
	WithCleanup[
		result = Block[{WolframInstitute`MathlibLink`Installation`Private`$installCancellation = Function[Null,
			If[AllTrue[files, FileExistsQ] || AbsoluteTime[] - started > 5,
				If[mode === "Abort", Abort[], True], False]
		]}, CheckAbort[Catch[
			WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun[
				Join[{"/bin/sh", "-c", "sh -c 'sleep 30 & printf \"%s\\n\" \"$!\" > \"$1\"; wait' sh \"$2\" & printf '%s\\n' \"$!\" > \"$1\"; wait", "sh"}, files], directory],
			"MathlibInstall"
		], "Aborted"]];
		pids = Select[StringTrim[Import[#, "Text"]] & /@ Select[files, FileExistsQ], StringMatchQ[#, DigitCharacter ..] &];
		Pause[0.1];
		stopped = AllTrue[pids, RunProcess[{"/bin/kill", "-0", #}]["ExitCode"] =!= 0 &];
		{If[FailureQ[result], result["Tag"], result], Length[pids], stopped},
		Scan[Quiet[RunProcess[{"/bin/kill", "-KILL", #}]] &, pids];
		DeleteDirectory[directory, DeleteContents -> True]
	]
]

If[$OperatingSystem =!= "Windows",
	VerificationTest[installerProcessFixture["Cancel"], {"MathlibInstallCancelled", 2, True},
		TestID -> "cancellation-stops-owned-process-and-descendants"]
]

If[$OperatingSystem =!= "Windows",
	VerificationTest[installerProcessFixture["Abort"], {"Aborted", 2, True},
		TestID -> "abort-stops-owned-process-and-descendants"]
]

If[$OperatingSystem =!= "Windows",
	VerificationTest[
		KeyTake[WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun[
			{"/bin/sh", "-c", "printf 'out\\n'; printf 'err\\n' >&2; exit 7"}, Directory[]],
			{"ExitCode", "StandardOutput", "StandardError"}],
		<|"ExitCode" -> 7, "StandardOutput" -> "out\n", "StandardError" -> "err\n"|>,
		TestID -> "installer-process-drains-both-streams-and-exit-status"
	]
]
