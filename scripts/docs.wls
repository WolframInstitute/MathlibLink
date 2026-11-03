Begin["PacletDevelopment`"]

script = ExpandFileName[$InputFileName];
repository = DirectoryName[DirectoryName[script]];
name = FileNameTake[repository];
paclet = FileNameJoin[{repository, name}];
mode = If[Length[$ScriptCommandLine] > 1, $ScriptCommandLine[[2]], "build"];
If[! MemberQ[{"build", "check", "publish", "page"}, mode], Print["Use build, check or publish."]; Exit[1]];
source = FileNameJoin[{repository, "docs", "en"}];
definition = FileNameJoin[{paclet, "ResourceDefinition.md"}];
documentationFiles = Sort[FileNames["*.md", source, Infinity]];
PacletDirectoryLoad[paclet];
If[PacletFind["WolframInstitute/PacletPage"] === {}, Print["Install WolframInstitute/PacletPage before building documentation."]; Exit[1]];
Needs["WolframInstitute`PacletPage`"];
If[! MemberQ[$Packages, "WolframInstitute`PacletPage`"], Exit[1]];
Print["PacletPage ", PacletObject["WolframInstitute/PacletPage"]["Version"]];
documentationTools = Environment["MATHLIBLINK_DOC_TOOLS"];
documentationOptions = {};
documentationDependencies = {"Wolfram/LeanLink"};
If[StringQ[documentationTools] && documentationTools =!= "",
	converter = FileNameJoin[{documentationTools, "MarkdownToNotebook", "MarkdownToNotebook.wl"}];
	If[! FileExistsQ[converter], Print["The pinned MarkdownToNotebook source is missing."]; Exit[1]];
	documentationOptions = {"Converter" -> converter};
	AppendTo[documentationDependencies, "Wolfram/Parser"]
];

(* As in PARILink and Ruliology, only PacletPage's fresh kernel scripts use
   the entitlement-aware launcher. Other processes and local licenses are unchanged. *)
kernelScriptQ[kernel_String] := MemberQ[{"WolframKernel", "WolframKernel.exe"}, Last[StringSplit[kernel, {"/", "\\"}]]];
SetAttributes[withEntitledKernels, HoldFirst];
withEntitledKernels[body_] := Internal`InheritedBlock[{RunProcess, StartProcess},
	Unprotect[RunProcess, StartProcess];
	DownValues[RunProcess] = Prepend[DownValues[RunProcess],
		HoldPattern[RunProcess[{kernel_String, "-noprompt", "-script", file_String}, arguments___] /; kernelScriptQ[kernel]] :>
			RunProcess[{"wolframscript", "-file", file}, arguments,
				ProcessEnvironment -> Append[Association[GetEnvironment[]], "WOLFRAMSCRIPT_KERNELPATH" -> kernel]]];
	DownValues[StartProcess] = Prepend[DownValues[StartProcess],
		HoldPattern[StartProcess[{kernel_String, "-noprompt", "-script", file_String}, options___] /; kernelScriptQ[kernel]] :>
			StartProcess[{"wolframscript", "-file", file}, options,
				ProcessEnvironment -> Append[Association[GetEnvironment[]], "WOLFRAMSCRIPT_KERNELPATH" -> kernel]]];
	Protect[RunProcess, StartProcess];
	body
];
pageCall[function_String, arguments___] := If[
	StringQ[Environment["WOLFRAMSCRIPT_ENTITLEMENTID"]] && Environment["WOLFRAMSCRIPT_ENTITLEMENTID"] =!= "",
	withEntitledKernels[Symbol["WolframInstitute`PacletPage`" <> function][arguments]],
	Symbol["WolframInstitute`PacletPage`" <> function][arguments]
];

(* Conversion can succeed while an example prints a message or returns its
   input. Check saved outputs too, including pages reused from the cache. *)
documentationIssues[file_String] := Module[{notebook, outputs, calls, failures, issues = <||>},
	notebook = Quiet[Check[Get[file], $Failed]];
	If[! MatchQ[notebook, _Notebook], Return[<|"Notebook" -> "Missing or unreadable"|>]];
	outputs = Cases[notebook, Cell[BoxData[boxes_], "Output", ___] :> boxes, Infinity];
	If[! FreeQ[notebook, Cell[_, "Message", ___]], AssociateTo[issues, "Messages" -> "Example emitted a message"]];
	calls = DeleteDuplicates[Flatten[Cases[outputs,
		RowBox[{head_, "[", ___}] :> Cases[{head}, name_String /; name =!= "" && MemberQ[{
			"LeanImport", "LeanImportString", "LeanEvaluate", "LeanVerify", "LeanFreeEnvironment",
			"StartMathlibSession", "MathlibNames", "MathlibDeclaration", "MathlibEvaluate", "MathlibCall", "ProveMathlib",
			"ArrayPlot", "ListPlot", "ListStepPlot", "Boole"
		}, Last[StringSplit[name, "`"]]], Infinity], Infinity]]];
	If[calls =!= {}, AssociateTo[issues, "UnevaluatedCalls" -> calls]];
	If[! FreeQ[outputs, "$Failed" | "$Aborted" | "$TimedOut"], AssociateTo[issues, "Evaluation" -> "Failed or interrupted"]];
	failures = DeleteDuplicates[Cases[outputs, HoldPattern[Failure[tag_, _Association]] :> tag, Infinity]];
	(* These two pages intentionally demonstrate rejection of an admitted proof. *)
	If[MemberQ[{"ProveMathlib.nb", "ValuesAndProofs.nb"}, FileNameTake[file]], failures = DeleteCases[failures, "MathlibUntrustedProof"]];
	If[FileNameTake[file] === "ValuesAndProofs.nb", failures = DeleteCases[failures, "UntrustedProof"]];
	If[FileNameTake[file] === "InstallMathlib.nb", failures = DeleteCases[failures, "MathlibInstallCancelled"]];
	If[failures =!= {}, AssociateTo[issues, "Failures" -> failures]];
	issues
];

checkDocumentation[files_List] := Module[{issues},
	issues = Select[AssociationMap[documentationIssues, DeleteDuplicates[files]], # =!= <||> &];
	If[issues =!= <||>, Print["Documentation examples failed: ", InputForm[issues]]; Exit[1]]
];

(* Imported Lean regions live until kernel exit. Evaluate each page in a fresh
   licensed process without reusing individual example results. PacletPage
   then assembles the checked page caches without reevaluating them. *)
buildPage[file_String] := Module[{worker, directories, program, result},
	directories = DeleteDuplicates[Flatten[(#["Location"] & /@ PacletFind[#] &) /@ documentationDependencies]];
	worker = CreateTemporary[];
	program = "Scan[PacletDirectoryLoad, " <> ToString[directories, InputForm, CharacterEncoding -> "PrintableASCII"] <> "];\n" <>
		"Block[{$ScriptCommandLine = " <> ToString[{script, "page", file}, InputForm, CharacterEncoding -> "PrintableASCII"] <>
		"}, Get[" <> ToString[script, InputForm, CharacterEncoding -> "PrintableASCII"] <> "]];\nExit[1];\n";
	Print["Evaluating ", FileNameTake[file]];
	result = WithCleanup[
		If[Export[worker, program, "Text", CharacterEncoding -> "UTF-8"] === $Failed, $Failed,
			RunProcess[{"wolframscript", "-file", worker}]],
		If[FileExistsQ[worker], DeleteFile[worker]]
	];
	If[! AssociationQ[result], Print["The page worker did not return a result."]; Exit[1]];
	If[result["StandardOutput"] =!= "", Print[result["StandardOutput"]]];
	If[result["StandardError"] =!= "", Print[result["StandardError"]]];
	If[result["ExitCode"] =!= 0, Print["Page evaluation failed: ", file]; Exit[1]]
];

If[mode =!= "publish",
	If[mode === "page",
		If[Length[$ScriptCommandLine] =!= 3 || ! MemberQ[Append[documentationFiles, definition], Last[$ScriptCommandLine]],
			Print["The page must be a documentation source in this checkout."]; Exit[1]
		];
		page = Last[$ScriptCommandLine],
		Scan[buildPage, Append[documentationFiles, definition]]
	];
	build = pageCall["BuildPacletDocumentation", paclet,
		"Source" -> source,
		"Files" -> If[mode === "page", {If[page === definition, First[documentationFiles], page]}, All],
		"Definition" -> If[mode === "page" && page =!= definition, None, definition],
		"Parallel" -> False, "Prune" -> (mode =!= "page"), "UseCache" -> (mode =!= "page"), "Dependencies" -> documentationDependencies,
		Sequence @@ documentationOptions
	];
	If[! AssociationQ[build] || Lookup[build, "Failed", {"Build"}] =!= {} || Lookup[build, "Unevaluated", <||>] =!= <||>,
		Print[InputForm[build]]; Exit[1]
	];
	If[mode =!= "page" && Lookup[build, "Flagged", <||>] =!= <||>,
		Print["Resolve the flagged documentation before building an archive."]; Print[InputForm[build["Flagged"]]]; Exit[1]
	];
	If[mode =!= "page" && Lookup[build, "Converted", {}] =!= {},
		Print["Documentation changed during page evaluation. Run the build again."]; Exit[1]
	];
	checkDocumentation[Join[build["Notebooks"], Replace[Lookup[build, "Definition", None], {file_String :> {file}, _ -> {}}]]];
	Print[Length[build["Notebooks"]], " documentation notebooks built."];
	If[mode === "page", Exit[0]]
];
If[mode =!= "build",
	distribution = FileNameJoin[{repository, "dist"}];
	If[! DirectoryQ[distribution], CreateDirectory[distribution]];
	If[mode === "publish",
		checkDocumentation[Append[FileNames["*.nb", FileNameJoin[{paclet, "Documentation", "English"}], Infinity], FileNameJoin[{paclet, "ResourceDefinition.nb"}]]];
		expected = FileNameJoin[{distribution, "WolframInstitute__MathlibLink-" <> PacletObject[File[paclet]]["Version"] <> ".paclet"}];
		If[! FileExistsQ[expected], Print["Restore the verified archive to dist, or run make check-publish first."]; Exit[1]];
		expectedHash = FileHash[expected, "SHA256"];
		resourceOptions = {"Build" -> False, "Parallel" -> False};
		prepared = Block[{$CloudConnected = False}, pageCall["PublishPacletPage", paclet, name, "Build" -> False, "DryRun" -> True, "ResourceOptions" -> resourceOptions]];
		If[! AssociationQ[prepared] || ! AssociationQ[prepared["Resource"]] ||
			! StringQ[prepared["Resource"]["Archive"]] || ! FileExistsQ[prepared["Resource"]["Archive"]] ||
			FileHash[prepared["Resource"]["Archive"], "SHA256"] =!= expectedHash,
			Print["The restored PacletPage build does not match the verified archive."]; Exit[1]
		];
		result = pageCall["PublishPacletPage", paclet, name, "Build" -> False, "ResourceOptions" -> resourceOptions],
		result = pageCall["PublishPacletPage", paclet, name, "Build" -> False, "DryRun" -> True]
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

End[];
