PackageExported[{MathlibEvaluate, MathlibCall, MathlibExpression, ProveMathlib}]
PackageScoped[{mathlibEncode, mathlibQuoteName}]

MathlibEvaluate::usage = "MathlibEvaluate[session, expression] evaluates a Lean expression. Use \"ReturnType\" -> \"Object\" to retain its exact typed expression."
MathlibCall::usage = "MathlibCall[session, name, args] applies an available Lean declaration to structured arguments."
MathlibExpression::usage = "MathlibExpression[source] supplies an explicit Lean expression as a structured call argument."
ProveMathlib::usage = "ProveMathlib[session, statement, proof] elaborates a Lean theorem and returns a kernel-checked object if its axiom dependencies are standard."

Options[MathlibEvaluate] = {TimeConstraint -> 30, "ReturnType" -> Automatic}
Options[MathlibCall] = Options[MathlibEvaluate]
Options[ProveMathlib] = {TimeConstraint -> 30}

mathlibQuoteName[name_String] := If[StringContainsQ[name, "«" | "»" | "\n" | "\r"],
	mathlibFailure["MathlibUnsupportedName", "Use MathlibExpression for this Lean identifier."],
	StringRiffle[("«" <> # <> "»" &) /@ StringSplit[name, ".", All], "."]
]

signedInteger[value_Integer] := If[value < 0, "-", ""] <> IntegerString[Abs[value]]

mathlibEncode[_, value_Integer] := "(" <> signedInteger[value] <> ")"
mathlibEncode[_, value_Rational] := "((" <> signedInteger[Numerator[value]] <> " : Rat) / " <> IntegerString[Denominator[value]] <> ")"
mathlibEncode[_, True] := "true"
mathlibEncode[_, False] := "false"
mathlibEncode[_, value_String] := "\"" <> StringJoin[Map[
	Switch[#, 34, "\\\"", 92, "\\\\", 10, "\\n", 13, "\\r", 9, "\\t",
		_, If[# < 32 || # === 127, "\\u{" <> IntegerString[#, 16] <> "}", FromCharacterCode[#]]] &,
	ToCharacterCode[value]
]] <> "\""
mathlibEncode[_, MathlibExpression[source_String]] := "(" <> source <> ")"
mathlibEncode[session_, values_List] := With[{encoded = mathlibEncode[session, #] & /@ values},
	If[AnyTrue[encoded, FailureQ], SelectFirst[encoded, FailureQ], "[" <> StringRiffle[encoded, ", "] <> "]"]
]
mathlibEncode[MathlibSession[sessionID_String], object_MathlibObject] := With[{data = mathlibObjectData[object]},
	Which[
		FailureQ[data], data,
		data["Session"] =!= sessionID, mathlibFailure["MathlibObjectSession", "Use objects from the same mathlib session."],
		True, "(" <> data["Expression"] <> ")"
	]
]
mathlibEncode[_, _] := mathlibFailure["MathlibUnsupportedValue", "Use an exact integer, rational, boolean, string, list, MathlibObject or MathlibExpression."]

retainExpression[session_MathlibSession, state_Association, expression_String, time_] := Module[{name, source, environment, result},
	name = "mathliblink_value_" <> StringDelete[CreateUUID[], "-"];
	source = mathlibSessionSource[state] <> "noncomputable def " <> name <> " := (" <> expression <> ")\n";
	environment = TimeConstrained[Quiet[Check[mathlibInvoke["LeanImportString", source, "ProjectDir" -> state["Directory"]], $Failed]], time, $TimedOut];
	If[! MatchQ[environment, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]],
		Return[mathlibFailure[If[environment === $TimedOut, "MathlibTimedOut", "MathlibElaborationFailed"], "Lean could not elaborate the expression.", <|"Expression" -> expression|>]]
	];
	result = mathlibKeepObject[session, environment[name], expression, environment];
	If[FailureQ[result], mathlibInvoke["LeanFreeEnvironment", Information[environment, "Handle"]]];
	result
]

MathlibEvaluate[session_MathlibSession, expression_String, opts : OptionsPattern[]] := Module[{state, time, mode, result},
	If[! mathlibOptionsQ[MathlibEvaluate, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown evaluation option."]]];
	{time, mode} = {OptionValue[TimeConstraint], OptionValue["ReturnType"]};
	If[! mathlibTimeQ[time] || ! MemberQ[{Automatic, "Object"}, mode], Return[mathlibFailure["MathlibInvalidOption", "Use a positive TimeConstraint and ReturnType Automatic or Object."]]];
	state = mathlibSessionData[session];
	If[FailureQ[state], Return[state]];
	If[mode === "Object", Return[retainExpression[session, state, expression, time]]];
	result = CheckAbort[
		mathlibInvoke["LeanEvaluate", expression, "ProjectDir" -> state["Directory"], "Imports" -> state["Imports"], "TimeLimit" -> time],
		mathlibCloseSession[session]; Abort[]
	];
	If[MatchQ[result, Failure["TimedOut", _]], mathlibCloseSession[session]];
	If[result === $Failed, mathlibFailure["MathlibEvaluationFailed", "Lean could not evaluate the expression."], result]
]

MathlibCall[session_MathlibSession, name_String, arguments : Longest[Except[_Rule | _RuleDelayed]...], opts : OptionsPattern[]] :=
	Module[{state, function, encoded},
		If[! mathlibOptionsQ[MathlibCall, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown evaluation option."]]];
		state = mathlibSessionData[session];
		If[FailureQ[state], Return[state]];
		If[! KeyExistsQ[state["Environment"], name], Return[mathlibFailure["MathlibUnknownDeclaration", "The declaration is not available in this session.", <|"Name" -> name|>]]];
		function = mathlibQuoteName[name];
		If[FailureQ[function], Return[function]];
		encoded = mathlibEncode[session, #] & /@ {arguments};
		If[AnyTrue[encoded, FailureQ], Return[SelectFirst[encoded, FailureQ]]];
		MathlibEvaluate[session, StringRiffle[Prepend[encoded, function], " "], opts]
	]

ProveMathlib[session_MathlibSession, statement_String, proof_String, opts : OptionsPattern[]] := Module[{
	state, time, name, source, environment, term, axioms, checked, result, retained = False
},
	If[! mathlibOptionsQ[ProveMathlib, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown proof option."]]];
	time = OptionValue[TimeConstraint];
	If[! mathlibTimeQ[time], Return[mathlibFailure["MathlibInvalidOption", "TimeConstraint must be positive or Infinity."]]];
	state = mathlibSessionData[session];
	If[FailureQ[state], Return[state]];
	name = "mathliblink_theorem_" <> StringDelete[CreateUUID[], "-"];
	source = mathlibSessionSource[state] <> "theorem " <> name <> " : " <> statement <> " := " <> proof <> "\n";
	environment = TimeConstrained[Quiet[Check[mathlibInvoke["LeanImportString", source, "ProjectDir" -> state["Directory"]], $Failed]], time, $TimedOut];
	If[! MatchQ[environment, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]],
		Return[mathlibFailure[If[environment === $TimedOut, "MathlibTimedOut", "MathlibProofFailed"], "Lean did not produce the requested theorem.", <|"Statement" -> statement|>]]
	];
	WithCleanup[
		term = environment[name];
		axioms = term["Axioms"];
		If[! MatchQ[axioms, {___String}] || Complement[axioms, {"propext", "Quot.sound", "Classical.choice"}] =!= {},
			Return[mathlibFailure["MathlibUntrustedProof", "The theorem depends on an admitted proof or an additional axiom.", <|"Axioms" -> axioms|>]]
		];
		checked = TimeConstrained[term["KernelCheck"], time, $TimedOut];
		If[! MatchQ[checked, _Success], Return[mathlibFailure["MathlibKernelRejected", "Lean's kernel did not accept the theorem's module.", <|"Result" -> checked|>]]];
		result = mathlibKeepObject[session, term, "((" <> proof <> ") : " <> statement <> ")", environment, True];
		retained = ! FailureQ[result];
		result,
		If[! retained, mathlibInvoke["LeanFreeEnvironment", Information[environment, "Handle"]]]
	]
]
