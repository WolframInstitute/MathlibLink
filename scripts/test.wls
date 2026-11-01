Begin["MathlibDevelopment`"];
repository = DirectoryName[DirectoryName[$InputFileName]];
SetDirectory[repository];
PacletDirectoryLoad[FileNameJoin[{repository, "MathlibLink"}]];
If[! TrueQ[Check[Needs["WolframInstitute`MathlibLink`"]; True, False]], Exit[1]];
mode = If[Length[$ScriptCommandLine] > 1, Last[$ScriptCommandLine], "local"];
files = If[mode === "mathlib", FileNames["*.wlt", "MathlibLink/Tests/Integration"], FileNames["*.wlt", "MathlibLink/Tests"]];
reports = TestReport /@ files;
Scan[Function[report,
	Print[report["TestsSucceededCount"], " passed; ", report["TestsFailedCount"], " failed"];
	Scan[Function[result, If[result["Outcome"] =!= "Success", Print[result["TestID"], ": ", InputForm[result["ActualOutput"]]]]], Values[report["TestResults"]]]
], reports];
If[! DirectoryQ["build"], CreateDirectory["build"]];
Put[reports, FileNameJoin[{"build", "Tests-" <> mode <> ".wl"}]];
Exit[If[files =!= {} && AllTrue[reports, MatchQ[#, _TestReportObject] && #["TestsFailedCount"] === 0 &], 0, 1]];
