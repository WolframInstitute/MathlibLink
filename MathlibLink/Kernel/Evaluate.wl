PackageExported[{MathlibEvaluate, MathlibCall, MathlibExpression, ProveMathlib}]
PackageScoped[{mathlibEncode, mathlibQuoteName}]

MathlibEvaluate::usage = "MathlibEvaluate[session, expression] evaluates a Lean expression. Use \"ReturnType\" -> \"Object\" to retain its exact typed expression."
MathlibCall::usage = "MathlibCall[session, name, args] applies an available Lean declaration to structured arguments."
MathlibExpression::usage = "MathlibExpression[source] supplies an explicit Lean expression as a structured call argument."
ProveMathlib::usage = "ProveMathlib[session, statement, proof] elaborates a Lean theorem and returns a kernel-checked object if its axiom dependencies are standard."

Options[MathlibEvaluate] = {TimeConstraint -> 120, "ReturnType" -> Automatic, "Isolated" -> False}
Options[MathlibCall] = Options[MathlibEvaluate]
Options[ProveMathlib] = {TimeConstraint -> 120}

MathlibExpression /: MakeBoxes[expression : MathlibExpression[_String], form : StandardForm | TraditionalForm] := mathlibExpressionBoxes[expression, form]

(* Keep the released LeanLink usable while the environment interface is developed. *)
importSource[state_Association, source_String] := If[mathlibDirectLeanQ[],
	mathlibInvoke["LeanImportString", state["Environment"], source],
	mathlibInvoke["LeanImportString", mathlibSessionSource[state] <> source, "ProjectDir" -> state["Directory"]]
]

verifyTheorem[term_, time_] := If[mathlibDirectLeanQ[],
	mathlibInvoke["LeanVerify", term, "TimeLimit" -> time],
	With[{axioms = term["Axioms"]},
		If[! MatchQ[axioms, {___String}] || Complement[axioms, {"propext", "Quot.sound", "Classical.choice"}] =!= {},
			mathlibFailure["UntrustedProof", "The theorem depends on an admitted proof or an additional axiom.", <|"Axioms" -> axioms|>],
			TimeConstrained[term["KernelCheck"], time, $TimedOut]
		]
	]
]

mathlibQuoteName[name_String] := If[StringContainsQ[name, "\:00ab" | "\:00bb" | "\n" | "\r"],
	mathlibFailure["MathlibUnsupportedName", "Use MathlibExpression for this Lean identifier."],
	StringRiffle[("\:00ab" <> # <> "\:00bb" &) /@ StringSplit[name, ".", All], "."]
]

signedInteger[value_Integer] := If[value < 0, "-", ""] <> IntegerString[Abs[value]]

mathlibEncode[_, value_Integer] := "(" <> signedInteger[value] <> ")"
mathlibEncode[_, value_Rational] := "((" <> signedInteger[Numerator[value]] <> " : Rat) / " <> IntegerString[Denominator[value]] <> ")"
mathlibEncode[_, True] := "true"
mathlibEncode[_, False] := "false"
mathlibEncode[_, value_String] := "\"" <> StringJoin[Map[
	Switch[#, 34, "\\\"", 92, "\\\\", 10, "\\n", 13, "\\r", 9, "\\t",
		_, If[# < 32 || # === 127, "\\u" <> IntegerString[#, 16, 4], FromCharacterCode[#]]] &,
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

releaseEnvironment[environment_] := If[MatchQ[environment, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]],
	mathlibInvoke["LeanFreeEnvironment", Information[environment, "Handle"]]
]

elaborateSource[session_MathlibSession, state_Association, source_String, time_, failure_Failure] := Module[{environment = None, result},
	result = CheckAbort[
		TimeConstrained[environment = Quiet[Check[importSource[state, source], $Failed]], time, $TimedOut],
		releaseEnvironment[environment];
		mathlibCloseSession[session]; Abort[]
	];
	If[result === $TimedOut,
		releaseEnvironment[environment];
		mathlibCloseSession[session];
		Return[mathlibFailure["MathlibTimedOut", "Lean elaboration exceeded the time limit. The session was closed."]]
	];
	If[MatchQ[result, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]], result, failure]
]

retainExpression[session_MathlibSession, state_Association, expression_String, time_] := Module[{name, source, environment, result},
	name = "mathliblink_value_" <> StringDelete[CreateUUID[], "-"];
	source = "noncomputable def " <> name <> " := (" <> expression <> ")\n";
	environment = elaborateSource[session, state, source, time,
		mathlibFailure["MathlibElaborationFailed", "Lean could not elaborate the expression.", <|"Expression" -> expression|>]];
	If[FailureQ[environment], Return[environment]];
	result = mathlibKeepObject[session, environment[name], expression, environment];
	If[FailureQ[result], releaseEnvironment[environment]];
	result
]

MathlibEvaluate[session_MathlibSession, expression_String, opts : OptionsPattern[]] := Module[{state, time, mode, isolated, evaluationOptions, result},
	If[! mathlibOptionsQ[MathlibEvaluate, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown evaluation option."]]];
	{time, mode, isolated} = {OptionValue[TimeConstraint], OptionValue["ReturnType"], OptionValue["Isolated"]};
	If[! mathlibTimeQ[time] || ! MemberQ[{Automatic, "Object"}, mode], Return[mathlibFailure["MathlibInvalidOption", "Use a positive TimeConstraint and ReturnType Automatic or Object."]]];
	If[! BooleanQ[isolated], Return[mathlibFailure["MathlibInvalidOption", "Isolated must be True or False."]]];
	If[isolated && mode === "Object", Return[mathlibFailure["MathlibInvalidOption", "Isolated evaluation returns copied values; use ReturnType Automatic."]]];
	state = mathlibSessionData[session];
	If[FailureQ[state], Return[state]];
	If[mode === "Object", Return[retainExpression[session, state, expression, time]]];
	(* Earlier LeanLink versions always evaluate in a separate process. *)
	evaluationOptions = FilterRules[{"Isolated" -> isolated}, Options[Symbol["Wolfram`LeanLink`LeanEvaluate"]]];
	result = CheckAbort[
		If[mathlibDirectLeanQ[],
			mathlibInvoke["LeanEvaluate", state["Environment"], expression, "TimeLimit" -> time, Sequence @@ evaluationOptions],
			mathlibInvoke["LeanEvaluate", expression, "ProjectDir" -> state["Directory"], "Imports" -> state["Imports"], "TimeLimit" -> time, Sequence @@ evaluationOptions]
		],
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
	state, time, name, source, environment, term, checked, result, retained = False, started = AbsoluteTime[]
},
	If[! mathlibOptionsQ[ProveMathlib, {opts}], Return[mathlibFailure["MathlibInvalidOption", "Unknown proof option."]]];
	time = OptionValue[TimeConstraint];
	If[! mathlibTimeQ[time], Return[mathlibFailure["MathlibInvalidOption", "TimeConstraint must be positive or Infinity."]]];
	state = mathlibSessionData[session];
	If[FailureQ[state], Return[state]];
	name = "mathliblink_theorem_" <> StringDelete[CreateUUID[], "-"];
	source = "theorem " <> name <> " : " <> statement <> " := " <> proof <> "\n";
	environment = elaborateSource[session, state, source, time,
		mathlibFailure["MathlibProofFailed", "Lean did not produce the requested theorem.", <|"Statement" -> statement|>]];
	If[FailureQ[environment], Return[environment]];
	WithCleanup[
		term = environment[name];
		checked = CheckAbort[
			verifyTheorem[term, If[time === Infinity, Infinity, Max[0.001, time - (AbsoluteTime[] - started)]]],
			mathlibCloseSession[session]; Abort[]
		];
		If[checked === $TimedOut || MatchQ[checked, Failure["TimedOut", _]], mathlibCloseSession[session]; Return[mathlibFailure["MathlibTimedOut", "Kernel checking exceeded the time limit. The session was closed."]]];
		If[MatchQ[checked, Failure["UntrustedProof", _]], Return[mathlibFailure["MathlibUntrustedProof", "The theorem depends on an admitted proof or an additional axiom.", <|"Axioms" -> checked["Axioms"]|>]]];
		If[! MatchQ[checked, _Success], Return[mathlibFailure["MathlibKernelRejected", "Lean's kernel did not accept the theorem's module.", <|"Result" -> checked|>]]];
		result = mathlibKeepObject[session, term, "((" <> proof <> ") : " <> statement <> ")", environment, True, statement];
		retained = ! FailureQ[result];
		result,
		If[! retained, releaseEnvironment[environment]]
	]
]
