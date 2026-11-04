PackageExported[{InstallMathlib, MathlibInstallation}]
PackageScoped[{mathlibInstallationReadyQ, mathlibLeanRelease, mathlibInstallLean, mathlibInstallRun, mathlibInstallStage, mathlibCheckCancellation, mathlibReportProgress}]

InstallMathlib::usage = "InstallMathlib[] installs the latest LeanLink and the pinned Lean and mathlib runtime. InstallMathlib[\"Directory\" -> path] uses a chosen directory."
MathlibInstallation::usage = "MathlibInstallation[] gives the mathlib installation status, versions and directory."
Options[InstallMathlib] = {"Directory" -> Automatic, "ProgressFunction" -> (Null &), "CancellationFunction" -> (False &)}
Options[MathlibInstallation] = {"Directory" -> Automatic}

$installProgress = (Null &)
$installCancellation = (False &)

mathlibCheckCancellation[] := With[{cancelled = Quiet[Check[$installCancellation[], $Failed]]},
	Which[
		TrueQ[cancelled], Throw[mathlibFailure["MathlibInstallCancelled", "Mathlib setup was cancelled. Run InstallMathlib[] to resume."], "MathlibInstall"],
		cancelled === False, Null,
		True, Throw[mathlibFailure["MathlibInvalidCallback", "CancellationFunction must return True or False."], "MathlibInstall"]
	]
]

mathlibReportProgress[stage_String, fraction_] := If[Quiet[Check[$installProgress[stage, fraction], $Failed]] === $Failed,
	mathlibFailure["MathlibInvalidCallback", "ProgressFunction could not report the setup stage."], Null
]

mathlibInstallStage[stage_String, fraction_ : None] := (
	mathlibCheckCancellation[];
	With[{reported = mathlibReportProgress[stage, fraction]}, If[FailureQ[reported], Throw[reported, "MathlibInstall"]]];
	mathlibCheckCancellation[]
)

(* Drain both pipes while polling, so a long cache download remains responsive.
   WithCleanup also stops the owned process on Throw, Abort or a callback error. *)
mathlibInstallRun[arguments_List, directory_String, extraEnvironment_Association : <||>] := Module[{process, out = "", err = "", read, stdout, stderr, newOut, newErr},
	mathlibCheckCancellation[];
	read[stream_] := Replace[ReadString[stream, EndOfBuffer], Except[_String] -> ""];
	process = Quiet[Check[StartProcess[arguments, ProcessDirectory -> directory,
		ProcessEnvironment -> mathlibEnvironment[extraEnvironment]], $Failed]];
	If[! MatchQ[process, _ProcessObject], Return[$Failed]];
	stdout = ProcessConnection[process, "StandardOutput"];
	stderr = ProcessConnection[process, "StandardError"];
	WithCleanup[
		While[True,
			mathlibCheckCancellation[];
			newOut = read[stdout];
			newErr = read[stderr];
			out = out <> newOut;
			err = err <> newErr;
			If[newOut === "" && newErr === "",
				(* The child can write and exit after the reads above. Drain
				   again after observing its exit, before accepting the result. *)
				If[ProcessStatus[process] =!= "Running",
					out = out <> read[stdout];
					err = err <> read[stderr];
					Break[]
				];
				Pause[0.1]
			]
		];
		mathlibCheckCancellation[];
		<|"ExitCode" -> ProcessInformation[process, "ExitCode"], "StandardOutput" -> out, "StandardError" -> err|>,
		If[ProcessStatus[process] === "Running", KillProcess[process]]
	]
]

mathlibInstallationReadyQ[directory_String] := Module[{marker, runtime = mathlibRuntime[], lean, manifest, git},
	marker = FileNameJoin[{directory, "mathliblink-installation.json"}];
	manifest = FileNameJoin[{directory, "lake-manifest.json"}];
	lean = FileNameJoin[{mathlibLeanDirectory[], "bin", "lean" <> If[$OperatingSystem === "Windows", ".exe", ""]}];
	git = mathlibExecutable["git"];
	And[
		StringQ[git],
		AllTrue[{marker, manifest, lean, FileNameJoin[{directory, "lean-toolchain"}], FileNameJoin[{directory, ".lake", "build", "lib", "lean", "Mathlib.olean"}]}, FileExistsQ],
		Quiet[Check[
			With[{stamp = Import[marker, "RawJSON"]},
				stamp["Revision"] === runtime["MathlibRevision"] &&
				StringTrim[Import[FileNameJoin[{directory, "lean-toolchain"}], "Text"]] === runtime["LeanToolchain"] &&
				stamp["ManifestSHA256"] === IntegerString[FileHash[manifest, "SHA256"], 16, 64]
			], False]],
		mathlibGitWorkingQ[git],
		With[{revision = mathlibRun[{git, "rev-parse", "HEAD"}, directory]}, AssociationQ[revision] && revision["ExitCode"] === 0 && StringTrim[revision["StandardOutput"]] === runtime["MathlibRevision"]],
		With[{changes = mathlibRun[{git, "diff", "--quiet", "HEAD"}, directory]}, AssociationQ[changes] && changes["ExitCode"] === 0],
		mathlibBridgeReadyQ[]
	]
]

MathlibInstallation[opts : OptionsPattern[]] := Module[{directory, runtime = mathlibRuntime[], status, installed},
	If[! mathlibOptionsQ[MathlibInstallation, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown installation option."]]];
	directory = mathlibDirectory[OptionValue["Directory"]];
	If[FailureQ[directory], Return[directory]];
	status = Which[mathlibInstallationReadyQ[directory], "Ready", DirectoryQ[directory], "Needs setup", True, "Not installed"];
	installed = First[PacletFind["Wolfram/LeanLink"], None];
	<|"Status" -> status, "Directory" -> directory, "MathlibDirectory" -> directory,
		"Toolchain" -> runtime["LeanToolchain"], "Revision" -> runtime["MathlibRevision"],
		"LeanLinkVersion" -> If[installed === None, Missing["NotInstalled"], installed["Version"]], "DocumentationURL" -> runtime["DocumentationURL"],
		"Executables" -> mathlibExecutables[], "PathDirectories" -> mathlibPathDirectories[]|>
]

InstallMathlib[opts : OptionsPattern[]] := Module[{directory, progress, cancellation},
	If[! mathlibOptionsQ[InstallMathlib, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown installation option."]]];
	directory = mathlibDirectory[OptionValue["Directory"]];
	If[FailureQ[directory], Return[directory]];
	{progress, cancellation} = {OptionValue["ProgressFunction"], OptionValue["CancellationFunction"]};
	If[! AllTrue[{progress, cancellation}, MatchQ[#, _Function | _Symbol] && ! MemberQ[{True, False, None, Null}, #] &],
		Return[mathlibFailure["MathlibInvalidOption", "ProgressFunction and CancellationFunction must be functions."]]
	];
	Catch[Block[{$ContextPath = $ContextPath, $installProgress = progress, $installCancellation = cancellation}, installMathlib[directory]], "MathlibInstall"]
]

(* Resolve the publisher's current resource on every explicit setup call. A
   cached installation or a lagging paclet-site index must not pin LeanLink. *)
mathlibLeanRelease[] := Module[{resource, latest},
	resource = Quiet[ResourceObject[CloudObject[mathlibRuntime[]["LeanLinkResource"]]]];
	mathlibCheckCancellation[];
	If[! MatchQ[resource, _ResourceObject],
		Return[mathlibFailure["LeanLinkUpdateCheckFailed", "The latest LeanLink release could not be checked. Retry InstallMathlib[]."]]
	];
	latest = Quiet[PacletObject[resource]];
	If[! MatchQ[latest, _PacletObject] || latest["Name"] =!= "Wolfram/LeanLink" || ! StringQ[latest["Version"]],
		Return[mathlibFailure["LeanLinkUpdateCheckFailed", "The published LeanLink paclet could not be read. Retry InstallMathlib[]."]]
	];
	<|"Resource" -> resource, "Paclet" -> latest|>
]

mathlibInstallLean[] := Module[{release, resource, latest, installed, result, loaded},
	mathlibInstallStage["Checking LeanLink..."];
	release = mathlibLeanRelease[];
	If[FailureQ[release], Return[release]];
	{resource, latest} = Lookup[release, {"Resource", "Paclet"}];
	If[TrueQ[$mathlibLeanNeedsRestart],
		Return[mathlibFailure["LeanLinkRestartRequired", "LeanLink was updated. Restart the kernel, then run InstallMathlib[] again."]]
	];
	installed = First[PacletFind["Wolfram/LeanLink"], None];
	If[installed =!= None && mathlibVersionQ[installed["Version"], latest["Version"]], Return[installed]];
	loaded = MemberQ[$Packages, "Wolfram`LeanLink`"];
	mathlibInstallStage["Installing LeanLink..."];
	result = Quiet[Check[PacletInstall[resource], $Failed]];
	If[MatchQ[result, _PacletObject] && loaded, $mathlibLeanNeedsRestart = True];
	mathlibCheckCancellation[];
	If[! MatchQ[result, _PacletObject],
		Return[mathlibFailure["LeanLinkInstallFailed", "LeanLink could not be installed.", <|"Result" -> result|>]]
	];
	If[loaded,
		Return[mathlibFailure["LeanLinkRestartRequired", "LeanLink was updated. Restart the kernel, then run InstallMathlib[] again.", <|"Version" -> result["Version"]|>]]
	];
	result
]

installMathlib[directory_String] := Module[{
	runtime = mathlibRuntime[], elan, lake, git, result, log, commands, head, parent, cloned = False
},
	mathlibInstallStage["Preparing..."];
	With[{tools = mathlibEnsureElan[]},
		If[FailureQ[tools], Return[tools]];
		{elan, lake} = Lookup[tools, {"Elan", "Lake"}]
	];
	git = mathlibEnsureGit[];
	If[FailureQ[git], Return[git]];
	With[{curl = mathlibEnsureCurl[]}, If[FailureQ[curl], Return[curl]]];
	result = mathlibInstallLean[];
	If[FailureQ[result], Return[result]];
	mathlibInstallStage["Checking..."];
	If[mathlibInstallationReadyQ[directory], mathlibCheckCancellation[]; Return[File[directory]]];
	parent = DirectoryName[directory];
	If[! DirectoryQ[parent], CreateDirectory[parent, CreateIntermediateDirectories -> True]];
	If[DirectoryQ[directory],
		If[! DirectoryQ[FileNameJoin[{directory, ".git"}]], Return[mathlibFailure["MathlibDirectoryInUse", "The selected directory is not a mathlib checkout. Choose another directory."]]];
		head = mathlibRun[{git, "rev-parse", "HEAD"}, directory];
		If[! AssociationQ[head] || head["ExitCode"] =!= 0 || StringTrim[head["StandardOutput"]] =!= runtime["MathlibRevision"],
			Return[mathlibFailure["MathlibRevisionMismatch", "The selected checkout has another revision. Choose a new directory for the pinned release.", <|"Directory" -> directory, "RequiredRevision" -> runtime["MathlibRevision"]|>]]
		],
		mathlibInstallStage["Downloading..."];
		If[! StringQ[Quiet[Check[CreateDirectory[directory], $Failed]]],
			Return[mathlibFailure["MathlibDirectoryInUse", "The selected directory could not be created.", <|"Directory" -> directory|>]]
		];
		WithCleanup[
			result = mathlibInstallRun[{git, "clone", "--branch", "v4.35.0", "--depth", "1", runtime["MathlibRepository"], directory}, parent];
			cloned = AssociationQ[result] && result["ExitCode"] === 0,
			If[! cloned && DirectoryQ[directory], DeleteDirectory[directory, DeleteContents -> True]]
		];
		If[! AssociationQ[result] || result["ExitCode"] =!= 0, Return[mathlibFailure["MathlibDownloadFailed", "The mathlib checkout could not be downloaded.", <|"Result" -> result|>]]];
		head = mathlibRun[{git, "rev-parse", "HEAD"}, directory];
		If[! AssociationQ[head] || StringTrim[head["StandardOutput"]] =!= runtime["MathlibRevision"],
			Return[mathlibFailure["MathlibRevisionMismatch", "The downloaded tag does not match the pinned revision."]]
		]
	];
	result = mathlibRun[{git, "diff", "--quiet", "HEAD"}, directory];
	If[! AssociationQ[result] || result["ExitCode"] =!= 0,
		Return[mathlibFailure["MathlibModifiedCheckout", "The checkout has local source changes. Choose another directory for the pinned release.", <|"Directory" -> directory|>]]
	];
	log = OpenWrite[FileNameJoin[{directory, "mathliblink-installation.log"}]];
	commands = {
		{"Downloading...", {elan, "toolchain", "install", runtime["LeanToolchain"]}},
		{"Downloading...", {lake, "+" <> runtime["LeanToolchain"], "exe", "cache", "get"}},
		{"Installing...", {lake, "+" <> runtime["LeanToolchain"], "build", "Mathlib"}}
	};
	WithCleanup[
		Do[With[{command = task[[2]]},
			mathlibInstallStage[task[[1]]];
			WriteString[log, StringRiffle[command, " "] <> "\n"];
			result = mathlibInstallRun[command, directory];
			If[AssociationQ[result], WriteString[log, result["StandardOutput"], result["StandardError"], "\n"]];
			If[! AssociationQ[result] || result["ExitCode"] =!= 0,
				Return[mathlibFailure["MathlibInstallFailed", "Mathlib setup did not finish. Rerun the installation after resolving the logged error.",
					<|"Command" -> command, "Log" -> File[FileNameJoin[{directory, "mathliblink-installation.log"}]], "Result" -> result|>]]
			]], {task, commands}
		];
		mathlibInstallStage["Checking..."];
		Export[FileNameJoin[{directory, "mathliblink-installation.json"}], <|"Revision" -> runtime["MathlibRevision"], "Toolchain" -> runtime["LeanToolchain"], "ManifestSHA256" -> IntegerString[FileHash[FileNameJoin[{directory, "lake-manifest.json"}], "SHA256"], 16, 64]|>, "RawJSON"];
		If[mathlibInstallationReadyQ[directory], File[directory], mathlibFailure["LeanLinkCompatibility", "Mathlib was built, but LeanLink could not load its runtime. Restart the kernel and rerun InstallMathlib[].", <|"Toolchain" -> runtime["LeanToolchain"], "URL" -> runtime["LeanLinkResource"]|>]],
		Close[log]
	]
]
