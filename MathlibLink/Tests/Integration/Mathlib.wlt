Needs["WolframInstitute`MathlibLink`"]

session = StartMathlibSession[];
Print["Imported declarations: ", session["DeclarationCount"]];

VerificationTest[Head[session], MathlibSession, TestID -> "full-mathlib-session"]
VerificationTest[
	With[{environment = Wolfram`LeanLink`LeanImport["ProjectDir" -> session["Directory"], "Imports" -> {"Mathlib"}, "IncludeInternal" -> True]},
		MathlibNames[session] === Sort[Information[environment, "Constants"]]
	], True, TestID -> "all-imported-declarations-exposed"
]
VerificationTest[MathlibCall[session, "Nat.choose", 10, 3], 120, TestID -> "generic-binomial-call"]
VerificationTest[MathlibCall[session, "Nat.sqrt", 1000], 31, TestID -> "generic-integer-root-call"]
VerificationTest[MathlibCall[session, "Nat.totient", 100], 40, TestID -> "generic-number-theory-call"]
VerificationTest[MathlibEvaluate[session, "(2 : Nat) ^ 100"], 2^100, TestID -> "large-value-lossless"]
VerificationTest[MathlibCall[session, "Int.natAbs", -42], 42, TestID -> "negative-structured-argument"]
VerificationTest[MathlibCall[session, "id", FromCharacterCode[{945, 10, 34, 92, 1}]], FromCharacterCode[{945, 10, 34, 92, 1}], TestID -> "unicode-and-control-string-roundtrip"]
VerificationTest[MathlibCall[session, "List.reverse", {1, 2, 3}], {3, 2, 1}, TestID -> "generic-list-call"]
VerificationTest[MathlibEvaluate[session, "(Nat.Partrec.Code.evaln 10 Nat.Partrec.Code.succ 5)"], 6, TestID -> "computability-code-evaluation"]
VerificationTest[
	AllTrue[{"mul_comm", "Real.exp_add", "Continuous.comp", "Nat.Partrec.Code.exists_code"},
		StringQ[MathlibDeclaration[session, #]["TypeForm"]] &], True, TestID -> "algebra-analysis-topology-computability-types"
]
VerificationTest[
	StringStartsQ[MathlibDeclaration[session, "Nat.Partrec.Code.exists_code"]["DocumentationURL"], "https://leanprover-community.github.io/mathlib4_docs/Mathlib/Computability/PartrecCode.html#"],
	True, TestID -> "official-declaration-documentation-link"
]
proof = ProveMathlib[session, "forall n : Nat, n + 0 = n", "by intro n; rfl"];
VerificationTest[{Head[proof], proof["Verified"], Complement[proof["Axioms"], {"propext", "Classical.choice", "Quot.sound"}]}, {MathlibObject, True, {}}, TestID -> "kernel-checked-universal-theorem"]
VerificationTest[ProveMathlib[session, "False", "by sorry"]["Tag"], "MathlibUntrustedProof", TestID -> "admitted-proof-rejected"]
VerificationTest[FailureQ[ProveMathlib[session, "(2 : Nat) + 2 = 4", "by native_decide"]], True, TestID -> "native-decide-not-trusted"]
VerificationTest[FailureQ[ProveMathlib[session, "(2 : Nat) + 2 = 5", "by decide"]], True, TestID -> "false-theorem-rejected"]
retained = MathlibEvaluate[session, "Real.exp", "ReturnType" -> "Object"];
VerificationTest[{Head[retained], StringQ[retained["TypeForm"]]}, {MathlibObject, True}, TestID -> "noncomputable-function-retained"]
secondSession = StartMathlibSession[];
VerificationTest[MathlibCall[secondSession, "id", retained]["Tag"], "MathlibObjectSession", TestID -> "retained-object-session-boundary"]
DeleteObject[session];
VerificationTest[retained["TypeForm"]["Tag"], "MathlibInvalidObject", TestID -> "close-invalidates-owned-objects"]
VerificationTest[MathlibCall[secondSession, "Nat.succ", 41], 42, TestID -> "closing-one-session-preserves-shared-environment"]
DeleteObject[secondSession];
timeoutSession = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Sqrt"}];
VerificationTest[FailureQ[MathlibEvaluate[timeoutSession, "(List.range 1000000).sum", TimeConstraint -> 0.001]], True, TestID -> "evaluation-time-budget-enforced"]
VerificationTest[timeoutSession["Status"], "Closed", TestID -> "timed-out-process-invalidates-session"]
