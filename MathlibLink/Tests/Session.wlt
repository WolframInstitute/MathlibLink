Needs["WolframInstitute`MathlibLink`"]

VerificationTest[MathlibNames[MathlibSession["unknown"]]["Tag"], "MathlibInvalidSession", TestID -> "unknown-session-rejected"]
VerificationTest[MathlibEvaluate[MathlibSession["unknown"], "1 + 1"]["Tag"], "MathlibInvalidSession", TestID -> "evaluation-requires-session"]
VerificationTest[StartMathlibSession["Imports" -> {"Mathlib\ntheorem injected : True := by trivial"}]["Tag"], "MathlibInvalidOption", TestID -> "imports-are-module-names"]
VerificationTest[StartMathlibSession["Imports" -> {}]["Tag"], "MathlibInvalidOption", TestID -> "imports-cannot-be-empty"]
VerificationTest[StartMathlibSession["Unknown" -> 1]["Tag"], "MathlibInvalidOption", TestID -> "unknown-session-option"]
VerificationTest[MathlibEvaluate[MathlibSession["unknown"], "1", TimeConstraint -> 0]["Tag"], "MathlibInvalidOption", TestID -> "time-limit-validated-first"]
VerificationTest[MathlibEvaluate[MathlibSession["unknown"], "1", "Isolated" -> 1]["Tag"], "MathlibInvalidOption", TestID -> "isolation-requires-boolean"]
VerificationTest[MathlibEvaluate[MathlibSession["unknown"], "1", "Isolated" -> True, "ReturnType" -> "Object"]["Tag"], "MathlibInvalidOption", TestID -> "isolation-does-not-promise-native-object-protection"]
VerificationTest[Normal[MathlibObject["unknown"]]["Tag"], "MathlibInvalidObject", TestID -> "released-object-rejected"]
VerificationTest[DeleteObject[MathlibSession["unknown"]], Null, TestID -> "session-close-idempotent"]
VerificationTest[
	Block[{WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"example" -> <|"Status" -> "Ready", "Directory" -> "local", "Imports" -> {"Mathlib"}, "DeclarationCount" -> 0, "Objects" -> {}|>|>},
		DeleteObject[MathlibSession["example"]]; {MathlibSession["example"]["Status"], MathlibNames[MathlibSession["example"]]["Tag"]}
	], {"Closed", "MathlibInvalidSession"}, TestID -> "close-invalidates-session"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"timed" -> <|"Status" -> "Ready", "Directory" -> "local", "Imports" -> {"Mathlib"}, "DeclarationCount" -> 0, "Objects" -> {}|>|>,
		WolframInstitute`MathlibLink`PackageScope`mathlibInvoke = Function[Null, Pause[0.5]; $Failed]
	},
		With[{result = MathlibEvaluate[MathlibSession["timed"], "1", "ReturnType" -> "Object", TimeConstraint -> 0.01]},
			{result["Tag"], MathlibSession["timed"]["Status"]}
		]
	], {"MathlibTimedOut", "Closed"}, TestID -> "retained-expression-timeout-closes-session"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"timed" -> <|"Status" -> "Ready", "Directory" -> "local", "Imports" -> {"Mathlib"}, "DeclarationCount" -> 0, "Objects" -> {}|>|>,
		WolframInstitute`MathlibLink`PackageScope`mathlibInvoke = Function[Null, Pause[0.5]; $Failed]
	},
		With[{result = ProveMathlib[MathlibSession["timed"], "True", "by trivial", TimeConstraint -> 0.01]},
			{result["Tag"], MathlibSession["timed"]["Status"]}
		]
	], {"MathlibTimedOut", "Closed"}, TestID -> "proof-elaboration-timeout-closes-session"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"aborted" -> <|"Status" -> "Ready", "Directory" -> "local", "Imports" -> {"Mathlib"}, "DeclarationCount" -> 0, "Objects" -> {}|>|>,
		WolframInstitute`MathlibLink`PackageScope`mathlibInvoke = (Abort[] &)
	},
		CheckAbort[ProveMathlib[MathlibSession["aborted"], "True", "by trivial"], Null];
		MathlibSession["aborted"]["Status"]
	], "Closed", TestID -> "proof-interruption-closes-session"
]


VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"local" -> <|"Status" -> "Ready"|>|>,
		WolframInstitute`MathlibLink`PackageScope`$mathlibObjects = <|"proof" -> <|"Session" -> "local", "Environment" -> "owned"|>|>
	}, MathlibObject["proof"]["DocumentationURL"]], Missing["NoDocumentationURL"],
	TestID -> "local-proof-does-not-invent-upstream-link"
]

VerificationTest[
	Internal`InheritedBlock[{Wolfram`LeanLink`LeanEvaluate},
		Options[Wolfram`LeanLink`LeanEvaluate] = {"Isolated" -> False};
		Block[{
			WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"evaluation" -> <|"Status" -> "Ready", "Environment" -> "borrowed"|>|>,
			WolframInstitute`MathlibLink`PackageScope`mathlibDirectLeanQ = (True &),
			WolframInstitute`MathlibLink`PackageScope`mathlibInvoke = Function[Null, {##}]
		}, Table[MathlibEvaluate[MathlibSession["evaluation"], "42", "Isolated" -> isolated], {isolated, {False, True}}]]
	],
	{{"LeanEvaluate", "borrowed", "42", "TimeLimit" -> 120, "Isolated" -> False}, {"LeanEvaluate", "borrowed", "42", "TimeLimit" -> 120, "Isolated" -> True}},
	TestID -> "evaluation-forwards-isolation-choice"
]

VerificationTest[
	Internal`InheritedBlock[{Wolfram`LeanLink`LeanEvaluate},
		Options[Wolfram`LeanLink`LeanEvaluate] = {};
		Block[{
			WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"evaluation" -> <|"Status" -> "Ready", "Environment" -> "borrowed", "Directory" -> "local", "Imports" -> {"Init"}|>|>,
			WolframInstitute`MathlibLink`PackageScope`mathlibInvoke = Function[Null, {##}]
		}, Table[Block[{WolframInstitute`MathlibLink`PackageScope`mathlibDirectLeanQ = (direct &)},
			MathlibEvaluate[MathlibSession["evaluation"], "42", "Isolated" -> True]
		], {direct, {True, False}}]]
	],
	{{"LeanEvaluate", "borrowed", "42", "TimeLimit" -> 120}, {"LeanEvaluate", "42", "ProjectDir" -> "local", "Imports" -> {"Init"}, "TimeLimit" -> 120}},
	TestID -> "earlier-leanlink-process-evaluators-remain-supported"
]
