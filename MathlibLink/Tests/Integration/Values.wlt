Needs["WolframInstitute`MathlibLink`"]

session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Sqrt", "Mathlib.Data.Nat.Totient", "Mathlib.Computability.PartrecCode"}];

If[MemberQ[First /@ Options[Wolfram`LeanLink`LeanImport], "PrepareEvaluation"],
	preparedEnvironment = Wolfram`LeanLink`LeanImport["ProjectDir" -> session["Directory"], "Imports" -> session["Imports"], "Filter" -> "Nat.sqrt"];
	VerificationTest[
		{Information[preparedEnvironment, "Valid"], Wolfram`LeanLink`LeanEvaluate[preparedEnvironment["Nat.sqrt"], 1000]},
		{True, 31}, TestID -> "session-shares-usable-lean-environment"
	]
];

VerificationTest[MathlibCall[session, "Nat.sqrt", 1000], 31, TestID -> "generic-integer-root-call"]
VerificationTest[MathlibCall[session, "Nat.totient", 100], 40, TestID -> "generic-number-theory-call"]
VerificationTest[MathlibEvaluate[session, "(2 : Nat) ^ 100"], 2^100, TestID -> "large-value-lossless"]
VerificationTest[MathlibCall[session, "Int.natAbs", -42], 42, TestID -> "negative-structured-argument"]
VerificationTest[MathlibCall[session, "id", FromCharacterCode[{945, 10, 34, 92, 1}]], FromCharacterCode[{945, 10, 34, 92, 1}], TestID -> "unicode-and-control-string-roundtrip"]
VerificationTest[MathlibCall[session, "List.reverse", {1, 2, 3}], {3, 2, 1}, TestID -> "generic-list-call"]
VerificationTest[MathlibEvaluate[session, "(Nat.Partrec.Code.evaln 10 Nat.Partrec.Code.succ 5)"], 6, TestID -> "computability-code-evaluation"]

VerificationTest[MathlibCall[session, "Nat.sqrt", 1000, "Isolated" -> True], 31, TestID -> "isolated-structured-call"]
VerificationTest[MathlibEvaluate[session, "(2 : Nat) ^ 100", "Isolated" -> True], 2^100, TestID -> "isolated-exact-value"]
VerificationTest[MathlibCall[session, "Nat.totient", 100], 40, TestID -> "default-evaluation-after-isolated-call"]

DeleteObject[session];
