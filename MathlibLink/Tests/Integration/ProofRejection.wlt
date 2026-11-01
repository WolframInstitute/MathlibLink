Needs["WolframInstitute`MathlibLink`"]

session = StartMathlibSession["Imports" -> {"Lean"}];

VerificationTest[
	{ProveMathlib[session, "False", "by sorry"]["Tag"], session["Status"]},
	{"MathlibUntrustedProof", "Ready"}, TestID -> "admitted-proof-rejected"
]
VerificationTest[
	{ProveMathlib[session, "(2 : Nat) + 2 = 4", "by native_decide"]["Tag"], session["Status"]},
	{"MathlibUntrustedProof", "Ready"}, TestID -> "native-decide-not-trusted"
]
VerificationTest[
	{ProveMathlib[session, "(2 : Nat) + 2 = 5", "by decide"]["Tag"], session["Status"]},
	{"MathlibProofFailed", "Ready"}, TestID -> "false-theorem-rejected"
]

DeleteObject[session];
