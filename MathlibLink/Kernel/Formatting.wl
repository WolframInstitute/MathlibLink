PackageScoped[{mathlibSessionBoxes, mathlibObjectBoxes, mathlibExpressionBoxes}]

(* Summaries use stored data only. Displaying an object must not evaluate Lean
   code, query its native environment or repeat a proof check. *)

summaryText[text_String] := Pane[Style[text, "Input", ShowStringCharacters -> False, TextAlignment -> Left],
	ImageSize -> {{0, 480}, Automatic}, Alignment -> Left]

summaryPreview[text_String] := With[{line = StringReplace[text, {"\r\n" -> " ", "\n" -> " ", "\r" -> " ", "\t" -> " "}]},
	summaryText[If[StringLength[line] > 90, StringTake[line, 87] <> "...", line]]
]

summaryBox[head_, object_, items_List, details_List, form_] :=
	BoxForm`ArrangeSummaryBox[head, object, None, items, details, form, "Interpretable" -> Automatic]

mathlibSessionBoxes[session : MathlibSession[id_String], form_] :=
	With[{state = Lookup[$mathlibSessions, id, <||>]},
		summaryBox[MathlibSession, session,
			{
				BoxForm`SummaryItem[{"Status: ", Lookup[state, "Status", "Unavailable"]}],
				If[KeyExistsQ[state, "DeclarationCount"], BoxForm`SummaryItem[{"Declarations: ", state["DeclarationCount"]}], Nothing]
			},
			{
				If[KeyExistsQ[state, "Imports"], BoxForm`SummaryItem[{"Imports: ", Column[summaryText /@ state["Imports"]]}], Nothing],
				If[KeyExistsQ[state, "Directory"], BoxForm`SummaryItem[{"Directory: ", summaryText[state["Directory"]]}], Nothing]
			}, form]
	]

mathlibObjectBoxes[object : MathlibObject[id_String], form_] :=
	Module[{data, state, term, kind, label, content},
		data = Lookup[$mathlibObjects, id, <||>];
		state = Lookup[$mathlibSessions, Lookup[data, "Session", ""], <||>];
		If[Lookup[state, "Status", None] =!= "Ready",
			Return[summaryBox[MathlibObject, object, {BoxForm`SummaryItem[{"Status: ", "Unavailable"}]}, {}, form]]
		];
		term = Replace[Lookup[data, "Term", None], {_[values_Association] :> values, _ -> <||>}];
		kind = Which[
			TrueQ[Lookup[data, "Verified", False]], "Checked theorem",
			Lookup[data, "Environment", None] =!= None, "Typed expression",
			True, Lookup[term, "Kind", "Declaration"]
		];
		{label, content} = Which[
			StringQ[Lookup[data, "Statement", None]], {"Statement: ", data["Statement"]},
			Lookup[data, "Environment", None] =!= None, {"Expression: ", Lookup[data, "Expression", ""]},
			True, {"Name: ", Lookup[term, "Name", ""]}
		];
		summaryBox[MathlibObject, object,
			{BoxForm`SummaryItem[{"Kind: ", kind}], BoxForm`SummaryItem[{label, summaryPreview[content]}]},
			{
				If[StringLength[content] > 90, BoxForm`SummaryItem[{label, summaryText[content]}], Nothing],
				If[label =!= "Name: ", BoxForm`SummaryItem[{"Declaration: ", summaryText[Lookup[term, "Name", ""]]}], Nothing],
				BoxForm`SummaryItem[{"Session: ", Lookup[state, "Status", "Unavailable"]}]
			}, form]
	]

mathlibExpressionBoxes[expression : MathlibExpression[source_String], form_] :=
	summaryBox[MathlibExpression, expression, {BoxForm`SummaryItem[{"Source: ", summaryPreview[source]}]},
		{BoxForm`SummaryItem[{"Source: ", summaryText[source]}]}, form]
