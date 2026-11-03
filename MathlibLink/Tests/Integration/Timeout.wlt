Needs["WolframInstitute`MathlibLink`"]

session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Sqrt"}];

(* A bounded loop avoids allocating a large list or overflowing the native stack. *)
countingExpression[limit_Integer] := "Id.run do\n  let mut n := 0\n  for _ in [0:" <> IntegerString[limit] <> "] do\n    n := n + 1\n  return n"

VerificationTest[MathlibEvaluate[session, countingExpression[1000]], 1000, TestID -> "finite-timeout-fixture-evaluates"]
VerificationTest[MathlibEvaluate[session, countingExpression[10000000], TimeConstraint -> 0.001]["Tag"], "TimedOut", TestID -> "evaluation-time-budget-enforced"]
VerificationTest[session["Status"], "Closed", TestID -> "timed-out-evaluation-invalidates-session"]

session = StartMathlibSession["Imports" -> {"Mathlib.Data.Nat.Sqrt"}];

VerificationTest[MathlibCall[session, "Nat.sqrt", 1000], 31, TestID -> "new-session-after-timeout"]
VerificationTest[MathlibEvaluate[session, "42", "Isolated" -> True], 42, TestID -> "isolated-evaluator-ready"]
VerificationTest[MathlibEvaluate[session, countingExpression[10000000], "Isolated" -> True, TimeConstraint -> 0.001]["Tag"], "TimedOut", TestID -> "isolated-time-budget-enforced"]
VerificationTest[session["Status"], "Closed", TestID -> "isolated-timeout-invalidates-session"]
