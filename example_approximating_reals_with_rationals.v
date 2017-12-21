(* This is example shows how to use a representation of the real numbers by means of rational
approximations to compute on the reals. Usually integers are prefered to avoid to many problems
that arise due to the possibility to use unnecessary high precission approximations. I tried
that approac in the other example file "example_approximating_reals_with_integers" but it lead
to extensive additional work so Igave up at some point. I feel that the approach in the present
file is more appropriate. *)

Load representations.

From mathcomp Require Import ssrnat.
Require Import Reals Lra Classical ClassicalFacts Psatz.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicits Defensive.

Local Open Scope Z_scope.
Import QArith.
Local Open Scope R_scope.

(* \begin{syntacticsuggar} *)
Fixpoint P2R n := match n with
  | xH => 1
  | xO m => 2* P2R m
  | xI k => 2* P2R k + 1
end.
(* It eludes my why this function is not provided under the name IPR in the standard Library *)
Fixpoint Z2R z := match z with
  | Z0 => 0
  | Zpos n => P2R n
  | Zneg m => - P2R m
end.
Coercion IZR : Z >-> R.
(* The translation IZR from the standard library translates to natural numbers in unary
and then to a real numbers. I think that is stuped so I tried to replace it. However, it turns
out that IZR is used in some lemmas, so I need to rely on it anyway. *)
Definition Q2R q := QArith_base.Qnum q / QArith_base.QDen q.
Coercion Q2R : Q >-> R.
(* This is not coerced since it leads to ambiguous paths. *)
(* \end{syntacticalsuggar} *)
(* It turns out that these coercions are not enough. To avoid heaps of burocracy I need to find
a way to also coerce the operators. Any hints about how to do this in a reasonable way are
appreciated *)

(* \begin{usefulllemmas} about the rational numbers provided by Laurent Thery *)
Lemma Q2R_make n d : Q2R (Qmake n d) = IZR n / IZR(' d).
Proof. by []. Qed.

Lemma Q2R_make1 n : Q2R (Qmake n 1) = IZR n.
Proof. by rewrite /Q2R /=; field. Qed.

Lemma Q2R0 : Q2R 0 = 0.
Proof. by rewrite Q2R_make1. Qed.

Lemma Q2R1 : Q2R 1 = 1.
Proof. by rewrite Q2R_make1. Qed.

Lemma plus_Q2R r1 r2 : Q2R (r1 + r2) = Q2R r1 + Q2R r2.
Proof.
rewrite /Q2R /= plus_IZR !mult_IZR.
rewrite Pos2Nat.inj_mul mult_INR /=.
field.
have H1 := pos_INR_nat_of_P (Qden r1).
have H2 := pos_INR_nat_of_P (Qden r2).
by lra.
Qed.

Lemma mul_Q2R r1 r2 : Q2R (r1 * r2) = Q2R r1 * Q2R r2.
Proof.
rewrite /Q2R /= !mult_IZR.
rewrite Pos2Nat.inj_mul mult_INR /=.
field.
have H1 := pos_INR_nat_of_P (Qden r1).
have H2 := pos_INR_nat_of_P (Qden r2).
by lra.
Qed.

Lemma opp_Q2R r : Q2R (-r) = - Q2R r.
Proof.
rewrite /Q2R /= opp_IZR.
field.
have H := pos_INR_nat_of_P (Qden r).
lra.
Qed.

Lemma minus_Q2R r1 r2 : Q2R (r1 - r2) = Q2R r1 - Q2R r2.
Proof. rewrite plus_Q2R opp_Q2R; lra. Qed.

Lemma le0_Q2R r : (0 <= r)%Q -> 0 <= Q2R r.
Proof.
rewrite /Qle /= Z.mul_1_r => /IZR_le /= H.
apply: Rmult_le_pos => //.
apply/Rlt_le/Rinv_0_lt_compat.
apply: pos_INR_nat_of_P (Qden r).
Qed.

Lemma le_Q2R r1 r2 : (r1 <= r2)%Q -> Q2R r1 <= Q2R r2.
Proof.
move=> H.
suff: 0 <= Q2R (r2 - r1) by rewrite minus_Q2R; lra.
apply: le0_Q2R; lra.
Qed.

Lemma lt0_Q2R r : (0 < r)%Q -> 0 < Q2R r.
Proof.
rewrite /Qlt /= Z.mul_1_r => /IZR_lt /= H.
apply: Rmult_lt_0_compat => //.
apply: Rinv_0_lt_compat.
apply: pos_INR_nat_of_P (Qden r).
Qed.

Lemma lt_Q2R r1 r2 : (r1 < r2)%Q -> Q2R r1 < Q2R r2.
Proof.
move=> H.
suff: 0 < Q2R (r2 - r1) by rewrite minus_Q2R; lra.
apply: lt0_Q2R; lra.
Qed.

Definition Q2Rt := (lt_Q2R, le_Q2R, minus_Q2R, opp_Q2R, mul_Q2R, plus_Q2R, Q2R_make).
(* \end{usefulllemmas} *)

Definition rep_R : (Q -> Q) -> R -> Prop :=
  fun phi x => forall eps, (0 < eps)%Q -> Rabs(x-(phi eps)) <= eps.
(* This is close to the standard definition of the chauchy representation. Usually integers
are prefered to avoid to many possible answers. I tried this in the other example file
"example_approximating_reals_with_integers" but it leads to extensive additional work so I
gave up at some point. I feel like the above is the most natural formulation of the Cauchy
representation. *)

Lemma approx : forall r, r - Int_part r <= 1.
Proof.
  move => r; move: (base_Int_part r) => [bipl bipr].
  lra.
Qed.

Lemma approx' : forall r, 0 <= r - Int_part r.
Proof.
  move => r; move: (base_Int_part r) => [bipl bipr].
  lra.
Qed.

Lemma rep_R_is_sur: is_sur rep_R.
Proof.
  move => x.
  exists (fun eps => Qmult eps (Qmake(Int_part(x/eps)) xH)).
  move => eps eg0.
  rewrite mul_Q2R.
  rewrite Q2R_make1.
  rewrite Rabs_pos_eq.
  - (* Why doesn't this work:
      set z := Int_part(x/eps).
      replace (x - eps * z) with (eps * (x / eps - z)) by field. *)
    rewrite -{1}(Rmult_1_l x).
    rewrite -(Rinv_r (eps)).
    rewrite Rmult_assoc.
    rewrite -{5}(Rmult_1_r eps).
    rewrite -(Rmult_minus_distr_l eps).
    - apply: (Rmult_le_compat_l (eps)).
      apply: le0_Q2R.
      by apply: Qlt_le_weak.
    rewrite (Rmult_comm (/eps)).
    rewrite /Rdiv.
    apply (approx (x * /eps)).
    apply: Rlt_dichotomy_converse.
    right.
    by apply: lt0_Q2R.
  apply: (Rmult_le_reg_l (/eps));last first.
  rewrite Rmult_0_r.
  rewrite Rmult_minus_distr_l.
  rewrite -Rmult_assoc.
  Search _ "Rinv".
  rewrite -(Rinv_l_sym eps).
  - rewrite Rmult_1_l.
    rewrite (Rmult_comm (/eps)).
    rewrite /Rdiv.
    apply (approx' (x * /eps)).
    apply: Rlt_dichotomy_converse.
    right.
    by apply: lt0_Q2R.
  apply : Rinv_0_lt_compat.
  by apply: lt0_Q2R.
Qed.

Lemma rep_R_is_sing: is_sing rep_R.
Admitted.

(* This is Admitted here. The proof of this statement for the more traditional cauchy representation
is carried out below. The proofs do not carry over easily but simplify a lot (compare the proof of the
surjectivity to that of the traditional cauchy representation) *)

Lemma rep_R_is_rep: is_rep rep_R.
Proof.
  split.
  - exact: rep_R_is_sur.
  - exact: rep_R_is_sing.
Qed.

Canonical rep_space_R := @make_rep_space
  R
  (Q -> Q)
  (fun n => Qmake Z0 xH)
  rep_R
  rep_R_is_rep.

Lemma id_is_computable : is_computable (id : R -> R).
Proof.
  by exists (fun phi=>phi).
Qed.
(* This is a trivial example. The proof looks nice, though... The next example uses the product
construction that was introduced in the file representations.v *)

Lemma Rplus_is_computable : is_computable (fun x => Rplus (x.1) (x.2)).
Proof.
  Definition Rplus_realizer (phi : names rep_space_R * names rep_space_R) eps : Q :=
    (Qplus (phi.1 (Qmult (Qmake 1 2) eps)) (phi.2(Qmult (Qmake 1 2) eps))).
  exists Rplus_realizer.
  move => phi x [phi0 phi1] eps eg0.
  rewrite /Rplus_realizer.
  Search _ "Ropp".
  rewrite plus_Q2R.
  set r := phi.1 (Qmult (Qmake 1 2) eps).
  set q := phi.2 (Qmult (Qmake 1 2) eps).
  rewrite /Rminus.
  rewrite Ropp_plus_distr.
  rewrite Rplus_assoc.
  Admitted.