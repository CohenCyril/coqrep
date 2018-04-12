Require Import Reals ssreflect ssrbool Psatz.

Set Bullet Behavior "None". 

Open Scope R_scope.

Definition Rgt0_bool x := (if total_order_T x 0 is inright _ then true else false).

Inductive Rgt0_bool_spec (x : R) : bool -> Type := 
   Rgt0_bool_spec1 :  x > 0 -> Rgt0_bool_spec x true
  |Rgt0_bool_spec2 :  x <= 0 -> Rgt0_bool_spec x false.

Lemma Rgt_boolP x : Rgt0_bool_spec x (Rgt0_bool x).
Proof.
by rewrite /Rgt0_bool; case: total_order_T => [[H|H]|H];
  ((apply: Rgt0_bool_spec1 ; lra) || (apply: Rgt0_bool_spec2 ; lra)).
Qed.

Definition Req_bool x y := (if total_order_T x y is inleft (right _) then true else false).

Lemma Req_bool_id x : Req_bool x x = true.
Proof.
by rewrite /Req_bool; case: total_order_T => [[|//]|]; lra.
Qed.

Inductive Req_bool_spec (x y : R) : bool -> Type := 
   Req_bool_spec1 :  x = y -> Req_bool_spec x y true
  |Req_bool_spec2 :  x <> y -> Req_bool_spec x y false.

Lemma Req_boolP x y : Req_bool_spec x y (Req_bool x y).
Proof.
rewrite /Req_bool; case: total_order_T => [[H|H]|H]; 
  ((apply: Req_bool_spec1 ; lra) || (apply: Req_bool_spec2 ; lra)).
Qed.

Definition acos x := 
  match total_order_T x 0 with
  | inleft (left _) => PI + atan (sqrt (1 - x * x) / x)
  | inleft (right _) => PI / 2
  | inright _  => atan (sqrt (1 - x * x) / x)
  end.

Lemma acos_0 : acos 0 = PI/2.
Proof. by rewrite /acos; case: total_order_T => [[]|]; lra. Qed.

Lemma acos_1 : acos 1 = 0.
Proof. 
rewrite /acos; case: total_order_T => [[]|]; try lra.
by rewrite Rminus_diag_eq ?sqrt_0 ?[_/_]Rmult_0_l ?atan_0; lra.
Qed.

Lemma acos_opp x : acos (- x) = PI - acos x.
Proof.
(rewrite /acos; do 2 case: total_order_T => [[]|]; try lra) => 
     H _; rewrite Rmult_opp_opp.
  by rewrite /Rminus -atan_opp [-(_/x)]Ropp_mult_distr_r Ropp_inv_permute; lra.
rewrite /Rdiv -Ropp_inv_permute; try lra.
by rewrite -Ropp_mult_distr_r atan_opp; lra.
Qed.

Lemma acos_atan x : 0 < x -> acos x = atan (sqrt (1 - x * x) / x).
Proof. by rewrite /acos; case: total_order_T => [[]|]; lra. Qed.

Lemma acos_bound x : -1 <= x <= 1 -> 0 <= acos x <= PI.
Proof.
move=> xB.
suff F y : 0 <= y <= 1 -> 0 <= acos y <= PI => [|Hy].
  have [H|H] : 0 <= x \/ x <= 0 by lra.
    by apply: F; lra.
  have : 0 <= acos (-x)  <= PI by apply: F; lra.
  by rewrite acos_opp; lra.
have PIP := PI_RGT_0.
have [->|yP] : y = 0 \/ 0 < y by lra.
  by rewrite acos_0; lra.
rewrite acos_atan; try lra.
have [->|yO] : y = 1 \/ y < 1 by lra.
  by rewrite Rmult_1_l Rminus_diag_eq // sqrt_0 [_/_]Rmult_0_l atan_0; lra.
set a := _ / _.
have Ha := atan_bound a.
suff : 0 < atan a by lra.
rewrite -atan_0; apply: atan_increasing.
apply: Rdiv_lt_0_compat => //.
by apply: sqrt_lt_R0; nra.
Qed.

Lemma atan_eq0 x : atan x = 0 -> x = 0.
Proof.
have := atan_increasing 0 x.
have := atan_increasing x 0.
rewrite atan_0.
lra.
Qed.

Lemma IZR_case k : [\/ IZR k <= -1, IZR k = 0 | IZR k >= 1].
Proof.
have [H1|[->|H1]] : (k <= - 1 \/ k = 0 \/ k >= 1)%Z by lia.
- by apply: Or31; apply: IZR_le (-1)%Z _.
- by apply: Or32.
by apply: Or33; apply: IZR_ge 1%Z _.
Qed.

Lemma atan_left_inv x : - PI / 2 < x < PI / 2 -> atan (tan x) = x.
Proof.
move=> xB.
apply: tan_is_inj; try lra.
  apply: atan_bound.
apply: atan_right_inv.
Qed.

Lemma cos_is_inj x y : 0 <= x <= PI -> 0 <= y <= PI -> cos x = cos y -> x = y.
Proof.
move=> xP yP Hcos.
have [H | [->//|H]] : (x < y) \/ (x = y) \/ (y < x) by lra.
  suff: cos y < cos x by lra.
  by apply: cos_decreasing_1; lra.
suff: cos x < cos y by lra.
by apply: cos_decreasing_1; lra.
Qed.

Lemma acos_right_inv x : -1 <= x <= 1 -> cos (acos x) = x.
Proof.
move=> HB.
suff HP y : 0 < y <= 1 -> cos (acos y) = y => [|[H1 H2]].
  have [->|[H|H]] : x = 0 \/ -1 <= x < 0 \/ 0 < x <= 1 by lra.
  - by rewrite acos_0 cos_PI2.
  - have : cos (acos (-x)) = -x by apply: HP; lra.
    by rewrite acos_opp [_ - _]Rplus_comm neg_cos -cos_sym; lra.
  by apply: HP.
rewrite acos_atan; try lra.
set A := atan _.
have AB : - PI / 2 < A < PI / 2 by apply: atan_bound.
have [|yNz] : y = 1 \/ y < 1 by lra.
  rewrite /A => ->.
  rewrite Rmult_1_l Rminus_diag_eq // sqrt_0 [0/_]Rmult_0_l.
  by rewrite atan_0 cos_0.
have ANZ : A <> 0.
  move=> /atan_eq0/Rmult_integral[H3|].
    have [] : 1 - y * y <> 0 by nra.
    by apply: sqrt_eq_0; nra.
  by apply: Rinv_neq_0_compat; lra.
have cosANZ : cos A <> 0.
  move/cos_eq_0_0=> [k Hk].
  by case: (IZR_case k) => H; nra.
have sinANZ : sin A <> 0.
  move/sin_eq_0_0=> [k Hk].
  case: (IZR_case k) => H; try nra.
have H3 := sin2_cos2 A.
rewrite /Rsqr in H3.
have := (eq_refl ((tan A)^2)).
rewrite {1}atan_right_inv /tan !Rpow_mult_distr -!Rinv_pow; try lra.
move=> H4.
have : sqrt (1 - y * y) ^ 2 * cos A ^ 2 - y ^ 2 * sin A ^ 2 = 0.
  have F a b : b <> 0 -> a = (a */ b) * b by move=> *; field.
  rewrite [sqrt _ ^ 2](F _ (y^2)) ?H4 ; try nra.
  by field.
rewrite (_ : (sin A)^2 = 1 - (cos A)^2); try lra.
rewrite -Rsqr_pow2 [Rsqr _]sqrt_sqrt; try nra.
move=> H5; ring_simplify in H5.
have /Rmult_integral[] : (y - cos A) * (y + cos A) = 0 by nra.
  by lra.
have sP : 0 < sqrt (1 - y * y) by apply: sqrt_lt_R0; nra.
have AP : 0 < A.
  rewrite -atan_0; apply: atan_increasing.
suff :  0 / y < sqrt (1 - y * y) / y by lra.
apply: Rmult_lt_compat_r; last by lra.
by apply: Rinv_0_lt_compat; lra.
suff : 0 < cos A by lra.
by apply: cos_gt_0; lra.
Qed.

Lemma acos_left_inv x : 0 <= x <= PI -> acos (cos x) = x.
Proof.
move=> HB.
apply: cos_is_inj => //.
  apply: acos_bound.
  apply: COS_bound.
apply/acos_right_inv/COS_bound.
Qed.

Definition Tcheby n x := cos (INR n * acos x).
Notation "'T_ n x" := (Tcheby n x) (at level 10, format "''T_' n  x").

Lemma Tcheby_0 x : -1 <= x <= 1 -> Tcheby 0 x = 1.
Proof. by rewrite /Tcheby Rmult_0_l cos_0. Qed.

Lemma Tcheby_1 x : -1 <= x <= 1 -> Tcheby 1 x = x.
Proof. by rewrite /Tcheby Rmult_1_l; exact: acos_right_inv. Qed.

Lemma Tcheby_cos n a : 0 <= a <= PI -> Tcheby n (cos a) = cos ((INR n) * a).
Proof. by move=> *; rewrite /Tcheby acos_left_inv. Qed.

Lemma cos_add_INR a n : cos (a + INR n * PI) = if Nat.even n then cos a else -cos a.
Proof.
elim: n => [|n IH]; first by rewrite /= Rmult_0_l Rplus_0_r.
rewrite S_INR Rmult_plus_distr_r Rmult_1_l -Rplus_assoc.
rewrite neg_cos IH Nat.even_succ -Nat.negb_even.
by case: Nat.even => /=; lra.
Qed.

Lemma Tcheby_compi m n a : -1 <= a <= 1 -> Tcheby n (Tcheby m a) = Tcheby (n * m) a.
Proof.
move=> Ha.
have U := acos_bound _ Ha.
rewrite /Tcheby mult_INR Rmult_assoc.
set v := _ * acos a.
have HP := PI2_1;
have [k [r [-> Hr]]] : exists k, exists r, v = r + INR k * PI /\ (0 <= r <= PI).
  pose k := Z.to_nat (up (v / PI) - 1).
  exists k; exists (v - INR k * PI); split; try lra.
  rewrite INR_IZR_INZ Z2Nat.id.
    suff : (0 < up (v / PI))%Z by lia.
    apply: lt_0_IZR.
    suff : 0 <= v / PI by case: (archimed (v / PI)); lra.
    apply: Rmult_le_pos.
      apply: Rmult_le_pos; try lra.
      by apply: pos_INR.
    by apply/Rlt_le/Rinv_0_lt_compat; lra.
  rewrite minus_IZR. 
  rewrite {1 3}(_ : v = (v / PI) * PI); first by field; lra.
  case: (archimed (v / PI)); nra.
rewrite Rmult_plus_distr_l -Rmult_assoc -mult_INR [RHS]cos_add_INR.
rewrite Nat.even_mul orbC.
rewrite cos_add_INR.
have [kE|kO] := boolP (Nat.even k).
  by rewrite acos_left_inv.
rewrite /= acos_opp acos_left_inv //.
rewrite (_ : INR n * (PI - r) = - (INR n * r) + INR n * PI); try ring.
by rewrite cos_add_INR cos_neg.
Qed.