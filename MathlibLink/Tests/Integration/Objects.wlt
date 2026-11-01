Needs["WolframInstitute`MathlibLink`"]

session = StartMathlibSession["Imports" -> {"Mathlib.Analysis.Complex.Exponential"}];

VerificationTest[
	retained = MathlibEvaluate[session, "Real.exp", "ReturnType" -> "Object"];
	If[FailureQ[retained], retained, {Head[retained], StringQ[retained["TypeForm"]]}],
	{MathlibObject, True}, TestID -> "noncomputable-function-retained"
]

secondSession = StartMathlibSession["Imports" -> {"Mathlib.Analysis.Complex.Exponential"}];
VerificationTest[MathlibCall[secondSession, "id", retained]["Tag"], "MathlibObjectSession", TestID -> "retained-object-session-boundary"]
DeleteObject[session];
VerificationTest[retained["TypeForm"]["Tag"], "MathlibInvalidObject", TestID -> "close-invalidates-owned-objects"]
VerificationTest[MathlibCall[secondSession, "Nat.succ", 41], 42, TestID -> "closing-one-session-preserves-shared-environment"]
DeleteObject[secondSession];
