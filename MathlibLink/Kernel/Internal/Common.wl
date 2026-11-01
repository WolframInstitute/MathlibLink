PackageScoped[{mathlibFailure, mathlibLoadLean, mathlibInvoke, mathlibOptionsQ, mathlibTimeQ, mathlibModuleQ, mathlibDirectory, mathlibRuntime, mathlibExecutable, mathlibRun, mathlibVersionQ, mathlibLeanDirectory, mathlibBridgeReadyQ, mathlibElanHome, mathlibToolsDirectory, mathlibExecutables, mathlibPathDirectories, mathlibEnvironment}]

mathlibFailure[tag_String, message_String, data_Association : <||>] := Failure[tag, Join[<|"MessageTemplate" -> message|>, data]]

mathlibRuntime[] := mathlibRuntime[] = Import[FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "Runtime.json"}], "RawJSON"]

mathlibDirectory[Automatic] := FileNameJoin[{$UserBaseDirectory, "ApplicationData", "MathlibLink", "4.35.0"}]
mathlibDirectory[path_String] := ExpandFileName[path]
mathlibDirectory[_] := mathlibFailure["MathlibInvalidOption", "Directory must be Automatic or a directory path."]

mathlibTimeQ[value_] := value === Infinity || (NumberQ[value] && TrueQ[value > 0])
mathlibModuleQ[name_String] := StringMatchQ[name, RegularExpression["[A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*"]]
mathlibOptionsQ[function_Symbol, options_List] := AllTrue[Flatten[options], MemberQ[First /@ Options[function], First[#]] &]
mathlibVersionQ[installed_String, minimum_String] := With[{
	a = FromDigits /@ StringSplit[installed, "."], b = FromDigits /@ StringSplit[minimum, "."]
}, OrderedQ[{PadRight[b, Max[Length[a], Length[b]]], PadRight[a, Max[Length[a], Length[b]]]}]]

mathlibInvoke[name_String, arguments___] := Symbol["Wolfram`LeanLink`" <> name][arguments]

mathlibLoadLean[] := Module[{installed = PacletFind["Wolfram/LeanLink"], result},
	If[installed === {} || ! mathlibVersionQ[First[installed]["Version"], mathlibRuntime[]["LeanLinkMinimumVersion"]],
		Return[mathlibFailure["LeanLinkRequired", "Install the compatible LeanLink release with InstallMathlib[]."]]
	];
	result = Block[{$ContextPath = $ContextPath}, Quiet[Check[Needs["Wolfram`LeanLink`"], $Failed]]];
	If[result === Null, True, mathlibFailure["LeanLinkUnavailable", "LeanLink could not load. Restart the kernel after updating it.", <|"Result" -> result|>]]
]

mathlibElanHome[] := Replace[Environment["ELAN_HOME"], Except[_String] -> FileNameJoin[{$HomeDirectory, ".elan"}]]
mathlibToolsDirectory[] := FileNameJoin[{$UserBaseDirectory, "ApplicationData", "MathlibLink", "Tools"}]

mathlibExecutable[name_String] := With[{suffix = If[$OperatingSystem === "Windows", ".exe", ""]},
	SelectFirst[Join[
		If[MemberQ[{"git", "curl"}, name], {mathlibManagedTool[name]}, {}],
		If[name === "curl", {mathlibBundledCurl[]}, {}],
		If[MemberQ[{"elan", "lake"}, name], {FileNameJoin[{mathlibElanHome[], "bin", name <> suffix}]}, {}],
		If[name === "lake", {}, FileNames[name <> suffix,
			StringSplit[Replace[Environment["PATH"], Except[_String] -> ""], If[$OperatingSystem === "Windows", ";", ":"]]]]
	], StringQ[#] && FileExistsQ[#] &, Missing["NotFound", name]]
]

mathlibExecutables[] := AssociationThread[{"Elan", "Lake", "Git", "Curl"}, mathlibExecutable /@ {"elan", "lake", "git", "curl"}]
mathlibPathDirectories[] := DeleteDuplicates[Join[
	Replace[mathlibToolPathDirectories[], Except[_List] -> {}],
	DirectoryName /@ Select[Values[mathlibExecutables[]], StringQ]
]]
mathlibEnvironment[extra_Association : <||>] := Association[GetEnvironment[],
	"PATH" -> StringRiffle[DeleteDuplicates[Join[mathlibPathDirectories[],
		StringSplit[Replace[Environment["PATH"], Except[_String] -> ""], If[$OperatingSystem === "Windows", ";", ":"]]]], If[$OperatingSystem === "Windows", ";", ":"]],
	"ELAN_HOME" -> mathlibElanHome[], "MATHLIB_NO_CACHE_ON_UPDATE" -> "1", extra
]

(* Argument lists go directly to the process API, never through a shell. *)
mathlibRun[arguments_List, directory_String] := Quiet[Check[
	RunProcess[arguments, All, ProcessDirectory -> directory, ProcessEnvironment -> mathlibEnvironment[]],
	$Failed
]]

mathlibLeanDirectory[] := FileNameJoin[{mathlibElanHome[], "toolchains", StringReplace[mathlibRuntime[]["LeanToolchain"], {"/" -> "--", ":" -> "---"}]}]

$bridgeReady = <||>

(* Loading the pinned Init module checks the olean/native ABI without invoking
   elan or a compiler fallback. A successful native probe is local and reusable. *)
mathlibBridgeReadyQ[] := Module[{loaded, version, handle},
	loaded = mathlibLoadLean[];
	If[FailureQ[loaded], Return[False]];
	version = First[PacletFind["Wolfram/LeanLink"]]["Version"];
	If[TrueQ[Lookup[$bridgeReady, version, False]], Return[True]];
	handle = Quiet[Check[mathlibInvoke["LeanLoadEnvironment", {"Init"}, FileNameJoin[{mathlibLeanDirectory[], "lib", "lean"}]], $Failed]];
	If[! IntegerQ[handle] || handle <= 0, Return[False]];
	mathlibInvoke["LeanFreeEnvironment", handle];
	AssociateTo[$bridgeReady, version -> True];
	True
]
