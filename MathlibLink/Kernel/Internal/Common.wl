PackageScoped[{mathlibFailure, mathlibLoadLean, mathlibInvoke, mathlibOptionsQ, mathlibTimeQ, mathlibNameQ, mathlibModuleQ, mathlibDirectory, mathlibRuntime, mathlibExecutable, mathlibRun, mathlibVersionQ}]

mathlibFailure[tag_String, message_String, data_Association : <||>] := Failure[tag, Join[<|"MessageTemplate" -> message|>, data]]

mathlibRuntime[] := mathlibRuntime[] = Import[FileNameJoin[{PacletObject["WolframInstitute/MathlibLink"]["Location"], "Resources", "Runtime.json"}], "RawJSON"]

mathlibDirectory[Automatic] := FileNameJoin[{$UserBaseDirectory, "ApplicationData", "MathlibLink", "4.35.0"}]
mathlibDirectory[path_String] := ExpandFileName[path]
mathlibDirectory[_] := mathlibFailure["MathlibInvalidOption", "Directory must be Automatic or a directory path."]

mathlibTimeQ[value_] := value === Infinity || (NumberQ[value] && TrueQ[value > 0])
mathlibNameQ[name_String] := StringMatchQ[name, RegularExpression["[\\p{L}_][\\p{L}\\p{N}_'.]*(?:\\.[\\p{L}_][\\p{L}\\p{N}_']*)*"]]
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

mathlibExecutable[name_String] := With[{suffix = If[$OperatingSystem === "Windows", ".exe", ""],
	elan = Replace[Environment["ELAN_HOME"], Except[_String] -> FileNameJoin[{$HomeDirectory, ".elan"}]]},
	SelectFirst[Join[
		FileNames[name <> suffix, StringSplit[Replace[Environment["PATH"], Except[_String] -> ""], If[$OperatingSystem === "Windows", ";", ":"]]],
		{FileNameJoin[{elan, "bin", name <> suffix}]}
	], StringQ[#] && FileExistsQ[#] &, Missing["NotFound", name]]
]

(* Argument lists go directly to the process API, never through a shell. *)
mathlibRun[arguments_List, directory_String] := Quiet[Check[
	RunProcess[arguments, All, ProcessDirectory -> directory,
		ProcessEnvironment -> Association[GetEnvironment[], "MATHLIB_NO_CACHE_ON_UPDATE" -> "1"]],
	$Failed
]]
