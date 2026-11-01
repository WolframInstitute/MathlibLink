Begin["MathlibDevelopment`"];
repository = DirectoryName[DirectoryName[$InputFileName]];
SetDirectory[repository];
PacletDirectoryLoad[FileNameJoin[{repository, "MathlibLink"}]];
If[! TrueQ[Check[Needs["WolframInstitute`MathlibLink`"]; True, False]], Exit[1]];
arguments = Rest[$ScriptCommandLine];
mode = If[arguments === {}, "local", First[arguments]];
files = If[mode === "mathlib", FileNames["*.wlt", "MathlibLink/Tests/Integration"], FileNames["*.wlt", "MathlibLink/Tests"]];
If[mode === "mathlib",
	If[Length[arguments] =!= 2, Print["Use make test-mathlib to run each live phase in a fresh kernel."]; Exit[2]];
	files = Select[files, ExpandFileName[#] === ExpandFileName[Last[arguments]] &];
	If[Length[files] =!= 1, Print["Unknown live test phase: ", Last[arguments]]; Exit[2]]
];
reportName = mode <> If[mode === "mathlib", "-" <> FileBaseName[First[files]], ""];
If[! DirectoryQ["build"], CreateDirectory["build"]];
eventFile = FileNameJoin[{"build", "Tests-" <> reportName <> "-events.wl"}];
Export[eventFile, "", "Text"];
runtimeFailure = False;

testResources[] := Module[{resources, status, files},
	resources = <|"KernelMemoryInUse" -> MemoryInUse[], "KernelMaxMemoryUsed" -> MaxMemoryUsed[]|>;
	If[StringStartsQ[$SystemID, "Linux"],
		status = Replace[Quiet[Check[ReadString["/proc/self/status"], ""]], Except[_String] -> ""];
		AssociateTo[resources, "ProcessMemory" -> Select[StringSplit[status, "\n"], StringStartsQ[#, "VmRSS:" | "VmHWM:"] &]];
		files = Select[FileNameJoin[{"/sys/fs/cgroup", #}] & /@ {"memory.current", "memory.peak", "memory.max", "memory.events"}, FileExistsQ];
		AssociateTo[resources, "CgroupMemory" -> AssociationMap[Quiet[Check[ReadString[#], "Unavailable"]] &, files]]
	];
	resources
];

recordTestEvent[event_Association] := Module[{record, test},
	If[event["EventName"] === "RuntimeFailure", runtimeFailure = True];
	record = Join[<|"Time" -> DateString[Now, "ISODateTime"]|>, KeyTake[event, {"EventName", "TestFileName", "Outcome", "Failure"}], testResources[]];
	test = Lookup[event, "TestObject", None];
	If[test =!= None,
		AssociateTo[record, "TestID" -> test["TestID"]];
		If[event["EventName"] === "TestEvaluated",
			AssociateTo[record, AssociationMap[test[#] &, {"ActualOutput", "ExpectedOutput", "ActualMessages", "AbsoluteTimeUsed"}]]
		]
	];
	PutAppend[record, eventFile];
	Print[Lookup[record, "TestID", Lookup[record, "TestFileName", "Tests"]], ": ", Lookup[record, "Outcome", event["EventName"]],
		"; kernel memory ", Round[record["KernelMemoryInUse"]/2.^20], " MiB"];
	If[KeyExistsQ[record, "Outcome"] && ! MemberQ[{"Success", "NotEvaluated"}, record["Outcome"]],
		Print[ToString[KeyTake[record, {"ActualOutput", "ExpectedOutput", "ActualMessages", "Failure"}], InputForm]]
	]
];

Print["Test environment: ", InputForm[<|"SystemID" -> $SystemID, "CharacterEncoding" -> $CharacterEncoding|>]];
reports = TestReport[#, ProgressReporting -> False,
	HandlerFunctions -> AssociationThread[{"FileStarted", "TestCreated", "TestEvaluated", "RuntimeFailure"}, ConstantArray[recordTestEvent, 4]]] & /@ files;
Scan[Function[report,
	Print[report["TestsSucceededCount"], " passed; ", report["TestsFailedCount"], " failed"];
	Scan[Function[result, If[result["Outcome"] =!= "Success", Print[result["TestID"], ": ", InputForm[result["ActualOutput"]]]]], Values[report["TestResults"]]]
], reports];
Put[reports, FileNameJoin[{"build", "Tests-" <> reportName <> ".wl"}]];
Exit[If[! runtimeFailure && files =!= {} && AllTrue[reports,
	MatchQ[#, _TestReportObject] && #["TestsSucceededCount"] > 0 && #["TestsFailedCount"] === 0 &], 0, 1]];
