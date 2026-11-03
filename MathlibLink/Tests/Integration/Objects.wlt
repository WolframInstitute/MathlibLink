Needs["WolframInstitute`MathlibLink`"]

session = StartMathlibSession["Imports" -> {"Mathlib.Analysis.Complex.Exponential"}];

VerificationTest[
	retained = MathlibEvaluate[session, "Real.exp", "ReturnType" -> "Object"];
	If[FailureQ[retained], retained, {Head[retained], StringQ[retained["TypeForm"]]}],
	{MathlibObject, True}, TestID -> "noncomputable-function-retained"
]

secondSession = StartMathlibSession["Imports" -> {"Mathlib.Analysis.Complex.Exponential"}];
VerificationTest[MathlibCall[secondSession, "id", retained]["Tag"], "MathlibObjectSession", TestID -> "retained-object-session-boundary"]
MathlibCall[session, "Nat.succ", 0, "Isolated" -> True];
directLeanQ = Names["Wolfram`LeanLink`LeanVerify"] =!= {};
If[directLeanQ,
	sharedEnvironment = Wolfram`LeanLink`LeanImport["Mathlib.Analysis.Complex.Exponential", "ProjectDir" -> session["Directory"]];
	sharedHandle = Information[sharedEnvironment, "Handle"];
	sharedWorker = Wolfram`LeanLink`Private`$evaluationWorkers[sharedHandle]["Process"]
];
DeleteObject[session];
VerificationTest[retained["TypeForm"]["Tag"], "MathlibInvalidObject", TestID -> "close-invalidates-owned-objects"]
VerificationTest[MathlibCall[secondSession, "Nat.succ", 41], 42, TestID -> "closing-one-session-preserves-shared-environment"]
If[directLeanQ,
	VerificationTest[ProcessStatus[sharedWorker], "Running", TestID -> "shared-isolated-evaluator-survives-first-session-close"]
];
DeleteObject[secondSession];

If[directLeanQ,
	VerificationTest[ProcessStatus[sharedWorker], "Finished", TestID -> "last-session-close-stops-isolated-evaluator"];
	VerificationTest[Information[sharedEnvironment, "Valid"], True, TestID -> "session-close-preserves-borrowed-lean-environment"];
	Wolfram`LeanLink`LeanFreeEnvironment[sharedEnvironment];
	reopened = StartMathlibSession["Imports" -> {"Mathlib.Analysis.Complex.Exponential"}];
	VerificationTest[MathlibCall[reopened, "Nat.succ", 41], 42, TestID -> "session-reloads-explicitly-freed-environment"];
	DeleteObject[reopened]
];
