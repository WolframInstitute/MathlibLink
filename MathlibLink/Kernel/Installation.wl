PackageExported[{InstallMathlib, MathlibInstallation}]
PackageScoped[mathlibInstallationReadyQ]

InstallMathlib::usage = "InstallMathlib[] installs the pinned Lean, LeanLink and mathlib releases. InstallMathlib[\"Directory\" -> path] uses a chosen directory."
MathlibInstallation::usage = "MathlibInstallation[] gives the mathlib installation status, versions and directory."
Options[InstallMathlib] = {"Directory" -> Automatic}
Options[MathlibInstallation] = Options[InstallMathlib]

mathlibInstallationReadyQ[directory_String] := And[
	FileExistsQ[FileNameJoin[{directory, "mathliblink-installation.json"}]],
	FileExistsQ[FileNameJoin[{directory, ".lake", "build", "lib", "lean", "Mathlib.olean"}]],
	Quiet[Check[Import[FileNameJoin[{directory, "mathliblink-installation.json"}], "RawJSON"]["Revision"] === mathlibRuntime[]["MathlibRevision"], False]]
]

MathlibInstallation[opts : OptionsPattern[]] := Module[{directory, runtime = mathlibRuntime[], status},
	If[! mathlibOptionsQ[MathlibInstallation, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown installation option."]]];
	directory = mathlibDirectory[OptionValue["Directory"]];
	If[FailureQ[directory], Return[directory]];
	status = Which[mathlibInstallationReadyQ[directory], "Ready", DirectoryQ[directory], "Needs setup", True, "Not installed"];
	<|"Status" -> status, "Directory" -> directory, "MathlibDirectory" -> directory,
		"Toolchain" -> runtime["LeanToolchain"], "Revision" -> runtime["MathlibRevision"],
		"LeanLinkMinimumVersion" -> runtime["LeanLinkMinimumVersion"], "DocumentationURL" -> runtime["DocumentationURL"]|>
]

InstallMathlib[opts : OptionsPattern[]] := Module[{
	directory, runtime = mathlibRuntime[], elan, lake, git, result, installed, log, commands, head, parent
},
	If[! mathlibOptionsQ[InstallMathlib, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown installation option."]]];
	directory = mathlibDirectory[OptionValue["Directory"]];
	If[FailureQ[directory], Return[directory]];
	{elan, lake, git} = mathlibExecutable /@ {"elan", "lake", "git"};
	If[! AllTrue[{elan, lake, git}, StringQ], Return[mathlibFailure["MathlibSetupRequired", "Install elan and Git, then run InstallMathlib[] again.", <|"URL" -> "https://lean-lang.org/install/"|>]]];
	installed = PacletFind["Wolfram/LeanLink"];
	If[installed === {} || ! mathlibVersionQ[First[installed]["Version"], runtime["LeanLinkMinimumVersion"]],
		result = Quiet[Check[PacletInstall[runtime["LeanLinkArchive"]], $Failed]];
		If[! MatchQ[result, _PacletObject], Return[mathlibFailure["LeanLinkInstallFailed", "LeanLink could not be installed.", <|"Result" -> result|>]]]
	];
	If[mathlibInstallationReadyQ[directory], Return[File[directory]]];
	parent = DirectoryName[directory];
	If[! DirectoryQ[parent], CreateDirectory[parent, CreateIntermediateDirectories -> True]];
	If[DirectoryQ[directory],
		If[! DirectoryQ[FileNameJoin[{directory, ".git"}]], Return[mathlibFailure["MathlibDirectoryInUse", "The selected directory is not a mathlib checkout. Choose another directory."]]];
		head = mathlibRun[{git, "rev-parse", "HEAD"}, directory];
		If[! AssociationQ[head] || head["ExitCode"] =!= 0 || StringTrim[head["StandardOutput"]] =!= runtime["MathlibRevision"],
			Return[mathlibFailure["MathlibRevisionMismatch", "The selected checkout has another revision. Choose a new directory for the pinned release.", <|"Directory" -> directory, "RequiredRevision" -> runtime["MathlibRevision"]|>]]
		],
		result = mathlibRun[{git, "clone", "--branch", "v4.35.0", "--depth", "1", runtime["MathlibRepository"], directory}, parent];
		If[! AssociationQ[result] || result["ExitCode"] =!= 0, Return[mathlibFailure["MathlibDownloadFailed", "The mathlib checkout could not be downloaded.", <|"Result" -> result|>]]];
		head = mathlibRun[{git, "rev-parse", "HEAD"}, directory];
		If[! AssociationQ[head] || StringTrim[head["StandardOutput"]] =!= runtime["MathlibRevision"],
			Return[mathlibFailure["MathlibRevisionMismatch", "The downloaded tag does not match the pinned revision."]]
		]
	];
	log = OpenWrite[FileNameJoin[{directory, "mathliblink-installation.log"}]];
	commands = {
		{elan, "toolchain", "install", runtime["LeanToolchain"]},
		{lake, "+" <> runtime["LeanToolchain"], "exe", "cache", "get"},
		{lake, "+" <> runtime["LeanToolchain"], "build", "Mathlib"}
	};
	WithCleanup[
		Do[
			WriteString[log, StringRiffle[command, " "] <> "\n"];
			result = mathlibRun[command, directory];
			If[AssociationQ[result], WriteString[log, result["StandardOutput"], result["StandardError"], "\n"]];
			If[! AssociationQ[result] || result["ExitCode"] =!= 0,
				Return[mathlibFailure["MathlibInstallFailed", "Mathlib setup did not finish. Rerun the installation after resolving the logged error.",
					<|"Command" -> command, "Log" -> File[FileNameJoin[{directory, "mathliblink-installation.log"}]], "Result" -> result|>]]
			], {command, commands}
		];
		Export[FileNameJoin[{directory, "mathliblink-installation.json"}], <|"Revision" -> runtime["MathlibRevision"], "Toolchain" -> runtime["LeanToolchain"]|>, "RawJSON"];
		If[mathlibInstallationReadyQ[directory], File[directory], mathlibFailure["MathlibInstallFailed", "The Mathlib module was not produced by the build."]],
		Close[log]
	]
]
