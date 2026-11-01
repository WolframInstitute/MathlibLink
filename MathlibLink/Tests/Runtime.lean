import Mathlib

set_option warningAsError true

namespace MathlibLinkCI

#guard Nat.choose 10 3 = 120
#guard Nat.sqrt 1000 = 31
#guard Nat.totient 100 = 40
#guard Int.natAbs (-42) = 42
#guard (2 : Nat) ^ 100 = 1267650600228229401496703205376
#guard List.reverse [1, 2, 3] = [3, 2, 1]
#guard Nat.Partrec.Code.evaln 10 Nat.Partrec.Code.succ 5 = some 6

theorem add_zero (n : Nat) : n + 0 = n := by rfl
example (x y : ℝ) : Real.exp (x + y) = Real.exp x * Real.exp y := Real.exp_add x y
example : Continuous (fun x : ℝ => x) := continuous_id

#check Nat.Partrec.Code.exists_code
#print axioms add_zero

end MathlibLinkCI
