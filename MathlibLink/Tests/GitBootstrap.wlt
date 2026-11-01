Needs["WolframInstitute`MathlibLink`"]

VerificationTest[
	Module[{manifest = Import[FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "GitBootstrap.json"}], "RawJSON"]},
		And[Length[manifest["Platforms"]] === 6,
			AllTrue[Values[manifest["Platforms"]], Function[platform,
				StringStartsQ[platform["Micromamba"]["URL"], "https://github.com/mamba-org/micromamba-releases/releases/download/2.10.0-0/"] &&
				StringMatchQ[platform["Micromamba"]["SHA256"], RegularExpression["[0-9a-f]{64}"]] &&
				Count[platform["Packages"], KeyValuePattern[{"Name" -> "git", "Version" -> "2.56.0"}]] === 1 &&
				AllTrue[platform["Packages"], StringStartsQ[#["URL"], "https://conda.anaconda.org/conda-forge/"] &&
					StringMatchQ[#["SHA256"], RegularExpression["[0-9a-f]{64}"]] &]
			]]]
	], True, TestID -> "git-bootstrap-pins-every-platform-and-package"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = (FileNameJoin[{$TemporaryDirectory, "existing-git"}] &),
		WolframInstitute`MathlibLink`PackageScope`mathlibGitWorkingQ = (True &),
		WolframInstitute`MathlibLink`PackageScope`mathlibInstallStage = (Null &),
		WolframInstitute`MathlibLink`PackageScope`mathlibDownload = (Throw["Unexpected download"] &)
	}, WolframInstitute`MathlibLink`PackageScope`mathlibEnsureGit[]],
	ExpandFileName[FileNameJoin[{$TemporaryDirectory, "existing-git"}]], TestID -> "working-git-reused-without-bootstrap"
]

If[$OperatingSystem === "MacOSX",
	VerificationTest[
		Block[{WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun = Function[{arguments, directory},
			Sow[arguments]; <|"ExitCode" -> 1, "StandardOutput" -> "", "StandardError" -> "No developer directory"|>]},
			Reap[WolframInstitute`MathlibLink`PackageScope`mathlibGitWorkingQ["/usr/bin/git"]]
		], {False, {{{"/usr/bin/xcode-select", "-p"}}}}, TestID -> "mac-git-launcher-not-invoked-without-developer-tools"
	]
]

gitBootstrapCancellationFixture[stage_String] := Module[{temporary = CreateDirectory[], result, sentinel},
	sentinel = FileNameJoin[{temporary, "unrelated.txt"}];
	Export[sentinel, "keep", "Text"];
	WithCleanup[
		result = Catch[Block[{
			WolframInstitute`MathlibLink`PackageScope`mathlibToolsDirectory = (temporary &),
			WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = (Missing["NotFound"] &),
			WolframInstitute`MathlibLink`PackageScope`mathlibGitWorkingQ = (False &),
			WolframInstitute`MathlibLink`PackageScope`mathlibInstallStage = (Null &),
			WolframInstitute`MathlibLink`PackageScope`mathlibDownload = Function[{asset, destination},
				If[stage === "Download", Throw[Failure["MathlibInstallCancelled", <||>], "MathlibInstall"]];
				Export[destination, "test fixture", "Text"]],
			WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun = Function[{arguments, directory},
				If[MemberQ[arguments, "create"], Throw[Failure["MathlibInstallCancelled", <||>], "MathlibInstall"]];
				<|"ExitCode" -> 0, "StandardOutput" -> "", "StandardError" -> ""|>]
		}, WolframInstitute`MathlibLink`PackageScope`mathlibEnsureGit[]], "MathlibInstall"];
		{result["Tag"], Import[sentinel, "Text"],
			FileNames["*.installing.json", temporary, Infinity],
			Select[FileNames["2.56.0-*", temporary, Infinity], DirectoryQ]},
		DeleteDirectory[temporary, DeleteContents -> True]
	]
]

VerificationTest[gitBootstrapCancellationFixture["Download"], {"MathlibInstallCancelled", "keep", {}, {}},
	TestID -> "git-download-cancellation-removes-only-owned-incomplete-prefix"]
VerificationTest[gitBootstrapCancellationFixture["Install"], {"MathlibInstallCancelled", "keep", {}, {}},
	TestID -> "git-process-cancellation-removes-only-owned-incomplete-prefix"]

VerificationTest[
	Module[{temporary = CreateDirectory[], file, prefix, before, expected, stream, result},
		file = FileNameJoin[{temporary, "environments.txt"}];
		prefix = FileNameJoin[{temporary, "Git With Spaces"}];
		before = ToCharacterCode["/other/first\r\n" <> prefix <> "\r\n\n" <> prefix <> "-other\n/other/last", "UTF8"];
		expected = ToCharacterCode["/other/first\r\n\n" <> prefix <> "-other\n/other/last", "UTF8"];
		WithCleanup[
			stream = OpenWrite[file, BinaryFormat -> True];
			WithCleanup[BinaryWrite[stream, before, "Byte"], Close[stream]];
			WolframInstitute`MathlibLink`PackageScope`mathlibGitRemoveRegistration[prefix, file];
			result = BinaryReadList[file, "Byte"];
			{result === expected, FileNames["*.mathliblink-*", temporary]},
			DeleteDirectory[temporary, DeleteContents -> True]
		]
	], {True, {}}, TestID -> "git-cancellation-registry-cleanup-preserves-all-unrelated-bytes"
]

VerificationTest[
	Module[{temporary = CreateDirectory[], manifest, platform, lock, prefix, sentinel, result},
		manifest = Import[FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "GitBootstrap.json"}], "RawJSON"];
		platform = manifest["Platforms"][$SystemID];
		lock = "@EXPLICIT\n" <> StringRiffle[(#["URL"] <> "#" <> #["SHA256"]) & /@ platform["Packages"], "\n"] <> "\n";
		prefix = FileNameJoin[{temporary, "Git", $SystemID, manifest["GitVersion"] <> "-" <> StringTake[Hash[lock, "SHA256", "HexString"], 12]}];
		CreateDirectory[prefix, CreateIntermediateDirectories -> True];
		sentinel = FileNameJoin[{prefix, "unrelated.txt"}];
		Export[sentinel, "keep", "Text"];
		WithCleanup[
			result = Catch[Block[{
				WolframInstitute`MathlibLink`PackageScope`mathlibToolsDirectory = (temporary &),
				WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = (Missing["NotFound"] &),
				WolframInstitute`MathlibLink`PackageScope`mathlibGitWorkingQ = (False &),
				WolframInstitute`MathlibLink`PackageScope`mathlibInstallStage = (Null &),
				WolframInstitute`MathlibLink`PackageScope`mathlibDownload = (Throw["Unexpected download"] &)
			}, WolframInstitute`MathlibLink`PackageScope`mathlibEnsureGit[]], "MathlibInstall"];
			{result["Tag"], Import[sentinel, "Text"]},
			DeleteDirectory[temporary, DeleteContents -> True]
		]
	], {"MathlibGitDirectoryInUse", "keep"}, TestID -> "git-bootstrap-preserves-unowned-prefix"
]
