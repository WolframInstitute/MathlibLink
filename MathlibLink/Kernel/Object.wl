PackageExported[{MathlibObject, MathlibDeclaration}]
PackageScoped[{$mathlibObjects, mathlibKeepObject, mathlibObjectData, mathlibForgetObject, mathlibDocumentationURL}]

MathlibObject::usage = "MathlibObject[...] retains a typed Lean declaration or expression in its mathlib session. object[\"property\"] queries it; Normal[object] gives its LeanTerm."
MathlibDeclaration::usage = "MathlibDeclaration[session, name] gives a typed object for a Lean declaration available in the session."

$mathlibObjects = <||>

mathlibKeepObject[session : MathlibSession[sessionID_String], term_, expression_String, environment_ : None, verified_ : False] := Module[{id = CreateUUID[], state},
	state = mathlibSessionData[session];
	If[FailureQ[state], Return[state]];
	AssociateTo[$mathlibObjects, id -> <|"Session" -> sessionID, "Term" -> term, "Expression" -> expression,
		"Environment" -> environment, "Verified" -> verified|>];
	AssociateTo[$mathlibSessions, sessionID -> Append[state, "Objects" -> Append[state["Objects"], id]]];
	MathlibObject[id]
]

mathlibObjectData[MathlibObject[id_String]] := With[{object = Lookup[$mathlibObjects, id, None]},
	Which[
		! AssociationQ[object], mathlibFailure["MathlibInvalidObject", "This mathlib object has been released or is unavailable."],
		FailureQ[mathlibSessionData[MathlibSession[object["Session"]]]], mathlibFailure["MathlibInvalidObject", "The object's mathlib session is closed."],
		True, object
	]
]

mathlibObjectData[_] := mathlibFailure["MathlibInvalidObject", "This mathlib object is not valid."]

mathlibForgetObject[id_String] := With[{object = Lookup[$mathlibObjects, id, None]},
	If[AssociationQ[object],
		If[MatchQ[object["Environment"], Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]],
			mathlibInvoke["LeanFreeEnvironment", Information[object["Environment"], "Handle"]]
		];
		KeyDropFrom[$mathlibObjects, id]
	];
	Null
]

mathlibDocumentationURL[term_] := With[{module = term["Module"], name = term["Name"]},
	If[StringQ[module] && StringQ[name],
		mathlibRuntime[]["DocumentationURL"] <> StringReplace[module, "." -> "/"] <> ".html#" <> URLEncode[name],
		Missing["NoDocumentationURL"]
	]
]

MathlibDeclaration[session_MathlibSession, name_String] := With[{state = mathlibSessionData[session]},
	Which[
		FailureQ[state], state,
		! KeyExistsQ[state["Environment"], name], mathlibFailure["MathlibUnknownDeclaration", "The declaration is not available in this session.", <|"Name" -> name|>],
		True, mathlibKeepObject[session, state["Environment"][name], name]
	]
]

(object_MathlibObject)["Properties"] := {"Name", "Kind", "Type", "TypeForm", "Term", "TermForm", "Axioms", "KernelCheck", "Module", "DocumentationURL", "Verified", "Properties"}
(object_MathlibObject)[property : "Name" | "Kind" | "Type" | "TypeForm" | "Term" | "TermForm" | "Axioms" | "KernelCheck" | "Module"] :=
	With[{data = mathlibObjectData[object]}, If[FailureQ[data], data, data["Term"][property]]]
(object_MathlibObject)["DocumentationURL"] := With[{data = mathlibObjectData[object]}, If[FailureQ[data], data, mathlibDocumentationURL[data["Term"]]]]
(object_MathlibObject)["Verified"] := With[{data = mathlibObjectData[object]}, If[FailureQ[data], data, data["Verified"]]]
(object_MathlibObject)[property_String] := Missing["UnknownProperty", property]

MathlibObject /: Normal[object_MathlibObject] := With[{data = mathlibObjectData[object]}, If[FailureQ[data], data, data["Term"]]]
MathlibObject /: DeleteObject[MathlibObject[id_String]] := mathlibForgetObject[id]
MathlibObject /: MakeBoxes[object : MathlibObject[id_String], form_] := With[{
	data = Lookup[$mathlibObjects, id, None]
}, InterpretationBox[RowBox[{"MathlibObject", "[", ToBoxes[If[AssociationQ[data], data["Term"]["Name"], "Released"], form], "]"}], object]]
