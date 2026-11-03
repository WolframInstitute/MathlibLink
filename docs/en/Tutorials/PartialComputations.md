---
Template: TechNote
Name: PartialComputations
Title: Observing Partial Computations
Description: Inspect a formal computation model and compare bounded observations with its semantics
Context: WolframInstitute`MathlibLink`
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/tutorial/PartialComputations
Keywords: [computability, partial recursive functions, fuel, formal model]
RelatedGuides: [MathlibLink]
RelatedTutorials: [GettingStarted, ArithmeticPatterns, ValuesAndProofs]
---

## A formal code language

Mathlib's `Nat.Partrec.Code` represents partial recursive functions on natural
numbers. It includes zero, successor, pairing, composition, primitive
recursion and minimization. Its semantics can describe computations that do
not return a value. The
[upstream reference](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Computability/PartrecCode.html)
connects codes to the partial-recursive function class.

Import the partial-recursive code model:

```wl
session = StartMathlibSession["Imports" -> {"Mathlib.Computability.PartrecCode"}]
```

Read its quantified statement:

```wl
MathlibDeclaration[session, "Nat.Partrec.Code.exists_code"]["TypeForm"]
```

The theorem gives a code for every function in the stated class. It does not
assert that every such code terminates on every input.

## A bounded evaluator

The executable `evaln` takes a finite structural bound. It gives an optional
result: a value if the bounded observation finishes, or no value when it does
not. This fuel is specific to mathlib's evaluator; it is not elapsed time or
a count of Wolfram evaluation steps.

Compose successor with itself and observe inputs 0 through 15 with fuel 20:

```wl
MathlibEvaluate[session, "(List.range 16).map (fun n => Nat.Partrec.Code.evaln 20 (.comp .succ .succ) n)"]
```

Measure which inputs finish as fuel increases from 1 through 20:

```wl
finished = MathlibEvaluate[session, "(List.range 20).map (fun k => (List.range 16).map (fun n => (Nat.Partrec.Code.evaln (k + 1) (.comp .succ .succ) n).isSome))"];
```

Display the completion map with increasing fuel to the right. Black cells mark
a returned value; white cells mark an unfinished observation:

```wl
ArrayPlot[Reverse[Transpose[Boole[finished]]], DataRange -> {{1, 20}, {0, 15}}, FrameTicks -> Automatic, FrameLabel -> {"Input", "Fuel"}]
```

Count completed inputs at each fuel level:

```wl
ListStepPlot[Total /@ Boole[finished], DataRange -> {1, 20}, AxesLabel -> {"Fuel", "Completed inputs"}]
```

A blank entry at a small fuel level is an unfinished observation. It does not
prove divergence. The larger bounds in the plot can establish completion for
additional inputs.

## Relating observations to semantics

Inspect the theorem that relates a returned bounded result to the partial
semantics:

```wl
MathlibDeclaration[session, "Nat.Partrec.Code.evaln_sound"]["TypeForm"]
```

Inspect the converse statement for a computation that has a semantic result:

```wl
MathlibDeclaration[session, "Nat.Partrec.Code.evaln_complete"]["TypeForm"]
```

These declarations specify the connection between finite observations and the
formal semantics. A compiler targeting this model needs its own simulation
proof before the model's computability results can be transferred to another
language.

Close the session:

```wl
DeleteObject[session]
```
