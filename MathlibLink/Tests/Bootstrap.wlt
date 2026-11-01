Needs["WolframInstitute`MathlibLink`"]

VerificationTest[
	Module[{runtime = Import[FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "Runtime.json"}], "RawJSON"]},
		runtime["ElanVersion"] === "4.2.4" && AllTrue[Values[runtime["ElanArchives"]],
			StringStartsQ[#["URL"], "https://github.com/leanprover/elan/releases/download/v4.2.4/"] &&
				StringMatchQ[#["SHA256"], RegularExpression["[0-9a-f]{64}"]] &]
	], True, TestID -> "elan-installers-have-pinned-official-urls-and-checksums"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`mathlibExecutable = ("/existing/" <> # &),
		WolframInstitute`MathlibLink`PackageScope`mathlibInstallRun = (<|"ExitCode" -> 0, "StandardOutput" -> "elan 4.2.4\n"|> &),
		WolframInstitute`MathlibLink`PackageScope`mathlibDownload = (Throw["Unexpected download"] &)
	}, WolframInstitute`MathlibLink`PackageScope`mathlibEnsureElan[]],
	<|"Elan" -> "/existing/elan", "Lake" -> "/existing/lake"|>, TestID -> "working-elan-and-proxy-reused-without-bootstrap"
]

VerificationTest[
	Module[{directory = CreateDirectory[], file, asset, result},
		file = FileNameJoin[{directory, "archive"}];
		Export[file, "verified archive fixture", "Text"];
		asset = <|"URL" -> "https://example.invalid/archive", "SHA256" -> IntegerString[FileHash[file, "SHA256"], 16, 64]|>;
		WithCleanup[
			result = Block[{URLDownloadSubmit = (Throw["Unexpected download"] &)},
				WolframInstitute`MathlibLink`PackageScope`mathlibDownload[asset, file]];
			result === file,
			DeleteDirectory[directory, DeleteContents -> True]
		]
	], True, TestID -> "verified-bootstrap-download-reused-without-network"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`Installation`Private`$installCancellation = (True &),
		URLDownloadSubmit = (Throw["Unexpected download"] &)
	}, Catch[WolframInstitute`MathlibLink`PackageScope`mathlibDownload[<||>, "unused"], "MathlibInstall"]["Tag"]],
	"MathlibInstallCancelled", TestID -> "bootstrap-cancellation-precedes-all-file-and-network-work"
]

VerificationTest[
	Module[{directory = CreateDirectory[], lake, elan, result},
		CreateDirectory[FileNameJoin[{directory, "bin"}]];
		{elan, lake} = FileNameJoin[{directory, "bin", # <> If[$OperatingSystem === "Windows", ".exe", ""]}] & /@ {"elan", "lake"};
		Export[elan, "fixture", "Text"]; Export[lake, "fixture", "Text"];
		WithCleanup[
			result = Block[{WolframInstitute`MathlibLink`PackageScope`mathlibElanHome = (directory &)},
				WolframInstitute`MathlibLink`PackageScope`mathlibExecutable /@ {"elan", "lake"}];
			result === {elan, lake},
			DeleteDirectory[directory, DeleteContents -> True]
		]
	], True, TestID -> "configured-elan-home-proxies-take-precedence-over-path"
]

VerificationTest[
	Module[{directory = CreateDirectory[], result},
		WithCleanup[
			result = Block[{WolframInstitute`MathlibLink`PackageScope`mathlibElanHome = (directory &)},
				WolframInstitute`MathlibLink`PackageScope`mathlibExecutable["lake"]];
			MatchQ[result, _Missing],
			DeleteDirectory[directory, DeleteContents -> True]
		]
	], True, TestID -> "missing-elan-proxy-does-not-use-unrelated-native-lake"
]

VerificationTest[
	Module[{before = GetEnvironment[], environment},
		environment = Block[{
			WolframInstitute`MathlibLink`PackageScope`mathlibElanHome = ("/local/elan" &),
			WolframInstitute`MathlibLink`PackageScope`mathlibPathDirectories = ({"/local/git/bin", "/local/elan/bin"} &)
		}, WolframInstitute`MathlibLink`PackageScope`mathlibEnvironment[<|"MATHLIB_TEST" -> "child-only"|>]];
		{environment["ELAN_HOME"], environment["MATHLIB_TEST"],
			StringStartsQ[environment["PATH"], StringRiffle[{"/local/git/bin", "/local/elan/bin"}, If[$OperatingSystem === "Windows", ";", ":"]]],
			GetEnvironment[] === before}
	], {"/local/elan", "child-only", True, True}, TestID -> "managed-tool-environment-is-confined-to-child-processes"
]
