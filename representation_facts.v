(* This file provides an alternative formulation of represented spaces that saves
the input and output types of the names *)
From mathcomp Require Import all_ssreflect.
Require Import continuity universal_machine multi_valued_functions machines oracle_machines representations.
Require Import FunctionalExtensionality ClassicalFacts ClassicalChoice Psatz ProofIrrelevance.
Require Import Morphisms.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section COMPUTABILITY_LEMMAS.

Lemma prod_cmpt_elt (X Y: rep_space) (x: X) (y: Y):
	x \is_computable_element -> y \is_computable_element -> (x, y) \is_computable_element.
Proof.
move => [phi phinx] [psi psiny].
by exists (fun q => match q with
	| inl qx => (phi qx, some_answer Y)
	| inr qy => (some_answer X, psi qy)
end).
Qed.

Lemma cmpt_elt_mon_cmpt (X Y: rep_space) (f: X c-> Y):
	f \is_computable_element -> (projT1 f) \is_monotone_computable.
Proof. move => [psiF comp]; exists (U psiF); split => //; exact: U_mon. Qed.

Lemma cmpt_fun_mon_cmpt (X Y: rep_space) (f: X -> Y):
	f \is_computable_function -> (F2MF f) \is_monotone_computable.
Proof.
move => [M comp]; exists (fun n phi q => Some (M phi q)); split => //; rewrite /is_rlzr.
by apply/ tight_trans; [apply tight_comp_r; apply/ (prec_F2MF_op 0) | apply frlzr_rlzr].
Qed.

Lemma mon_cmpt_cmpt (X Y: rep_space) (f: X ->> Y):
	f \is_monotone_computable -> f \is_computable.
Proof. by move => [M [mon comp]]; exists M. Qed.

Lemma prim_rec_comp (X Y:rep_space) (f: X ->> Y):
	is_prim_rec f -> is_comp f.
Proof.
move => [N Nir]; exists (fun n phi q' => Some (N phi q')).
by apply/ tight_trans; first by apply/ tight_comp_r;	apply (prec_F2MF_op 0).
Qed.

Definition is_sprd (X: rep_space) := forall (x: X) (M: nat -> questions X -> option (answers X)),
	(exists phi, (meval M) \tightens (F2MF phi) /\ phi \is_name_of x) -> x \is_computable_element.
Notation "X '\is_spreaded'" := (is_sprd X) (at level 2).

Lemma fun_sprd (X Y: rep_space) (someq: questions X): (X c-> Y) \is_spreaded.
Proof.
move => f N prop.
pose M Lq := match N (length Lq.1) Lq with
	| Some t => t
	| None => inl someq
end.
exists M.
rewrite /delta/=/is_fun_name/=.
Admitted.

Lemma cmpt_fun_cmpt_elt (X Y: rep_space) (f: X ->> Y) (x: X) (y: Y):
	Y \is_spreaded -> f \is_monotone_computable -> f \is_single_valued
	-> x \is_computable_element -> f x y -> y \is_computable_element.
Proof.
move => sprd [M [mon comp]] sing [phi phinx] fxy.
have phifd: phi \from_dom (eval M).
	suffices phifd': (phi \from_dom (f o (delta (r:=X)))).
		by have [y' [[Mphi [MphiMphi asd]] prop]]:= (comp phi phifd').1; exists Mphi.
	exists y; split; first by exists x.
	move => x' phinx'; exists y.
	suffices: x = x' by move => <-.
	by apply/ (\rep_valid X).1; first by apply phinx.
have Mop: (eval M) \is_computable_operator by exists M.
have Msing: (eval M) \is_single_valued by apply/ mon_sing_op.
have [N Nprop]:= (cmpt_op_cmpt phifd Mop Msing).
have qfd: forall q, q \from_dom (fun (q' : questions Y) (a' : answers Y) =>
  exists Ff : names Y, (eval M) phi Ff /\ Ff q' = a').
	by move => q; have [Mphi MphiMphi]:= phifd; exists (Mphi q); exists Mphi.
have Ntot: (meval N) \is_total by move => q; have [qfdN prop] := Nprop q (qfd q).
apply/ (sprd y N).
have [psi psiprop]:= choice (meval N) Ntot.
have eq: forall Mphi, (eval M) phi Mphi -> Mphi = psi.
	move => Mphi MphiMphi.
	apply/ Msing; first by apply MphiMphi.
	move => q'.
	have [n eq]:= MphiMphi q'.
	exists n;	rewrite eq; congr Some.
	have Npsi: (meval N) q' (psi q') by apply psiprop.
	have [Mpsi [MphiMpsi eq']]:= (Nprop q' (qfd q')).2 (psi q') Npsi.
	suffices: Mphi = Mpsi by move => ->.
	by apply/ Msing.
exists psi.
split.
	move => q _.
	split; first by exists (psi q); apply psiprop.
	move => a evl.
	have [Mphi [MphiMphi val]]:= (Nprop q (qfd q)).2 a evl.
	by rewrite -(eq Mphi).
have [Mphi MphiMphi] := phifd.
rewrite -(eq Mphi) => //.
have phiny: (f o (delta (r:=X))) phi y.
	split; first by exists x.
	move => x' phinx'.
	exists y.
	suffices: x' = x by move => ->.
	by apply/ (\rep_valid X).1; first by apply phinx'.
have phifd': phi \from_dom (f o (delta (r:=X))) by exists y.
have [[fx [[Mpsi [MphiMpsi Mpsinfx]]] prop'] prop]:= comp phi phifd'.
have [fx' Mphinfx']:= prop' Mphi MphiMphi.
rewrite -(Msing phi Mphi Mpsi) in Mpsinfx => //.
have fdsing: (f o (\rep X)) \is_single_valued.
	apply/ comp_sing => //.
	by apply (\rep_valid X).
suffices: fx = y by move => <-.
apply/ fdsing; last by apply phiny.
apply/prop.
split; first by exists Mphi.
move => Mphi' MphiMphi'.
exists fx.
by rewrite (Msing phi Mphi' Mphi).
Qed.

Lemma id_prim_rec X:
	@is_prim_rec X X (F2MF id).
Proof. by exists id; apply frlzr_rlzr. Qed.

Lemma id_cmpt X:
	@is_comp X X (F2MF id).
Proof. exact: (prim_rec_comp (id_prim_rec X)). Qed.

Lemma id_hcr X:
	@has_cont_rlzr X X (F2MF id).
Proof.
exists (F2MF id).
split; first by apply frlzr_rlzr.
move => phi q' _.
exists [ ::q'].
move => Fphi /= eq psi coin Fpsi val.
rewrite -val -eq.
apply coin.1.
Qed.

Definition id_fun X :=
	(exist_fun (conj (conj (@F2MF_sing (space X) (space X) (@id X)) (F2MF_tot (@id X))) (id_hcr X))).

Lemma id_comp_elt X:
	(id_fun X) \is_computable_element.
Proof.
pose id_name p := match p.1: seq (questions X* answers X) with
		| nil => inl (p.2:questions X)
		| (q,a):: L => inr (a: answers X)
	end.
exists (id_name).
rewrite /delta /= /is_fun_name/=.
rewrite /is_rlzr id_comp.
rewrite -{1}(comp_id (\rep X)).
apply tight_comp_r.
apply/ (mon_cmpt_op); first exact: U_mon.
by move => phi q; exists 1.
Qed.

Definition fun_comp X Y Z (f: X c-> Y) (g: Y c-> Z) :(X c-> Z) :=
	exist_fun (conj
		(conj
			(comp_sing (projT2 g).1.1 (projT2 f).1.1)
			(comp_tot (projT2 f).1.2 (projT2 g).1.2)
		)
		(comp_hcr (projT2 f).2 (projT2 g).2)
		).

Definition composition X Y Z := F2MF (fun fg => @fun_comp X Y Z fg.1 fg.2).

Lemma fcmp_sing X Y Z:
	(@composition X Y Z) \is_single_valued.
Proof. exact: F2MF_sing. Qed.

Lemma fcmp_tot X Y Z:
	(@composition X Y Z) \is_total.
Proof. exact: F2MF_tot. Qed.

Lemma fcmp_mon_cmpt X Y Z:
	(@composition X Y Z) \is_monotone_computable.
Proof.
exists ( fun n psifg Lxqz => Some(inr (some_answer Z))).
split.
	admit.
move => psifg [gof [[[f g] [psifgnfg]]fggof] prop].
pose psif Lxqy := (psifg (inl Lxqy)).1.
pose psig Lyqz := (psifg (inr Lyqz)).2.
split.
	exists (fun_comp f g).
	split.
Admitted.

Lemma iso_ref X:
	X ~=~ X.
Proof.
exists (id_fun X); exists (id_fun X).
exists (id_comp_elt X); exists (id_comp_elt X).
by split; rewrite comp_id.
Qed.

Lemma iso_sym X Y:
	X ~=~ Y -> Y ~=~ X.
Proof.
move => [f [g [fcomp [gcomp [bij1 bij2]]]]].
exists g; exists f.
by exists gcomp; exists fcomp.
Qed.

Lemma iso_trans X Y Z (someqx: questions X) (someqz: questions Z):
	X ~=~ Y -> Y ~=~ Z -> X ~=~ Z.
Proof.
move => [f [g [fcomp [gcomp [bij1 bij2]]]]] [f' [g' [f'comp [g'comp [bij1' bij2']]]]].
exists (fun_comp f f').
exists (fun_comp g' g).
split.
	apply/ cmpt_fun_cmpt_elt; [apply: fun_sprd someqx | apply fcmp_mon_cmpt | apply fcmp_sing | | ].
		by apply prod_cmpt_elt; [apply fcomp | apply f'comp].
	by trivial.
split.
	by apply: (@cmpt_fun_cmpt_elt
		(rep_space_prod (Z c-> Y) (Y c-> X)) (Z c-> X)
		(@composition Z Y X)
		(g', g)
		(fun_comp g' g)
		(fun_sprd someqz)
		(fcmp_mon_cmpt Z Y X)
		(@fcmp_sing Z Y X)
		(prod_cmpt_elt g'comp gcomp)
		_
		).
rewrite /fun_comp/=.
split.
	rewrite -comp_assoc (comp_assoc (sval f') (sval f) (sval g)).
	by rewrite bij1 comp_id bij1'.
rewrite -comp_assoc (comp_assoc (sval g) (sval g') (sval f')).
by rewrite bij2' comp_id bij2.
Qed.

Definition evaluation X Y (fx: (X c-> Y) * X):= (projT1 fx.1) fx.2.

Lemma eval_sing X Y:
	(@evaluation X Y) \is_single_valued.
Proof.
move => [f x] y z fxy fxz.
have sing:= (projT2 f).1.1.
apply/ sing; [apply fxy| apply fxz].
Qed.

Lemma eval_tot X Y:
	(@evaluation X Y) \is_total.
Proof.
move => [f x].
have [y fxy]:= ((projT2 f).1.2 x).
by exists y.
Qed.

Lemma eval_hcr X Y:
	(@evaluation X Y) \has_continuous_realizer.
Proof.
pose M n (psi: _ -> (_ + answers Y) *_) (q: questions Y) :=
	U (fun L: seq (questions X * _) * _ => (psi (inl L)).1) n (fun q => (psi (inr q)).2:answers X) q.
exists (eval M).
split.
	move => psi [y [[[f x] [psinfx val]]] prop].
	split.
		exists y.
		split.
			rewrite /rel_comp.
			have [phi phiny]:= \rep_sur Y y.
			exists phi.
			split => //.
Admitted.

End COMPUTABILITY_LEMMAS.