Needs["WolframInstitute`MathlibLink`"]

VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibEncode[None, 2^100],
	"(1267650600228229401496703205376)", TestID -> "large-integer-exact"
]
VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibEncode[None, -2/3],
	"((-2 : Rat) / 3)", TestID -> "rational-keeps-type"
]
VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibEncode[None, {True, False, {1, 2}}],
	"[true, false, [(1), (2)]]", TestID -> "structured-values-recursive"
]
VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibEncode[None, MathlibExpression["(3 : Fin 5)"]],
	"((3 : Fin 5))", TestID -> "explicit-typed-expression"
]
VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibEncode[None, 1.25]["Tag"],
	"MathlibUnsupportedValue", TestID -> "no-implicit-machine-real-rounding"
]
VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibQuoteName["Nat.add_comm"],
	"«Nat».«add_comm»", TestID -> "qualified-names-quoted"
]

VerificationTest[
	ToCharacterCode[WolframInstitute`MathlibLink`PackageScope`mathlibEncode[None, FromCharacterCode[945]]],
	{34, 945, 34}, TestID -> "unicode-string-not-double-encoded"
]
VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibEncode[None, "a\n\"b\\c"],
	"\"a\\n\\\"b\\\\c\"", TestID -> "lean-string-escaping"
]
VerificationTest[
	WolframInstitute`MathlibLink`PackageScope`mathlibEncode[None, -42], "(-42)", TestID -> "negative-integer-sign"
]
