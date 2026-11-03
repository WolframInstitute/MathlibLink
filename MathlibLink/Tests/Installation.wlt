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
	Module[{temporary = CreateDirectory[], directory, lean, manifest, runtime, result},
		directory = FileNameJoin[{temporary, "mathlib"}];
		lean = FileNameJoin[{temporary, "lean"}];
		runtime = <|"LeanToolchain" -> "leanprover/lean4:v4.35.0", "MathlibRevision" -> "fixture"|>;
		CreateDirectory[FileNameJoin[{directory, ".lake", "build", "lib", "lean"}], CreateIntermediateDirectories -> True];
		CreateDirectory[FileNameJoin[{lean, "bin"}], CreateIntermediateDirectories -> True];
		CreateFile[FileNameJoin[{directory, ".lake", "build", "lib", "lean", "Mathlib.olean"}]];
		CreateFile[FileNameJoin[{lean, "bin", "lean" <> If[$OperatingSystem === "Windows", ".exe", ""]}]];
		Export[FileNameJoin[{directory, "lean-toolchain"}], runtime["LeanToolchain"], "Text"];
		manifest = Export[FileNameJoin[{directory, "lake-manifest.json"}], <||>, "RawJSON"];
		Export[FileNameJoin[{directory, "mathliblink-installation.json"}],
			<|"Revision" -> "fixture", "ManifestSHA256" -> IntegerString[FileHash[manifest, "SHA256"], 16, 64]|>, "RawJSON"];
		WithCleanup[
			result = Block[{
				WolframInstitute`MathlibLink`PackageScope`mathlibRuntime = (runtime &),
				WolframInstitute`MathlibLink`PackageScope`mathlibLeanDirectory = (lean &),
				WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = ("git" &),
				WolframInstitute`MathlibLink`PackageScope`mathlibGitWorkingQ = (True &),
				WolframInstitute`MathlibLink`PackageScope`mathlibRun = Function[{arguments, workingDirectory},
					If[MemberQ[arguments, "diff"], <|"ExitCode" -> 1|>, <|"ExitCode" -> 0, "StandardOutput" -> "fixture\n"|>]],
				WolframInstitute`MathlibLink`PackageScope`mathlibBridgeReadyQ = (Throw["Unexpected native probe"] &)
			}, WolframInstitute`MathlibLink`PackageScope`mathlibInstallationReadyQ[directory]],
			DeleteDirectory[temporary, DeleteContents -> True]
		];
		result
	], False, TestID -> "modified-tracked-source-is-not-ready-despite-matching-pins-and-cache"
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
	Module[{before = $ContextPath, result},
		result = Block[{
			WolframInstitute`MathlibLink`PackageScope`mathlibEnsureElan = (<|"Elan" -> "/tool", "Lake" -> "/tool"|> &),
			WolframInstitute`MathlibLink`PackageScope`mathlibEnsureGit = ("/tool" &),
			WolframInstitute`MathlibLink`PackageScope`mathlibEnsureCurl = ("/tool" &),
			WolframInstitute`MathlibLink`PackageScope`mathlibInstallLean = Function[Null,
				AppendTo[$ContextPath, "InstallerFixture`"]; Failure["LeanLinkInstallFailed", <||>]]
		}, InstallMathlib[]];
		{result["Tag"], $ContextPath === before}
	], {"LeanLinkInstallFailed", True}, TestID -> "dependency-installation-preserves-caller-context-path"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = ("/tool" &),
		WolframInstitute`MathlibLink`PackageScope`mathlibEnsureElan = (<|"Elan" -> "/tool", "Lake" -> "/tool"|> &),
		WolframInstitute`MathlibLink`PackageScope`mathlibEnsureGit = ("/tool" &),
		WolframInstitute`MathlibLink`PackageScope`mathlibEnsureCurl = ("/tool" &),
		WolframInstitute`MathlibLink`PackageScope`mathlibInstallationReadyQ = (True &),
		WolframInstitute`MathlibLink`PackageScope`mathlibInstallLean = Function[Null, Sow["Checked latest LeanLink"]; True],
		StartProcess = (Throw["Unexpected process"] &)
	}, With[{result = Reap[InstallMathlib["ProgressFunction" -> Function[{stage, fraction}, Sow[{stage, fraction}]]]]},
		{MatchQ[First[result], _File], Last[result]}
	]], {True, {{{"Preparing...", None}, "Checked latest LeanLink", {"Checking...", None}}}},
	TestID -> "ready-mathlib-still-checks-latest-leanlink"
]

VerificationTest[
	Module[{temporary = CreateDirectory[], target, result},
		target = FileNameJoin[{temporary, "mathlib"}];
		WithCleanup[
			result = Block[{
				WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = ("/tool" &),
				WolframInstitute`MathlibLink`PackageScope`mathlibEnsureElan = (<|"Elan" -> "/tool", "Lake" -> "/tool"|> &),
				WolframInstitute`MathlibLink`PackageScope`mathlibEnsureGit = ("/tool" &),
				WolframInstitute`MathlibLink`PackageScope`mathlibEnsureCurl = ("/tool" &),
				WolframInstitute`MathlibLink`PackageScope`mathlibInstallationReadyQ = (False &),
				WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun =
					(Throw[Failure["MathlibInstallCancelled", <||>], "MathlibInstall"] &),
				WolframInstitute`MathlibLink`PackageScope`mathlibInstallLean = (True &)
			}, InstallMathlib["Directory" -> target]];
			{result["Tag"], DirectoryQ[target]},
			DeleteDirectory[temporary, DeleteContents -> True]
		]
	], {"MathlibInstallCancelled", False}, TestID -> "cancelled-clone-removes-only-new-owned-directory"
]

(* The publication changes independently of the installed mathlib checkout. *)
latestLeanFixture[version_, loaded_ : False, unavailable_ : False] := Module[{latest, checks = 0, installs = 0, result},
	latest = PacletObject[<|"Name" -> "Wolfram/LeanLink", "Version" -> "9.1.0"|>];
	result = Block[{
		$Packages = If[loaded, {"Wolfram`LeanLink`"}, {}],
		WolframInstitute`MathlibLink`PackageScope`$mathlibLeanNeedsRestart = False,
		WolframInstitute`MathlibLink`PackageScope`mathlibLeanRelease = Function[Null,
			checks++;
			If[unavailable, Failure["LeanLinkUpdateCheckFailed", <||>], <|"Resource" -> "latest-resource", "Paclet" -> latest|>]],
		PacletFind = Function[Null, If[version === None, {}, {PacletObject[<|"Name" -> "Wolfram/LeanLink", "Version" -> version|>]}]],
		PacletInstall = Function[source, If[source === "latest-resource", installs++; latest, $Failed]]
	}, WolframInstitute`MathlibLink`PackageScope`mathlibInstallLean[]];
	{If[FailureQ[result], result["Tag"], result["Version"]], checks, installs}
]

VerificationTest[latestLeanFixture[None], {"9.1.0", 1, 1}, TestID -> "missing-leanlink-installs-current-publication"]
VerificationTest[latestLeanFixture["9.0.0"], {"9.1.0", 1, 1}, TestID -> "installed-leanlink-updates-to-current-publication"]
VerificationTest[latestLeanFixture["9.1.0"], {"9.1.0", 1, 0}, TestID -> "current-leanlink-still-checks-publication-without-reinstalling"]
VerificationTest[latestLeanFixture["9.2.0"], {"9.2.0", 1, 0}, TestID -> "newer-local-leanlink-is-not-downgraded"]
VerificationTest[latestLeanFixture["9.0.0", True], {"LeanLinkRestartRequired", 1, 1}, TestID -> "updated-loaded-leanlink-requires-kernel-restart"]
VerificationTest[latestLeanFixture["9.1.0", True], {"9.1.0", 1, 0}, TestID -> "unchanged-loaded-leanlink-does-not-require-restart"]
VerificationTest[latestLeanFixture["9.1.0", False, True], {"LeanLinkUpdateCheckFailed", 1, 0}, TestID -> "failed-update-check-is-not-reported-as-current"]

VerificationTest[
	Block[{WolframInstitute`MathlibLink`PackageScope`$mathlibLeanNeedsRestart = True,
		Needs = (Throw["Unexpected reload"] &)},
		WolframInstitute`MathlibLink`PackageScope`mathlibLoadLean[]["Tag"]
	], "LeanLinkRestartRequired", TestID -> "loaded-native-library-is-not-reused-after-update"
]

(* kill -0 also succeeds for a dead Linux zombie awaiting its parent's wait.
   Inspect /proc on Linux; unknown or live states must still fail cleanup. *)
installerProcessState[pid_String] := Module[{file, status, states, result},
	If[StringStartsQ[$SystemID, "Linux"],
		file = FileNameJoin[{"/proc", pid, "status"}];
		status = Quiet[Check[ReadString[file], $Failed]];
		states = If[StringQ[status], StringCases[status, RegularExpression["(?m)^State:\\s+([A-Za-z])"] -> "$1"], {}];
		If[Length[states] === 1, Return[First[states]]];
		Return[If[DirectoryQ[DirectoryName[file]], "Unknown", "Absent"]]
	];
	result = Quiet[Check[RunProcess[{"/bin/kill", "-0", pid}], $Failed]];
	Which[
		AssociationQ[result] && result["ExitCode"] === 0, "Alive",
		AssociationQ[result] && result["ExitCode"] === 1, "Absent",
		True, "Unknown"
	]
]

installerTerminatedStateQ[state_] := MemberQ[{"Absent", "Z", "X"}, state]

installerWaitForTermination[pids_List] := Module[{deadline = AbsoluteTime[] + 2, states},
	states = installerProcessState /@ pids;
	While[! AllTrue[states, installerTerminatedStateQ] && AbsoluteTime[] < deadline,
		Pause[0.02];
		states = installerProcessState /@ pids
	];
	states
]

(* The Unix process fixture creates both a child and a grandchild. Each PID is
   supplied by that owned process; cleanup never targets unrelated processes. *)
installerProcessFixture[mode_String] := Module[{directory = CreateDirectory[], files, started = AbsoluteTime[], result, pids = {}, states},
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
		states = installerWaitForTermination[pids];
		Print["Installer owned descendants (", mode, "): ", AssociationThread[pids, states]];
		{If[FailureQ[result], result["Tag"], result], Length[pids], AllTrue[states, installerTerminatedStateQ]},
		Scan[Quiet[RunProcess[{"/bin/kill", "-KILL", #}]] &, pids];
		DeleteDirectory[directory, DeleteContents -> True]
	]
]

If[$OperatingSystem =!= "Windows",
	VerificationTest[
		Module[{process, pid, before, after},
			process = StartProcess[{"/bin/sh", "-c", "printf '%s\\n' \"$$\"; exec sleep 30"}];
			WithCleanup[
				pid = TimeConstrained[ReadLine[process], 3, $TimedOut];
				If[! StringQ[pid] || ! StringMatchQ[pid, DigitCharacter ..], Return[{pid, False}]];
				before = installerTerminatedStateQ[installerProcessState[pid]];
				KillProcess[process];
				after = AllTrue[installerWaitForTermination[{pid}], installerTerminatedStateQ];
				{before, after},
				If[ProcessStatus[process] === "Running", KillProcess[process]]
			]
		], {False, True}, TestID -> "cleanup-check-distinguishes-live-process-from-terminated-process"
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

If[$OperatingSystem =!= "Windows",
	VerificationTest[
		Module[{out = StringRepeat["o", 256], err = StringRepeat["e", 256], result},
			result = WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun[
				{"/bin/sh", "-c", "i=0; while [ $i -lt 4096 ]; do printf '" <> out <>
					"'; printf '" <> err <> "' >&2; i=$((i+1)); done; exit 7"}, Directory[]];
			result === <|"ExitCode" -> 7, "StandardOutput" -> StringRepeat[out, 4096], "StandardError" -> StringRepeat[err, 4096]|>
		],
		True, TestID -> "installer-process-keeps-large-logs-on-both-streams"
	]
]
