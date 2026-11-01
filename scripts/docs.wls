Begin["PacletDevelopment`"]

repository = DirectoryName[DirectoryName[$InputFileName]];
name = FileNameTake[repository];
paclet = FileNameJoin[{repository, name}];
mode = If[Length[$ScriptCommandLine] > 1, Last[$ScriptCommandLine], "build"];
If[! MemberQ[{"build", "check", "publish"}, mode], Print["Use build, check or publish."]; Exit[1]];
PacletDirectoryLoad[paclet];
If[PacletFind["WolframInstitute/PacletPage"] === {}, Print["Install WolframInstitute/PacletPage before building documentation."]; Exit[1]];
Needs["WolframInstitute`PacletPage`"];
If[! MemberQ[$Packages, "WolframInstitute`PacletPage`"], Exit[1]];
Print["PacletPage ", PacletObject["WolframInstitute/PacletPage"]["Version"]];
build = BuildPacletDocumentation[paclet,
	"Source" -> FileNameJoin[{repository, "docs", "en"}],
	"Definition" -> FileNameJoin[{paclet, "ResourceDefinition.md"}],
	"Parallel" -> False, "Prune" -> True, "Dependencies" -> {"Wolfram/LeanLink"}
];
If[! AssociationQ[build] || Lookup[build, "Failed", {"Build"}] =!= {} || Lookup[build, "Unevaluated", <||>] =!= <||>,
	Print[InputForm[build]]; Exit[1]
];
Print[Length[build["Notebooks"]], " documentation notebooks built."];
If[mode =!= "build",
	distribution = FileNameJoin[{repository, "dist"}];
	If[! DirectoryQ[distribution], CreateDirectory[distribution]];
	result = PublishPacletPage[paclet, name, "Build" -> False, "DryRun" -> (mode === "check")];
	If[! AssociationQ[result], Print[InputForm[result]]; Exit[1]];
	archive = Lookup[result["Resource"], "Archive", None];
	If[! StringQ[archive] || ! FileExistsQ[archive], Print["No archive was built."]; Exit[1]];
	output = FileNameJoin[{distribution, FileNameTake[archive]}];
	CopyFile[archive, output, OverwriteTarget -> True];
	Print["Archive: ", output];
	If[mode === "publish" && ! TrueQ[Lookup[result["Check"], "OK", False]], Print[InputForm[result["Check"]]]; Exit[1]]
];
