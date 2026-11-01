PackageScoped[{mathlibEnsureGit, mathlibEnsureCurl, mathlibManagedTool, mathlibBundledCurl, mathlibToolPathDirectories,
	mathlibGitWorkingQ, mathlibCurlWorkingQ, mathlibRemoveToolRegistration}]

toolBootstrapData[] := toolBootstrapData[] = Import[
	FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "ToolBootstrap.json"}], "RawJSON"]

toolPlatform[] := Lookup[toolBootstrapData[]["Platforms"], $SystemID, Missing["UnsupportedPlatform", $SystemID]]
toolLabel[name_String] := Switch[name, "git", "Git", "curl", "Curl"]
toolVersion[name_String] := toolBootstrapData[]["Versions"][name]
toolLock[name_String, platform_Association] := "@EXPLICIT\n" <>
	StringRiffle[(#["URL"] <> "#" <> #["SHA256"]) & /@ platform["Packages"][name], "\n"] <> "\n"
toolPrefix[name_String] := With[{platform = toolPlatform[]},
	If[! AssociationQ[platform], Return[Missing["UnsupportedPlatform", $SystemID]]];
	FileNameJoin[{mathlibToolsDirectory[], toolLabel[name], $SystemID,
		toolVersion[name] <> "-" <> StringTake[Hash[toolLock[name, platform], "SHA256", "HexString"], 12]}]
]
toolExecutable[prefix_String, name_String] := FileNameJoin[Join[{prefix},
	If[$OperatingSystem === "Windows", {"Library", "bin", name <> ".exe"}, {"bin", name}]]]
toolStamp[prefix_String, name_String] := <|"Owner" -> "WolframInstitute/MathlibLink", "Prefix" -> prefix,
	"Version" -> toolVersion[name], "SystemID" -> $SystemID,
	"PackagesSHA256" -> Hash[toolLock[name, toolPlatform[]], "SHA256", "HexString"]|>
toolStampFile[prefix_String, name_String] := FileNameJoin[{prefix, "mathliblink-" <> name <> ".json"}]
toolStampQ[file_String, stamp_Association] := FileExistsQ[file] && Quiet[Check[Import[file, "RawJSON"] === stamp, False]]

mathlibManagedTool[name_String] := With[{prefix = toolPrefix[name]},
	If[StringQ[prefix] && FileExistsQ[toolExecutable[prefix, name]] && toolStampQ[toolStampFile[prefix, name], toolStamp[prefix, name]],
		toolExecutable[prefix, name], Missing["NotInstalled", name]]
]

toolPathDirectories[prefix_String] := Select[
	FileNameJoin[Prepend[#, prefix]] & /@ If[$OperatingSystem === "Windows",
		{{"Library", "bin"}, {"Library", "mingw64", "bin"}, {"Library", "clangarm64", "bin"}, {"Library", "usr", "bin"}, {"bin"}},
		{{"bin"}}], DirectoryQ]
mathlibToolPathDirectories[] := DeleteDuplicates[Flatten[
	If[StringQ[mathlibManagedTool[#]], toolPathDirectories[toolPrefix[#]], {}] & /@ {"curl", "git"}]]
(* Git for Windows includes curl. Discover it in the same order used for
   child processes, before falling back to unrelated system directories. *)
mathlibBundledCurl[] := If[StringQ[mathlibManagedTool["git"]],
	SelectFirst[Flatten[FileNames["curl" <> If[$OperatingSystem === "Windows", ".exe", ""], #] & /@
		toolPathDirectories[toolPrefix["git"]]], FileExistsQ, Missing["NotFound", "curl"]],
	Missing["NotFound", "curl"]
]
toolEnvironment[prefix_String] := With[{separator = If[$OperatingSystem === "Windows", ";", ":"]},
	<|"PATH" -> StringRiffle[DeleteDuplicates[Join[toolPathDirectories[prefix],
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

mathlibCurlWorkingQ[path_String, environment_Association : <||>] := Module[{result, versions},
	result = TimeConstrained[mathlibInstallRun[{path, "--version"}, Directory[], environment], 10, $Failed];
	If[! AssociationQ[result] || result["ExitCode"] =!= 0, Return[False]];
	versions = StringCases[result["StandardOutput"], RegularExpression["(?m)^curl ([0-9]+\\.[0-9]+\\.[0-9]+)"] -> "$1"];
	Length[versions] === 1 && mathlibVersionQ[First[versions], "7.84.0"] &&
		StringContainsQ[result["StandardOutput"], RegularExpression["(?m)^Protocols:[^\\n]*\\bhttps\\b"]]
]
mathlibCurlWorkingQ[_, ___] := False

toolWorkingQ["git", path_, environment_Association : <||>] := mathlibGitWorkingQ[path, environment]
toolWorkingQ["curl", path_, environment_Association : <||>] := mathlibCurlWorkingQ[path, environment]
toolInstallFailure[name_String, tag_String, message_String, data_Association : <||>] :=
	Throw[mathlibFailure["Mathlib" <> toolLabel[name] <> tag, message, data], "MathlibInstall"]
toolCreateDirectory[path_String, name_String] := If[! DirectoryQ[path] && ! StringQ[Quiet[Check[CreateDirectory[path, CreateIntermediateDirectories -> True], $Failed]]],
	toolInstallFailure[name, "Directory", "The local tool directory could not be created.", <|"Directory" -> path|>]]
toolExport[file_String, value_, format_String, name_String] := If[! StringQ[Quiet[Check[Export[file, value, format], $Failed]]],
	toolInstallFailure[name, "Directory", "The local tool installation metadata could not be written.", <|"File" -> file|>]]

(* Micromamba registers even download-only prefixes. Preserve unrelated bytes
   and leave a concurrently changed registry untouched. Cleanup is best effort. *)
mathlibRemoveToolRegistration[prefix_String, registry_ : Automatic] := Module[{file, bytes, target, variants, remaining, temporary, stream},
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

mathlibEnsureGit[] := ensureTool["git"]
mathlibEnsureCurl[] := ensureTool["curl"]

ensureTool[name_String] := Module[{
	candidate, platform, prefix, base, stamp, ownership, root, config, lock, executable, mamba, asset, command, result, complete = False
},
	mathlibInstallStage["Checking..."];
	candidate = mathlibExecutable[name];
	If[toolWorkingQ[name, candidate], Return[ExpandFileName[candidate]]];
	platform = toolPlatform[];
	If[! AssociationQ[platform], toolInstallFailure[name, "Platform", "Automatic tool installation is unavailable on this platform.", <|"SystemID" -> $SystemID, "Tool" -> name|>]];
	prefix = toolPrefix[name];
	base = DirectoryName[prefix];
	stamp = toolStamp[prefix, name];
	ownership = prefix <> ".installing.json";
	(* Only an incomplete installation carrying our exact ownership record may
	   be removed. A completed or unrelated directory is never replaced. *)
	If[DirectoryQ[prefix],
		If[toolStampQ[ownership, stamp] && ! toolStampQ[toolStampFile[prefix, name], stamp], DeleteDirectory[prefix, DeleteContents -> True],
			toolInstallFailure[name, "DirectoryInUse", "The local tool directory already exists but could not be used.", <|"Directory" -> prefix|>]]
	];
	toolCreateDirectory[base, name];
	If[! StringQ[Quiet[Check[CreateDirectory[prefix], $Failed]]],
		toolInstallFailure[name, "DirectoryInUse", "The local tool directory could not be reserved.", <|"Directory" -> prefix|>]];
	WithCleanup[
		toolExport[ownership, stamp, "RawJSON", name];
		root = FileNameJoin[{base, "Cache"}];
		config = FileNameJoin[{base, "bootstrap.yaml"}];
		lock = prefix <> ".lock";
		mamba = FileNameJoin[{mathlibToolsDirectory[], "Micromamba", toolBootstrapData[]["MicromambaRelease"], $SystemID,
			If[$OperatingSystem === "Windows", "micromamba.exe", "micromamba"]}];
		asset = platform["Micromamba"];
		toolCreateDirectory[DirectoryName[mamba], name];
		mathlibInstallStage["Downloading..."];
		mathlibDownload[asset, mamba];
		If[$OperatingSystem =!= "Windows",
			result = mathlibInstallRun[{"/bin/chmod", "755", mamba}, base];
			If[! AssociationQ[result] || result["ExitCode"] =!= 0,
				toolInstallFailure[name, "Bootstrap", "The local tool installer could not be made executable.", <|"Result" -> result|>]]
		];
		(* JSON syntax is YAML; micromamba requires a recognized rc-file suffix. *)
		toolExport[config, <|"pkgs_dirs" -> {FileNameJoin[{root, "pkgs"}]}, "envs_dirs" -> {FileNameJoin[{root, "envs"}]},
			"channels" -> {"https://conda.anaconda.org/conda-forge"}, "channel_priority" -> "strict", "shortcuts" -> False|>, "RawJSON", name];
		toolExport[lock, toolLock[name, platform], "Text", name];
		command = {mamba, "create", "--rc-file", config, "--no-env", "--root-prefix", root,
			"--prefix", prefix, "--no-shortcuts", "--yes", "--file", lock};
		mathlibInstallStage["Downloading..."];
		result = mathlibInstallRun[Append[command, "--download-only"], base];
		If[! AssociationQ[result] || result["ExitCode"] =!= 0,
			toolInstallFailure[name, "DownloadFailed", "The local tool packages could not be downloaded. Run InstallMathlib[] to retry.", <|"Result" -> result|>]];
		mathlibInstallStage["Installing..."];
		result = mathlibInstallRun[Append[command, "--offline"], base];
		If[! AssociationQ[result] || result["ExitCode"] =!= 0,
			toolInstallFailure[name, "InstallFailed", "The local tool runtime could not be installed. Run InstallMathlib[] to retry.", <|"Result" -> result|>]];
		mathlibInstallStage["Checking..."];
		executable = toolExecutable[prefix, name];
		If[! toolWorkingQ[name, executable, toolEnvironment[prefix]],
			toolInstallFailure[name, "Unavailable", "The downloaded tool could not run on this system.", <|"Executable" -> executable|>]];
		toolExport[toolStampFile[prefix, name], stamp, "RawJSON", name];
		complete = True;
		executable,
		If[! complete && DirectoryQ[prefix], Quiet[DeleteDirectory[prefix, DeleteContents -> True]]];
		If[! complete && ! DirectoryQ[prefix], mathlibRemoveToolRegistration[prefix]];
		If[toolStampQ[ownership, stamp], Quiet[DeleteFile[ownership]]]
	]
]
