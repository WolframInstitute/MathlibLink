Needs["WolframInstitute`MathlibLink`"]

session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Sqrt"}];

VerificationTest[MathlibEvaluate[session, "(List.range 1000000).sum", TimeConstraint -> 0.001]["Tag"], "TimedOut", TestID -> "evaluation-time-budget-enforced"]
VerificationTest[session["Status"], "Closed", TestID -> "timed-out-process-invalidates-session"]
