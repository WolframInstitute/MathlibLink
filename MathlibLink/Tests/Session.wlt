Needs["WolframInstitute`MathlibLink`"]

VerificationTest[MathlibNames[MathlibSession["unknown"]]["Tag"], "MathlibInvalidSession", TestID -> "unknown-session-rejected"]
VerificationTest[MathlibEvaluate[MathlibSession["unknown"], "1 + 1"]["Tag"], "MathlibInvalidSession", TestID -> "evaluation-requires-session"]
VerificationTest[StartMathlibSession["Imports" -> {"Mathlib\ntheorem injected : True := by trivial"}]["Tag"], "MathlibInvalidOption", TestID -> "imports-are-module-names"]
VerificationTest[StartMathlibSession["Imports" -> {}]["Tag"], "MathlibInvalidOption", TestID -> "imports-cannot-be-empty"]
VerificationTest[StartMathlibSession["Unknown" -> 1]["Tag"], "MathlibInvalidOption", TestID -> "unknown-session-option"]
VerificationTest[MathlibEvaluate[MathlibSession["unknown"], "1", TimeConstraint -> 0]["Tag"], "MathlibInvalidOption", TestID -> "time-limit-validated-first"]
VerificationTest[Normal[MathlibObject["unknown"]]["Tag"], "MathlibInvalidObject", TestID -> "released-object-rejected"]
VerificationTest[DeleteObject[MathlibSession["unknown"]], Null, TestID -> "session-close-idempotent"]
VerificationTest[
	Block[{WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"example" -> <|"Status" -> "Ready", "Directory" -> "local", "Imports" -> {"Mathlib"}, "DeclarationCount" -> 0, "Objects" -> {}|>|>},
		DeleteObject[MathlibSession["example"]]; {MathlibSession["example"]["Status"], MathlibNames[MathlibSession["example"]]["Tag"]}
	], {"Closed", "MathlibInvalidSession"}, TestID -> "close-invalidates-session"
]
