Needs["WolframInstitute`MathlibLink`"]

VerificationTest[
	And @@ Flatten[Table[
		With[{object = value}, ToExpression[ToBoxes[object, form], form, HoldComplete] === HoldComplete[object]],
		{value, {MathlibSession["unknown"], MathlibObject["unknown"], MathlibExpression["(3 : Fin 5)"]}},
		{form, {StandardForm, TraditionalForm}}
	]], True, TestID -> "summary-copy-preserves-underlying-objects"
]

VerificationTest[
	And @@ Table[
		With[{object = value}, ToExpression[ToString[object, InputForm], InputForm, HoldComplete] === HoldComplete[object]],
		{value, {MathlibSession["unknown"], MathlibObject["unknown"], MathlibExpression["\"a\\n\\\"b\" : String"]}}
	], True, TestID -> "input-form-preserves-identifiers-and-source"
]

VerificationTest[
	With[{object = MathlibExpression[StringRepeat[FromCharacterCode[945] <> " + ", 100] <> "0\n"]},
		ToExpression[ToBoxes[object], StandardForm, HoldComplete] === HoldComplete[object]
	], True, TestID -> "long-unicode-source-roundtrips-through-summary"
]

VerificationTest[
	Module[{queries = 0, term, boxes},
		term[_Association][_String] := (queries++; $Failed);
		Block[{
			WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"local" -> <|"Status" -> "Ready", "Imports" -> {"Mathlib"}, "Directory" -> "local", "DeclarationCount" -> 1|>|>,
			WolframInstitute`MathlibLink`PackageScope`$mathlibObjects = <|"proof" -> <|"Session" -> "local", "Term" -> term[<|"Name" -> "example", "Kind" -> "theorem"|>], "Verified" -> True, "Statement" -> "forall n : Nat, n = n", "Environment" -> "owned"|>|>
		},
			boxes = ToBoxes /@ {MathlibSession["local"], MathlibObject["proof"]};
			{queries, StringContainsQ[ToString[boxes, InputForm], "Checked theorem"], StringContainsQ[ToString[boxes, InputForm], "forall n : Nat, n = n"]}
		]
	], {0, True, True}, TestID -> "summary-uses-stored-metadata-without-querying-lean"
]

VerificationTest[
	Block[{
		WolframInstitute`MathlibLink`PackageScope`$mathlibSessions = <|"local" -> <|"Status" -> "Closed"|>|>,
		WolframInstitute`MathlibLink`PackageScope`$mathlibObjects = <|"proof" -> <|"Session" -> "local", "Verified" -> True|>|>
	},
		With[{boxes = ToBoxes /@ {MathlibSession["local"], MathlibObject["proof"]}},
			{StringContainsQ[ToString[boxes[[1]], InputForm], "Closed"], StringContainsQ[ToString[boxes[[2]], InputForm], "Unavailable"], ! StringContainsQ[ToString[boxes[[2]], InputForm], "Checked theorem"]}
		]
	], {True, True, True}, TestID -> "closed-session-does-not-display-live-proof"
]
