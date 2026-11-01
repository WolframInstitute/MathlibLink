Needs["WolframInstitute`MathlibLink`"]

VerificationTest[
	Module[{manifest = Import[FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "ToolBootstrap.json"}], "RawJSON"]},
		And[Length[manifest["Platforms"]] === 6,
			AllTrue[Values[manifest["Platforms"]], Function[platform,
				StringStartsQ[platform["Micromamba"]["URL"], "https://github.com/mamba-org/micromamba-releases/releases/download/2.10.0-0/"] &&
				StringMatchQ[platform["Micromamba"]["SHA256"], RegularExpression["[0-9a-f]{64}"]] &&
				Count[platform["Packages"]["git"], KeyValuePattern[{"Name" -> "git", "Version" -> "2.56.0"}]] === 1 &&
				AllTrue[platform["Packages"]["git"], StringStartsQ[#["URL"], "https://conda.anaconda.org/conda-forge/"] &&
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

toolBootstrapCancellationFixture[stage_String, name_String : "git"] := Module[{temporary = CreateDirectory[], result, sentinel},
	sentinel = FileNameJoin[{temporary, "unrelated.txt"}];
	Export[sentinel, "keep", "Text"];
	WithCleanup[
		result = Catch[Block[{
			WolframInstitute`MathlibLink`PackageScope`mathlibToolsDirectory = (temporary &),
			WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = (Missing["NotFound"] &),
			WolframInstitute`MathlibLink`PackageScope`mathlibGitWorkingQ = (False &),
			WolframInstitute`MathlibLink`PackageScope`mathlibCurlWorkingQ = (False &),
			WolframInstitute`MathlibLink`PackageScope`mathlibInstallStage = (Null &),
			WolframInstitute`MathlibLink`PackageScope`mathlibDownload = Function[{asset, destination},
				If[stage === "Download", Throw[Failure["MathlibInstallCancelled", <||>], "MathlibInstall"]];
				Export[destination, "test fixture", "Text"]],
			WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun = Function[{arguments, directory},
				If[MemberQ[arguments, "create"], Throw[Failure["MathlibInstallCancelled", <||>], "MathlibInstall"]];
				<|"ExitCode" -> 0, "StandardOutput" -> "", "StandardError" -> ""|>]
		}, If[name === "git", WolframInstitute`MathlibLink`PackageScope`mathlibEnsureGit[], WolframInstitute`MathlibLink`PackageScope`mathlibEnsureCurl[]]], "MathlibInstall"];
		{result["Tag"], Import[sentinel, "Text"],
			FileNames["*.installing.json", temporary, Infinity],
			Select[FileNames[If[name === "git", "2.56.0-*", "8.23.0-*"], temporary, Infinity], DirectoryQ]},
		DeleteDirectory[temporary, DeleteContents -> True]
	]
]

VerificationTest[toolBootstrapCancellationFixture["Download"], {"MathlibInstallCancelled", "keep", {}, {}},
	TestID -> "git-download-cancellation-removes-only-owned-incomplete-prefix"]
VerificationTest[toolBootstrapCancellationFixture["Install"], {"MathlibInstallCancelled", "keep", {}, {}},
	TestID -> "git-process-cancellation-removes-only-owned-incomplete-prefix"]

VerificationTest[toolBootstrapCancellationFixture["Download", "curl"], {"MathlibInstallCancelled", "keep", {}, {}},
	TestID -> "curl-download-cancellation-removes-only-owned-incomplete-prefix"]
VerificationTest[toolBootstrapCancellationFixture["Install", "curl"], {"MathlibInstallCancelled", "keep", {}, {}},
	TestID -> "curl-process-cancellation-removes-only-owned-incomplete-prefix"]

VerificationTest[
	Module[{manifest = Import[FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "ToolBootstrap.json"}], "RawJSON"]},
		manifest["Versions"]["curl"] === "8.23.0" && AllTrue[Values[manifest["Platforms"]],
			Count[#["Packages"]["curl"], KeyValuePattern[{"Name" -> "curl", "Version" -> "8.23.0"}]] === 1 &&
				AllTrue[#["Packages"]["curl"], StringStartsQ[#["URL"], "https://conda.anaconda.org/conda-forge/"] &&
					StringMatchQ[#["SHA256"], RegularExpression["[0-9a-f]{64}"]] &] &]
	], True, TestID -> "curl-and-all-transitive-packages-pinned-on-every-platform"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = Function[name,
			If[name === "curl", FileNameJoin[{$TemporaryDirectory, "existing-curl"}], Throw["Unexpected Git lookup"]]],
		WolframInstitute`MathlibLink`PackageScope`mathlibCurlWorkingQ = (True &),
		WolframInstitute`MathlibLink`PackageScope`mathlibInstallStage = (Null &),
		WolframInstitute`MathlibLink`PackageScope`mathlibDownload = (Throw["Unexpected download"] &)
	}, WolframInstitute`MathlibLink`PackageScope`mathlibEnsureCurl[]],
	ExpandFileName[FileNameJoin[{$TemporaryDirectory, "existing-curl"}]], TestID -> "working-curl-reused-independently-of-git"
]

VerificationTest[
	Function[output, Block[{
		WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun = (<|"ExitCode" -> 0, "StandardOutput" -> output|> &)
	}, WolframInstitute`MathlibLink`PackageScope`mathlibCurlWorkingQ["curl"]]] /@ {
		"curl 8.23.0 (fixture)\nProtocols: file http https\n",
		"curl 7.83.0 (fixture)\nProtocols: http https\n",
		"curl 8.23.0 (fixture)\nProtocols: file http\n"
	}, {True, False, False}, TestID -> "curl-must-support-cache-options-and-https"
]

toolPathResolutionFixture[privateQ_] :=
	Module[{temporary = CreateDirectory[], system, selected, suffix, environment, directories, resolved},
		system = CreateDirectory[FileNameJoin[{temporary, "system"}]];
		selected = CreateDirectory[FileNameJoin[{temporary, "selected-curl"}]];
		suffix = If[$OperatingSystem === "Windows", ".exe", ""];
		Scan[CreateFile, {FileNameJoin[{system, "git" <> suffix}], FileNameJoin[{system, "curl" <> suffix}], FileNameJoin[{selected, "curl" <> suffix}]}];
		WithCleanup[
			environment = Block[{
				WolframInstitute`MathlibLink`PackageScope`mathlibExecutables = (<|"Git" -> FileNameJoin[{system, "git" <> suffix}], "Curl" -> FileNameJoin[{selected, "curl" <> suffix}]|> &),
				WolframInstitute`MathlibLink`PackageScope`mathlibToolPathDirectories = (If[privateQ, {selected}, {}] &)
			}, WolframInstitute`MathlibLink`PackageScope`mathlibEnvironment[]];
			directories = StringSplit[environment["PATH"], If[$OperatingSystem === "Windows", ";", ":"]];
			resolved = Function[name, SelectFirst[FileNameJoin[{#, name <> suffix}] & /@ directories, FileExistsQ]] /@ {"git", "curl"};
			resolved === {FileNameJoin[{system, "git" <> suffix}], FileNameJoin[{selected, "curl" <> suffix}]},
			DeleteDirectory[temporary, DeleteContents -> True]
		]
]

VerificationTest[toolPathResolutionFixture[True], True,
	TestID -> "child-path-uses-private-curl-before-older-curl-beside-working-git"
]
VerificationTest[toolPathResolutionFixture[False], True,
	TestID -> "child-path-preserves-existing-curl-selection-beside-working-git"
]

VerificationTest[
	Module[{temporary = CreateDirectory[], file, prefix, before, expected, stream, result},
		file = FileNameJoin[{temporary, "environments.txt"}];
		prefix = FileNameJoin[{temporary, "Git With Spaces"}];
		before = ToCharacterCode["/other/first\r\n" <> prefix <> "\r\n\n" <> prefix <> "-other\n/other/last", "UTF8"];
		expected = ToCharacterCode["/other/first\r\n\n" <> prefix <> "-other\n/other/last", "UTF8"];
		WithCleanup[
			stream = OpenWrite[file, BinaryFormat -> True];
			WithCleanup[BinaryWrite[stream, before, "Byte"], Close[stream]];
			WolframInstitute`MathlibLink`PackageScope`mathlibRemoveToolRegistration[prefix, file];
			result = BinaryReadList[file, "Byte"];
			{result === expected, FileNames["*.mathliblink-*", temporary]},
			DeleteDirectory[temporary, DeleteContents -> True]
		]
	], {True, {}}, TestID -> "git-cancellation-registry-cleanup-preserves-all-unrelated-bytes"
]

VerificationTest[
	Module[{temporary = CreateDirectory[], manifest, platform, lock, prefix, sentinel, result},
		manifest = Import[FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "ToolBootstrap.json"}], "RawJSON"];
		platform = manifest["Platforms"][$SystemID];
		lock = "@EXPLICIT\n" <> StringRiffle[(#["URL"] <> "#" <> #["SHA256"]) & /@ platform["Packages"]["git"], "\n"] <> "\n";
		prefix = FileNameJoin[{temporary, "Git", $SystemID, manifest["Versions"]["git"] <> "-" <> StringTake[Hash[lock, "SHA256", "HexString"], 12]}];
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
