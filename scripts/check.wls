Begin["MathlibDevelopment`"];
repository = DirectoryName[DirectoryName[$InputFileName]];
paclet = FileNameJoin[{repository, "MathlibLink"}];
SetDirectory[repository];
PacletDirectoryLoad[paclet];
loaded = Check[Needs["WolframInstitute`MathlibLink`"]; True, False];
If[! loaded, Print["MathlibLink did not load cleanly."]; Exit[1]];
files = Join[FileNames["*.wl", FileNameJoin[{paclet, "Kernel"}], Infinity], FileNames["*.wlt", FileNameJoin[{paclet, "Tests"}], Infinity]];
syntax = AllTrue[files, Function[file, Check[ReadList[file, Hold[Expression]]; True, Print["Syntax: ", file]; False]]];
symbols = Names["WolframInstitute`MathlibLink`*"];
coverage = AllTrue[symbols, Function[symbol, With[{name = Last[StringSplit[symbol, "`"]]},
	If[FileExistsQ[FileNameJoin[{repository, "docs", "en", "ReferencePages", "Symbols", name <> ".md"}]], True, Print["Missing reference page: ", name]; False]
]]];
usage = AllTrue[symbols, Function[symbol, StringQ[ToExpression[symbol <> "::usage"]]]];
metadata = PacletObject[File[paclet]];
valid = metadata["Name"] === "WolframInstitute/MathlibLink" && metadata["Version"] === "0.1.2";
Print[Length[files], " source/test files; ", Length[symbols], " public symbols."];
Exit[If[syntax && coverage && usage && valid, 0, 1]];
