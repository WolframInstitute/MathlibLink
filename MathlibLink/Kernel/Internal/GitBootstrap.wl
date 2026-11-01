PackageScoped[{mathlibEnsureGit, mathlibManagedGit, mathlibGitPathDirectories, mathlibGitWorkingQ, mathlibGitRemoveRegistration}]

gitBootstrapData[] := gitBootstrapData[] = Import[
	FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "GitBootstrap.json"}], "RawJSON"]

gitPlatform[] := Lookup[gitBootstrapData[]["Platforms"], $SystemID, Missing["UnsupportedPlatform", $SystemID]]
gitLock[platform_Association] := "@EXPLICIT\n" <> StringRiffle[(#["URL"] <> "#" <> #["SHA256"]) & /@ platform["Packages"], "\n"] <> "\n"
gitPrefix[] := With[{platform = gitPlatform[]},
	If[! AssociationQ[platform], Return[Missing["UnsupportedPlatform", $SystemID]]];
	FileNameJoin[{mathlibToolsDirectory[], "Git", $SystemID,
		gitBootstrapData[]["GitVersion"] <> "-" <> StringTake[Hash[gitLock[platform], "SHA256", "HexString"], 12]}]
]
gitExecutable[prefix_String] := FileNameJoin[Join[{prefix}, If[$OperatingSystem === "Windows", {"Library", "bin", "git.exe"}, {"bin", "git"}]]]
gitStamp[prefix_String] := <|"Owner" -> "WolframInstitute/MathlibLink", "Prefix" -> prefix,
	"Version" -> gitBootstrapData[]["GitVersion"], "SystemID" -> $SystemID,
	"PackagesSHA256" -> Hash[gitLock[gitPlatform[]], "SHA256", "HexString"]|>
gitStampQ[file_String, stamp_Association] := FileExistsQ[file] && Quiet[Check[Import[file, "RawJSON"] === stamp, False]]

mathlibManagedGit[] := With[{prefix = gitPrefix[]},
	If[StringQ[prefix] && FileExistsQ[gitExecutable[prefix]] &&
		gitStampQ[FileNameJoin[{prefix, "mathliblink-git.json"}], gitStamp[prefix]],
		gitExecutable[prefix], Missing["NotInstalled", "Git"]]
]

gitPathDirectories[prefix_String] := Select[
	FileNameJoin[Prepend[#, prefix]] & /@ If[$OperatingSystem === "Windows",
		{{"Library", "bin"}, {"Library", "mingw64", "bin"}, {"Library", "clangarm64", "bin"}, {"Library", "usr", "bin"}, {"bin"}},
		{{"bin"}}], DirectoryQ]
mathlibGitPathDirectories[] := If[StringQ[mathlibManagedGit[]], gitPathDirectories[gitPrefix[]], {}]
gitEnvironment[prefix_String] := With[{separator = If[$OperatingSystem === "Windows", ";", ":"]},
	<|"PATH" -> StringRiffle[DeleteDuplicates[Join[gitPathDirectories[prefix],
		StringSplit[Replace[Environment["PATH"], Except[_String] -> ""], separator]]], separator]|>
]

(* Apple's /usr/bin/git can launch the developer-tools installer. Check the
   selected developer directory first, without invoking that launcher. *)
mathlibGitWorkingQ[path_String, environment_Association : <||>] := Module[{result},
	If[$OperatingSystem === "MacOSX" && path === "/usr/bin/git",
		result = TimeConstrained[mathlibInstallRun[{"/usr/bin/xcode-select", "-p"}, Directory[]], 10, $Failed];
		If[! AssociationQ[result] || result["ExitCode"] =!= 0, Return[False]]
	];
	result = TimeConstrained[mathlibInstallRun[{path, "--version"}, Directory[], environment], 10, $Failed];
	AssociationQ[result] && result["ExitCode"] === 0 && StringStartsQ[StringTrim[result["StandardOutput"]], "git version "]
]
mathlibGitWorkingQ[_, ___] := False

gitInstallFailure[tag_String, message_String, data_Association : <||>] := Throw[mathlibFailure[tag, message, data], "MathlibInstall"]
gitCreateDirectory[path_String] := If[! DirectoryQ[path] && ! StringQ[Quiet[Check[CreateDirectory[path, CreateIntermediateDirectories -> True], $Failed]]],
	gitInstallFailure["MathlibGitDirectory", "The local Git directory could not be created.", <|"Directory" -> path|>]]
gitExport[file_String, value_, format_String] := If[! StringQ[Quiet[Check[Export[file, value, format], $Failed]]],
	gitInstallFailure["MathlibGitDirectory", "The local Git installation metadata could not be written.", <|"File" -> file|>]]

(* Micromamba registers even download-only prefixes. Preserve unrelated bytes
   and leave a concurrently changed registry untouched. Cleanup is best effort. *)
mathlibGitRemoveRegistration[prefix_String, registry_ : Automatic] := Module[{file, bytes, target, variants, remaining, temporary, stream},
	file = Replace[registry, Automatic -> FileNameJoin[{$HomeDirectory, ".conda", "environments.txt"}]];
	If[! StringQ[file] || ! FileExistsQ[file], Return[Null]];
	bytes = Quiet[Check[BinaryReadList[file, "Byte"], $Failed]];
	If[! VectorQ[bytes, IntegerQ], Return[Null]];
	target = ToCharacterCode[prefix, "UTF8"];
	variants = {target, Append[target, 10], Join[target, {13, 10}]};
	remaining = Flatten[Select[Split[bytes, #1 =!= 10 &], ! MemberQ[variants, #] &]];
	If[remaining === bytes, Return[Null]];
	temporary = file <> ".mathliblink-" <> CreateUUID[];
	WithCleanup[
		stream = Quiet[Check[OpenWrite[temporary, BinaryFormat -> True], $Failed]];
		If[! MatchQ[stream, _OutputStream], Return[Null]];
		WithCleanup[Quiet[BinaryWrite[stream, remaining, "Byte"]], Close[stream]];
		If[Quiet[Check[BinaryReadList[temporary, "Byte"], $Failed]] === remaining &&
			Quiet[Check[BinaryReadList[file, "Byte"], $Failed]] === bytes,
			Quiet[RenameFile[temporary, file, OverwriteTarget -> True]]
		];
		Null,
		If[FileExistsQ[temporary], Quiet[DeleteFile[temporary]]]
	]
]

mathlibEnsureGit[] := Module[{
	candidate, platform, prefix, base, stamp, ownership, root, config, lock, executable, mamba, asset, command, result, complete = False
},
	mathlibInstallStage["Checking..."];
	candidate = mathlibExecutable["git"];
	If[mathlibGitWorkingQ[candidate], Return[ExpandFileName[candidate]]];
	platform = gitPlatform[];
	If[! AssociationQ[platform], gitInstallFailure["MathlibGitPlatform", "Automatic Git installation is unavailable on this platform.", <|"SystemID" -> $SystemID|>]];
	prefix = gitPrefix[];
	base = DirectoryName[prefix];
	stamp = gitStamp[prefix];
	ownership = prefix <> ".installing.json";
	(* Only a failed installation carrying our exact ownership record may be
	   removed. A completed or unrelated directory is never replaced. *)
	If[DirectoryQ[prefix],
		If[gitStampQ[ownership, stamp] && ! gitStampQ[FileNameJoin[{prefix, "mathliblink-git.json"}], stamp], DeleteDirectory[prefix, DeleteContents -> True],
			gitInstallFailure["MathlibGitDirectoryInUse", "The local Git directory already exists but could not be used.", <|"Directory" -> prefix|>]]
	];
	gitCreateDirectory[base];
	If[! StringQ[Quiet[Check[CreateDirectory[prefix], $Failed]]],
		gitInstallFailure["MathlibGitDirectoryInUse", "The local Git directory could not be reserved.", <|"Directory" -> prefix|>]];
	WithCleanup[
		gitExport[ownership, stamp, "RawJSON"];
		root = FileNameJoin[{base, "Cache"}];
		config = FileNameJoin[{base, "bootstrap.yaml"}];
		lock = prefix <> ".lock";
		mamba = FileNameJoin[{mathlibToolsDirectory[], "Micromamba", gitBootstrapData[]["MicromambaRelease"], $SystemID,
			If[$OperatingSystem === "Windows", "micromamba.exe", "micromamba"]}];
		asset = platform["Micromamba"];
		gitCreateDirectory[DirectoryName[mamba]];
		mathlibInstallStage["Downloading..."];
		If[! FileExistsQ[mamba] || Quiet[Check[IntegerString[FileHash[mamba, "SHA256"], 16, 64], ""]] =!= asset["SHA256"],
			mathlibDownload[asset, mamba]
		];
		If[$OperatingSystem =!= "Windows",
			result = mathlibInstallRun[{"/bin/chmod", "755", mamba}, base];
			If[! AssociationQ[result] || result["ExitCode"] =!= 0,
				gitInstallFailure["MathlibGitBootstrap", "The Git installer could not be made executable.", <|"Result" -> result|>]]
		];
		(* JSON syntax is also YAML. The .yaml suffix is required: micromamba
		   silently ignores rc files whose names do not match its allowlist. *)
		gitExport[config, <|"pkgs_dirs" -> {FileNameJoin[{root, "pkgs"}]}, "envs_dirs" -> {FileNameJoin[{root, "envs"}]},
			"channels" -> {"https://conda.anaconda.org/conda-forge"}, "channel_priority" -> "strict", "shortcuts" -> False|>, "RawJSON"];
		gitExport[lock, gitLock[platform], "Text"];
		command = {mamba, "create", "--rc-file", config, "--no-env", "--root-prefix", root,
			"--prefix", prefix, "--no-shortcuts", "--yes", "--file", lock};
		mathlibInstallStage["Downloading..."];
		result = mathlibInstallRun[Append[command, "--download-only"], base];
		If[! AssociationQ[result] || result["ExitCode"] =!= 0,
			gitInstallFailure["MathlibGitDownloadFailed", "The local Git packages could not be downloaded. Run InstallMathlib[] to retry.", <|"Result" -> result|>]];
		mathlibInstallStage["Installing..."];
		result = mathlibInstallRun[Append[command, "--offline"], base];
		If[! AssociationQ[result] || result["ExitCode"] =!= 0,
			gitInstallFailure["MathlibGitInstallFailed", "The local Git runtime could not be installed. Run InstallMathlib[] to retry.", <|"Result" -> result|>]];
		mathlibInstallStage["Checking..."];
		executable = gitExecutable[prefix];
		If[! mathlibGitWorkingQ[executable, gitEnvironment[prefix]],
			gitInstallFailure["MathlibGitUnavailable", "The downloaded Git runtime could not run on this system.", <|"Executable" -> executable|>]];
		gitExport[FileNameJoin[{prefix, "mathliblink-git.json"}], stamp, "RawJSON"];
		complete = True;
		executable,
		If[! complete && DirectoryQ[prefix], Quiet[DeleteDirectory[prefix, DeleteContents -> True]]];
		If[! complete && ! DirectoryQ[prefix], mathlibGitRemoveRegistration[prefix]];
		If[gitStampQ[ownership, stamp], Quiet[DeleteFile[ownership]]]
	]
]
