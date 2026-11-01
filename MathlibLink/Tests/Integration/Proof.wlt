Needs["WolframInstitute`MathlibLink`"]

session = StartMathlibSession[];

VerificationTest[
	With[{proof = ProveMathlib[session, "forall n : Nat, n + 0 = n", "by intro n; rfl", TimeConstraint -> 300]},
		WithCleanup[
			If[FailureQ[proof], proof, {Head[proof], proof["Verified"], Complement[proof["Axioms"], {"propext", "Classical.choice", "Quot.sound"}]}],
			If[MatchQ[proof, _MathlibObject], DeleteObject[proof]]
		]
	], {MathlibObject, True, {}}, TestID -> "kernel-checked-universal-theorem"
]

DeleteObject[session];
