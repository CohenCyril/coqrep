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

Lemma diag_cmpt (X: rep_space):
	(fun x => (x, x): rep_space_prod X X) \is_prec_function.
Proof.
by exists (fun phi q => match q with
	| inl q => (phi q, some_answer X)
	| inr q => (some_answer X, phi q)
end).
Defined.

Lemma prec_fun_cmpt_elt (X Y: rep_space) (f: X -> Y) (x: X):
	x \is_computable_element -> f \is_prec_function -> (f x) \is_computable_element.
Proof.
move => [phi phinx] [M Mrf].
by exists (M phi); apply Mrf.
Defined.

Lemma cnst_fun_prec (X Y: rep_space) (y: Y):
	y \is_computable_element -> (fun x:X => y) \is_prec_function.
Proof. by move => [psi psiny]; exists (fun _ => psi). Qed.

Lemma prod_prec_fun (X Y X' Y': rep_space) (f: X -> Y) (g: X' -> Y'):
	f \is_prec_function -> g \is_prec_function -> (fun p => (f p.1, g p.2)) \is_prec_function.
Proof.
move => [M Mrf] [N Nrg].
exists (fun np q => match q with
	| inl q => (M (fun q' => (np (inl q')).1) q, some_answer Y')
	| inr q => (some_answer Y, N (fun q' => (np (inr q')).2) q)
end).
by move => phipsi [x x'] [phinx psinx']; split; [apply Mrf | apply Nrg].
Defined.

Lemma cmpt_elt_mon_cmpt (X Y: rep_space) (f: X c-> Y):
	f \is_computable_element -> (projT1 f) \is_monotone_computable.
Proof. move => [psiF comp]; exists (U psiF); split => //; exact: U_mon. Qed.

Lemma prec_cmpt_fun_cmpt (X Y: rep_space) (f: X -> Y):
	f \is_prec_function -> f \is_computable_function.
Proof.
move => [M comp].
exists (fun n phi q' => Some (M phi q')).
rewrite /is_rlzr.
apply/ tight_trans; last by apply /frlzr_rlzr; apply comp.
by apply tight_comp_r; apply/ (prec_F2MF_op 0).
Qed.

Lemma mon_cmpt_cmpt (X Y: rep_space) (f: X ->> Y):
	f \is_monotone_computable -> f \is_computable.
Proof. by move => [M [mon comp]]; exists M. Qed.

Lemma prec_fun_comp (X Y Z: rep_space) (f: X -> Y) (g: Y -> Z):
	f \is_prec_function -> g \is_prec_function
	-> forall h, (forall x, h x = g (f x)) -> h \is_prec_function.
Proof.
move => [M comp] [N comp'] h eq.
exists (fun phi => N (M phi)).
by move => phi x phinx; rewrite eq; apply comp'; apply comp.
Defined.

Lemma prec_fun_cmpt (X Y: rep_space) (f: X -> Y):
	f \is_prec_function -> f \is_computable_function.
Proof.
move => [N Nir]; exists (fun n phi q' => Some (N phi q')).
apply/ tight_trans; last by apply frlzr_rlzr; apply Nir.
apply tight_comp_r; apply: prec_F2MF_op 0.
Qed.

Lemma prec_cmpt (X Y:rep_space) (f: X ->> Y):
	is_prim_rec f -> is_comp f.
Proof.
move => [N Nir]; exists (fun n phi q' => Some (N phi q')).
by apply/ tight_trans; first by apply/ tight_comp_r;	apply (prec_F2MF_op 0).
Qed.

Definition is_sprd (X: rep_space) := forall (x: X) (M: nat -> questions X -> option (answers X)),
	(exists phi, (meval M) \tightens (F2MF phi) /\ phi \is_name_of x) -> x \is_computable_element.
Notation "X '\is_spreaded'" := (is_sprd X) (at level 2).

Lemma prod_sprd (X Y: rep_space):
	X \is_spreaded -> Y \is_spreaded -> (rep_space_prod X Y) \is_spreaded.
Proof.
move => sprdx sprdy [x y] MN prop.
pose M n q := match MN n (inl q) with
	| some a => Some a.1
	| None => None
end.
pose N n q := match MN n (inr q) with
	| Some a => Some a.2
	| None => None
end.
have ex: exists phi, (meval M) \tightens (F2MF phi) /\ phi \is_name_of x.
	have [phipsi [comp [/=phinx psiny]]]:= prop.
	exists (lprj phipsi).
	split; last by apply phinx.
	move => q _.
	have qfd': (inl q) \from_dom (F2MF phipsi) by exists (phipsi (inl q)).
	split.
		have [a [n MNqa]]:= (comp (inl q) qfd').1.
		by exists a.1; exists n; rewrite /M MNqa.
	move => a [n Mqa]; rewrite /F2MF/lprj.
	rewrite /M in Mqa.
	have [a' [MNqa' eq]]: exists a', MN n (inl q) = some a' /\ a'.1 = a.
		by case: (MN n (inl q)) Mqa => // a' eq; exists a'; split => //; apply Some_inj.
	have val: (meval MN (inl q) a') by exists n.
	have:= ((comp (inl q) qfd').2 a' val).
	by rewrite /F2MF -eq => ->.
have:= sprdx x M ex.
have ex': exists psi, (meval N) \tightens (F2MF psi) /\ psi \is_name_of y.
	have [phipsi [comp [/=phinx psiny]]]:= prop.
	exists (rprj phipsi).
	split; last by apply psiny.
	move => q _.
	have qfd': (inr q) \from_dom (F2MF phipsi) by exists (phipsi (inr q)).
	split.
		have [a [n MNqa]]:= (comp (inr q) qfd').1.
		by exists a.2; exists n; rewrite /N MNqa.
	move => a [n Mqa]; rewrite /F2MF/rprj.
	rewrite /N in Mqa.
	have [a' [MNqa' eq]]: exists a', MN n (inr q) = some a' /\ a'.2 = a.
		by case: (MN n (inr q)) Mqa => // a' eq; exists a'; split => //; apply Some_inj.
	have val: (meval MN (inr q) a') by exists n.
	have:= ((comp (inr q) qfd').2 a' val).
	by rewrite /F2MF -eq => ->.
have:= sprdy y N ex'.
move => [psi psiny] [phi phinx].
by exists (name_pair phi psi).
Qed.

(*
Lemma fun_sprd (X Y: rep_space) (someq: questions X): (X c-> Y) \is_spreaded.
Proof.
Admitted.
*)

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
	by apply/ (rep_sing X); first by apply phinx.
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
	by apply/ (rep_sing X); first by apply phinx'.
have phifd': phi \from_dom (f o (delta (r:=X))) by exists y.
have [[fx [[Mpsi [MphiMpsi Mpsinfx]]] prop'] prop]:= comp phi phifd'.
have [fx' Mphinfx']:= prop' Mphi MphiMphi.
rewrite -(Msing phi Mphi Mpsi) in Mpsinfx => //.
have fdsing: (f o (\rep X)) \is_single_valued.
	apply/ comp_sing => //.
	by apply (rep_sing X).
suffices: fx = y by move => <-.
apply/ fdsing; last by apply phiny.
apply/prop.
split; first by exists Mphi.
move => Mphi' MphiMphi'.
exists fx.
by rewrite (Msing phi Mphi' Mphi).
Qed.

Lemma id_prec X:
	@is_prim_rec X X (F2MF id).
Proof. by exists id; apply frlzr_rlzr. Defined.

Lemma id_prec_fun X:
	(@id (space X)) \is_prec_function.
Proof. by exists id. Defined.

Lemma id_cmpt X:
	@is_comp X X (F2MF id).
Proof. exact: (prec_cmpt (id_prec X)). Qed.

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

(*
Lemma fcmp_mon_cmpt X Y Z:
	(@composition X Y Z) \is_monotone_computable.
Proof.
pose p1 psifg Lxqy:= (psifg (inl Lxqy)).1.
pose p2 psifg Lyqz:= (psifg (inr Lyqz)).2.
Admitted.
*)

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

(*
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
*)

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

(*
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
			have [phi phiny]:= rep_sur Y y.
			exists phi.
			split => //.
Admitted.
*)

End COMPUTABILITY_LEMMAS.