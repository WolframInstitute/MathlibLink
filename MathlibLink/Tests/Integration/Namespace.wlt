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
VerificationTest[
	AllTrue[{"mul_comm", "Real.exp_add", "Continuous.comp", "Nat.Partrec.Code.exists_code"},
		StringQ[MathlibDeclaration[session, #]["TypeForm"]] &], True, TestID -> "algebra-analysis-topology-computability-types"
]
VerificationTest[
	StringStartsQ[MathlibDeclaration[session, "Nat.Partrec.Code.exists_code"]["DocumentationURL"], "https://leanprover-community.github.io/mathlib4_docs/Mathlib/Computability/PartrecCode.html#"],
	True, TestID -> "official-declaration-documentation-link"
]

DeleteObject[session];
