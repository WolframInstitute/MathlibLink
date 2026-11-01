PackageScoped[{mathlibEnsureElan, mathlibDownload}]

(* Downloads run as cancellable tasks. Only checksum-verified archives enter
   the tools cache; no shell, compiler or package manager is needed to fetch them. *)
mathlibDownload[asset_Association, file_String] := Module[{result, attempt = 0},
	mathlibCheckCancellation[];
	If[FileExistsQ[file] && IntegerString[FileHash[file, "SHA256"], 16, 64] === asset["SHA256"], Return[file]];
	If[! DirectoryQ[DirectoryName[file]], CreateDirectory[DirectoryName[file], CreateIntermediateDirectories -> True]];
	While[attempt < 3,
		mathlibInstallStage[If[attempt === 0, "Downloading...", "Retrying..."]];
		result = downloadToolArchive[asset, file];
		If[StringQ[result], Return[result]];
		attempt++
	];
	Throw[result, "MathlibInstall"]
]

downloadToolArchive[asset_Association, file_String] := Module[{task = None, response = <||>, progress = Null, complete = False},
	WithCleanup[
		task = Quiet[Check[URLDownloadSubmit[asset["URL"], file,
			TimeConstraint -> <|"Connecting" -> 30, "Reading" -> Infinity|>, ProgressReporting -> False,
			HandlerFunctions -> <|
				"TaskProgress" -> Function[event,
					progress = mathlibReportProgress["Downloading...", Replace[Lookup[event, "FractionComplete", None], Except[_?NumberQ] -> None]]
				],
				"TaskFinished" -> Function[event, response = event]
			|>, HandlerFunctionsKeys -> {"StatusCode", "Failure", "FractionComplete"}
		], $Failed]];
		If[! MatchQ[task, _TaskObject], Return[mathlibFailure["MathlibDownloadFailed", "The tool archive could not be downloaded.", <|"URL" -> asset["URL"]|>]]];
		While[task["TaskStatus"] =!= "Removed",
			mathlibCheckCancellation[];
			If[FailureQ[progress], Throw[progress, "MathlibInstall"]];
			Pause[0.1]
		];
		If[FailureQ[progress], Throw[progress, "MathlibInstall"]];
		If[FailureQ[Lookup[response, "Failure", None]] || ! TrueQ[200 <= Lookup[response, "StatusCode", None] < 400] || ! FileExistsQ[file],
			Return[mathlibFailure["MathlibDownloadFailed", "The tool archive could not be downloaded.", <|"URL" -> asset["URL"], "Result" -> response|>]]
		];
		If[IntegerString[FileHash[file, "SHA256"], 16, 64] =!= asset["SHA256"],
			Return[mathlibFailure["MathlibDownloadChecksum", "The downloaded tool archive does not match its pinned checksum.", <|"URL" -> asset["URL"]|>]]
		];
		complete = True;
		mathlibCheckCancellation[];
		file,
		If[MatchQ[task, _TaskObject] && task["TaskStatus"] =!= "Removed", TaskRemove[task]];
		If[! complete && FileExistsQ[file], DeleteFile[file]]
	]
]

mathlibEnsureElan[] := Module[{elan, lake, checked, asset, archive, temporary, installer, result},
	{elan, lake} = mathlibExecutable /@ {"elan", "lake"};
	If[StringQ[elan] && StringQ[lake],
		checked = mathlibInstallRun[{elan, "--version"}, $TemporaryDirectory];
		If[AssociationQ[checked] && checked["ExitCode"] === 0 && StringStartsQ[StringTrim[checked["StandardOutput"]], "elan "],
			Return[<|"Elan" -> elan, "Lake" -> lake|>]
		]
	];
	asset = Lookup[mathlibRuntime[]["ElanArchives"], $SystemID, None];
	If[! AssociationQ[asset], Return[mathlibFailure["MathlibUnsupportedPlatform", "No pinned elan installer is available for this system.", <|"SystemID" -> $SystemID|>]]];
	archive = mathlibDownload[asset, FileNameJoin[{mathlibToolsDirectory[], "Downloads", Last[StringSplit[asset["URL"], "/"]]}]];
	temporary = CreateDirectory[];
	WithCleanup[
		mathlibInstallStage["Installing..."];
		result = Quiet[Check[ExtractArchive[archive, temporary], $Failed]];
		installer = FileNameJoin[{temporary, "elan-init" <> If[$OperatingSystem === "Windows", ".exe", ""]}];
		If[result === $Failed || ! FileExistsQ[installer], Return[mathlibFailure["MathlibElanInstallFailed", "The elan installer could not be extracted."]]];
		If[$OperatingSystem =!= "Windows",
			result = mathlibInstallRun[{"/bin/chmod", "u+x", installer}, temporary];
			If[! AssociationQ[result] || result["ExitCode"] =!= 0, Return[mathlibFailure["MathlibElanInstallFailed", "The elan installer could not be made executable."]]]
		];
		result = mathlibInstallRun[{installer, "-y", "--no-modify-path", "--default-toolchain", "none"}, temporary];
		If[! AssociationQ[result] || result["ExitCode"] =!= 0, Return[mathlibFailure["MathlibElanInstallFailed", "The local elan installation did not finish.", <|"Result" -> result|>]]];
		{elan, lake} = FileNameJoin[{mathlibElanHome[], "bin", # <> If[$OperatingSystem === "Windows", ".exe", ""]}] & /@ {"elan", "lake"};
		checked = mathlibInstallRun[{elan, "--version"}, temporary];
		If[! FileExistsQ[lake] || ! AssociationQ[checked] || checked["ExitCode"] =!= 0,
			Return[mathlibFailure["MathlibElanInstallFailed", "The installed elan tools could not run.", <|"Result" -> checked|>]]
		];
		<|"Elan" -> elan, "Lake" -> lake|>,
		DeleteDirectory[temporary, DeleteContents -> True]
	]
]
