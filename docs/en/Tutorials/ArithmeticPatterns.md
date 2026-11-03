---
Template: TechNote
Name: ArithmeticPatterns
Title: Exact Arithmetic Patterns
Description: Compute binomial coefficients, common divisors and totients in Lean and plot the results
Context: WolframInstitute`MathlibLink`
ContextPath: [Wolfram`LeanLink`]
Paclet: WolframInstitute/MathlibLink
URI: WolframInstitute/MathlibLink/tutorial/ArithmeticPatterns
Keywords: [exact arithmetic, binomial coefficients, greatest common divisor, totient]
RelatedGuides: [MathlibLink]
RelatedTutorials: [GettingStarted, ValuesAndProofs, PartialComputations]
---

## Binomial coefficients modulo two

Exact arithmetic makes it possible to compare a Lean computation directly
with a Wolfram computation before plotting a larger pattern. Import the
binomial-coefficient and totient modules used in this experiment:

```wl
env = LeanImport["ProjectDir" -> MathlibInstallation[]["Directory"], "Imports" -> {"Mathlib.Data.Nat.Choose.Basic", "Mathlib.Data.Nat.Totient"}]
```

Compute the coefficient in Lean:

```wl
LeanEvaluate[env["Nat.choose"], 10, 4]
```

Compute it independently in Wolfram Language:

```wl
Binomial[10, 4]
```

Compute rows and columns 0 through 31 modulo two:

```wl
pascal = LeanEvaluate[env, "(List.range 32).map (fun n => (List.range 32).map (fun k => Nat.choose n k % 2))"];
```

Plot the parity pattern with the row coordinate increasing upward:

```wl
ArrayPlot[Reverse[pascal], DataRange -> {{0, 31}, {0, 31}}, FrameTicks -> Automatic, FrameLabel -> {"Row n", "Column k"}]
```

Check the entire finite array against the built-in binomial function:

```wl
pascal === Table[Mod[Binomial[n, k], 2], {n, 0, 31}, {k, 0, 31}]
```

The triangular regions repeat within this finite window. The displayed
agreement checks the computed array; a theorem about all rows would require
a statement and proof with the appropriate quantifiers.

## Common divisors

Compute the greatest common divisor of each pair of integers
from 1 to 32:

```wl
divisors = LeanEvaluate[env, "(List.range 32).map (fun n => (List.range 32).map (fun k => Nat.gcd (n + 1) (k + 1)))"];
```

Display the integer array:

```wl
ArrayPlot[divisors, FrameTicks -> Automatic, FrameLabel -> {"First integer", "Second integer"}, PlotLegends -> Automatic]
```

Large values occur at pairs sharing large divisors. The array is symmetric
because exchanging the two arguments preserves their greatest common divisor.
Inspect the corresponding theorem:

```wl
env["Nat.gcd_comm"]["TypeForm"]
```

## Totients

Euler's totient counts the integers from 1 through n that are coprime to n.
Compute the values for n from 1 through 64:

```wl
totients = LeanEvaluate[env, "(List.range 64).map (fun n => Nat.totient (n + 1))"];
```

Plot the counts:

```wl
ListPlot[totients, DataRange -> {1, 64}, AxesLabel -> {"n", "Totient"}]
```

Compare the exact list with Wolfram Language's totient function:

```wl
totients === EulerPhi[Range[64]]
```

The data remain ordinary exact integers after transfer. Wolfram plotting and
analysis functions can use them without converting theorem statements or
Lean's typeclass machinery.

Release the environment:

```wl
LeanFreeEnvironment[env]
```
