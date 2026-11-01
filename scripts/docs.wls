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
If[mode =!= "publish",
	build = BuildPacletDocumentation[paclet,
		"Source" -> FileNameJoin[{repository, "docs", "en"}],
		"Definition" -> FileNameJoin[{paclet, "ResourceDefinition.md"}],
		"Parallel" -> False, "Prune" -> True, "Dependencies" -> {"Wolfram/LeanLink"}
	];
	If[! AssociationQ[build] || Lookup[build, "Failed", {"Build"}] =!= {} || Lookup[build, "Unevaluated", <||>] =!= <||>,
		Print[InputForm[build]]; Exit[1]
	];
	Print[Length[build["Notebooks"]], " documentation notebooks built."]
];
If[mode =!= "build",
	distribution = FileNameJoin[{repository, "dist"}];
	If[! DirectoryQ[distribution], CreateDirectory[distribution]];
	If[mode === "publish",
		expected = FileNameJoin[{distribution, "WolframInstitute__MathlibLink-" <> PacletObject[File[paclet]]["Version"] <> ".paclet"}];
		If[! FileExistsQ[expected], Print["Restore the verified archive to dist, or run make check-publish first."]; Exit[1]];
		expectedHash = FileHash[expected, "SHA256"];
		resourceOptions = {"Build" -> False, "Parallel" -> False};
		prepared = Block[{$CloudConnected = False}, PublishPacletPage[paclet, name, "Build" -> False, "DryRun" -> True, "ResourceOptions" -> resourceOptions]];
		If[! AssociationQ[prepared] || ! AssociationQ[prepared["Resource"]] ||
			! StringQ[prepared["Resource"]["Archive"]] || ! FileExistsQ[prepared["Resource"]["Archive"]] ||
			FileHash[prepared["Resource"]["Archive"], "SHA256"] =!= expectedHash,
			Print["The restored PacletPage build does not match the verified archive."]; Exit[1]
		];
		result = PublishPacletPage[paclet, name, "Build" -> False, "ResourceOptions" -> resourceOptions],
		result = PublishPacletPage[paclet, name, "Build" -> False, "DryRun" -> True]
	];
	If[! AssociationQ[result], Print[InputForm[result]]; Exit[1]];
	archive = Lookup[result["Resource"], "Archive", None];
	If[! StringQ[archive] || ! FileExistsQ[archive], Print["No archive was built."]; Exit[1]];
	If[mode === "publish" && (FileHash[archive, "SHA256"] =!= expectedHash ||
		! TrueQ[Lookup[result["Resource"], "Deployed", False]] || ! TrueQ[Lookup[result["Check"], "OK", False]]),
		Print[InputForm[result]]; Exit[1]
	];
	output = FileNameJoin[{distribution, FileNameTake[archive]}];
	CopyFile[archive, output, OverwriteTarget -> True];
	Print["Archive: ", output]
];
