PackageExported[{StartMathlibSession, MathlibSession, MathlibNames}]
PackageScoped[{$mathlibSessions, $mathlibEnvironments, mathlibSessionData, mathlibCloseSession, mathlibSessionSource}]

StartMathlibSession::usage = "StartMathlibSession[] opens a session with all mathlib declarations. StartMathlibSession[\"Imports\" -> modules] imports selected modules."
MathlibSession::usage = "MathlibSession[...] represents a mathlib session. session[\"property\"] gives a session property. DeleteObject[session] closes it."
MathlibNames::usage = "MathlibNames[session] lists available Lean declaration names. MathlibNames[session, pattern] selects names matching a string pattern."
Options[StartMathlibSession] = {"Directory" -> Automatic, "Imports" -> {"Mathlib"}}

$mathlibSessions = <||>
$mathlibEnvironments = <||>

StartMathlibSession[opts : OptionsPattern[]] := Module[{directory, imports, loaded, environment, session, cacheKey, names},
	If[! mathlibOptionsQ[StartMathlibSession, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown session option."]]];
	directory = mathlibDirectory[OptionValue["Directory"]];
	If[FailureQ[directory], Return[directory]];
	imports = OptionValue["Imports"];
	If[! MatchQ[imports, {__String}] || ! AllTrue[imports, mathlibModuleQ], Return[mathlibFailure["MathlibInvalidOption", "Imports must be a nonempty list of Lean module names."]]];
	If[! mathlibInstallationReadyQ[directory], Return[mathlibFailure["MathlibSetupRequired", "Run InstallMathlib[] before starting a session.", <|"Directory" -> directory|>]]];
	loaded = mathlibLoadLean[];
	If[FailureQ[loaded], Return[loaded]];
	imports = DeleteDuplicates[imports];
	cacheKey = Hash[{directory, imports}, "SHA256", "HexString"];
	If[KeyExistsQ[$mathlibEnvironments, cacheKey] && Information[$mathlibEnvironments[cacheKey]["Environment"], "Valid"] === False,
		KeyDropFrom[$mathlibEnvironments, cacheKey]
	];
	If[KeyExistsQ[$mathlibEnvironments, cacheKey],
		{environment, names} = Lookup[$mathlibEnvironments[cacheKey], {"Environment", "Names"}],
		environment = Quiet[Check[mathlibInvoke["LeanImport", "ProjectDir" -> directory, "Imports" -> imports, "IncludeInternal" -> True], $Failed]];
		If[! MatchQ[environment, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]], Return[mathlibFailure["MathlibImportFailed", "Lean could not load the selected mathlib modules.", <|"Directory" -> directory, "Imports" -> imports|>]]];
		names = Sort[Keys[environment]];
		AssociateTo[$mathlibEnvironments, cacheKey -> <|"Environment" -> environment, "Names" -> names|>]
	];
	session = MathlibSession[CreateUUID[]];
	AssociateTo[$mathlibSessions, First[session] -> <|"Status" -> "Ready", "Directory" -> directory,
		"Imports" -> DeleteDuplicates[imports], "Environment" -> environment, "Names" -> names, "Objects" -> {},
		"DeclarationCount" -> Length[environment], "CacheKey" -> cacheKey|>];
	session
]

mathlibSessionData[MathlibSession[id_String]] := With[{state = Lookup[$mathlibSessions, id, None]},
	Which[
		! AssociationQ[state], mathlibFailure["MathlibInvalidSession", "This mathlib session is not available in this kernel."],
		state["Status"] =!= "Ready", mathlibFailure["MathlibInvalidSession", "The mathlib session is closed.", <|"Status" -> state["Status"]|>],
		True, state
	]
]

mathlibSessionData[_] := mathlibFailure["MathlibInvalidSession", "This mathlib session is not valid."]

mathlibSessionSource[state_Association] := StringRiffle[("import " <> # &) /@ state["Imports"], "\n"] <> "\n"

mathlibCloseSession[session : MathlibSession[id_String]] := With[{state = Lookup[$mathlibSessions, id, None]},
	If[AssociationQ[state] && state["Status"] === "Ready",
		Scan[mathlibForgetObject, state["Objects"]];
		AssociateTo[$mathlibSessions, id -> Append[KeyTake[state, {"Directory", "Imports", "DeclarationCount"}], "Status" -> "Closed"]];
		If[mathlibDirectLeanQ[] && KeyExistsQ[state, "Environment"] && NoneTrue[Values[$mathlibSessions], Lookup[#, "Status", None] === "Ready" && Lookup[#, "CacheKey", None] === state["CacheKey"] &],
			mathlibInvoke["LeanFreeEnvironment", state["Environment"], "EvaluatorOnly" -> True]
		]
	];
	Null
]

(session_MathlibSession)["Properties"] := {"Status", "Directory", "Imports", "DeclarationCount", "Properties"}
(session : MathlibSession[id_String])[property : "Status" | "Directory" | "Imports" | "DeclarationCount"] :=
	Lookup[Lookup[$mathlibSessions, id, <||>], property, Missing["Unavailable", property]]
(session_MathlibSession)[property_String] := Missing["UnknownProperty", property]

MathlibSession /: DeleteObject[session_MathlibSession] := mathlibCloseSession[session]
MathlibSession /: MakeBoxes[session : MathlibSession[id_String], form_] := With[{
	status = Lookup[Lookup[$mathlibSessions, id, <||>], "Status", "Unavailable"]
}, With[{boxes = ToBoxes[status, form]}, InterpretationBox[RowBox[{"MathlibSession", "[", boxes, "]"}], session]]]

MathlibNames[session_MathlibSession, pattern_String : "*"] := With[{state = mathlibSessionData[session]},
	If[FailureQ[state], state, Select[state["Names"], StringMatchQ[#, pattern] &]]
]
