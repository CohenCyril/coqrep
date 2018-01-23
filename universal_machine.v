(* This file is supposed to contain the definition of a universal machine and the proof
that the machine is actually universal. The universal machine is a machine of type two
and it should work for any continuous function from B -> B. Usually B is the Baire space,
here, i.e. the set of all mappings from strings to strings. However, since I don't want
to rely on a handwritten type of strings as I attempted in the file "operators.v" I use
more generaly a space S -> T as substitute for B. *)
From mathcomp Require Import all_ssreflect.
Require Import multi_valued_functions continuity initial_segments.
Require Import ClassicalChoice Psatz.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section UNIVERSAL_MACHINE.

Context (Q I Q' I' : Type).
Notation A := (option I).
Notation A' := (option I').
Notation B := (Q -> A).
Notation B' := (Q' -> A').

Definition U_step (psi: list(Q * A) * Q' -> Q + A') phi q' L :=
match psi (L, q') with
  | inr a' => inl a'
  | inl q => inr (cons (q, phi q) L)
end.

Fixpoint U_rec
n (psi: list(Q * A) * Q' -> Q + A') phi q' :=
match n with
	|	0 => match U_step psi phi q' nil with
		| inl a' => inl a'
		| inr L => inr L
	end
	|	S n' => match (U_rec n' psi phi q') with
		| inl a' => inl a'
		| inr L => U_step psi phi q' L
	end
end.

(* This is what I want to prove to be a universal machine: *)
Definition U
	(n: nat)
	(psi: list (Q * A) * Q' -> Q + A')
	(phi: Q -> A)
	(q' : Q') :=
match (U_rec n psi phi q') with
	| inl a' => a'
	| inr L => None
end.

Notation L2MF L := (fun q a => List.In (q, a) L).

Section FLST.
Context (phi: B).
Definition flst L:= (zip L (map phi L)).

Lemma flst_cons_elts qa L:
	List.In qa (flst L) -> phi (qa.1) = qa.2.
Proof.
move: L; elim => // q L ih ass.
case: ass => //; rewrite (surjective_pairing qa).
by case => eq1 eq2 /=; rewrite -eq1.
Qed.

Lemma list_in_to_flst_in q L:
	(List.In q L -> List.In (q, phi q) (flst L)).
Proof.
move: L; elim => // q' L ih ass.
case: ass => H.
	by left; rewrite H.
by move; right; apply: ih.
Qed.

Lemma flst_in_to_list_in qa L:
	List.In qa (flst L) -> List.In qa.1 L.
Proof.
move: L; elim => // a L ih [].
	by rewrite (surjective_pairing qa); case => eq _; left.
by move => stuff; right; apply: ih.
Qed.

Lemma icf_flst L:
	phi is_choice_for (L2MF (flst L)).
Proof.
move => q [] a listin.
split.
	exists a; apply: (flst_cons_elts listin).
move => a' phiqa'.
by rewrite -phiqa'; apply: (list_in_to_flst_in (flst_in_to_list_in listin)).
Qed.

Lemma coin_icf_flst psi L:
	psi is_choice_for (L2MF (flst L))
	<->
	psi and phi coincide_on L.
Proof.
move: L; elim.
	by split => // _ /= q [] a false; exfalso.
move => q L.
split.
	move: H => [] ih _ icf.
	split.
		case: (icf q).
			by exists (phi q); apply: (list_in_to_flst_in); left.
		move => [] a psiqa prop.
		move: (flst_cons_elts (prop a psiqa)) => /= phiqa.
		by rewrite psiqa -phiqa.
	apply ih => q' [] a inlist.
	move: (flst_cons_elts inlist) => /= eq.
	split.
		exists a; case: (icf q') => /=.
			by exists a; right.
		move => [] a' psiq'a' prop.
		case: (prop a' psiq'a').
			move: prop => _ [] eq1 eq2.
			by rewrite -eq -{2}eq1 eq2.
		move: prop => _ listin.
		move: (flst_cons_elts listin) => /= eq'.
		by rewrite -eq eq'.
	move: (flst_in_to_list_in inlist) => /= listin a' psiq'a'.
	case: (icf q').
		by exists a; right.
	move => _ prop.
	case: (prop a' psiq'a').
		move => [] eq1 eq2.
		by rewrite -eq2 eq1; apply: list_in_to_flst_in.
	by move => stuff.
move => coin q' [] a inlist.
split.
	by exists (psi q').
move: coin.1 => eq a' psiq'a'.
rewrite -psiq'a'.
case: (flst_in_to_list_in inlist) => /=.
	move => eq'.
	by left; rewrite -eq' eq.
move => listin;right.
have: List.In q' (q::L) by right.
move => listin2.
move: ((coin_and_list_in psi phi (q::L)).1 coin q' listin2) => eq'.
by rewrite eq'; apply: (list_in_to_flst_in).
Qed.

Lemma icf_flst_coin psi L:
	psi is_choice_for (L2MF(flst L)) <-> psi and phi coincide_on L.
Proof.
exact: coin_icf_flst.
Qed.

Lemma length_flst_in_seg cnt n:
	length (flst (in_seg cnt n)) = n.
Proof.
by move: n; elim => // n ih; rewrite -{2}ih.
Qed.
End FLST.

Section MINIMAL_MODULI.
Context (cnt: nat -> Q) (sec: Q -> nat) (F: B ->> B').
Notation init_seg := (in_seg cnt).
Notation size := (size sec).

Definition is_min_mod mf :=
	mf is_modulus_of F /\ forall phi q' K, (forall psi, phi and psi coincide_on K
    -> forall Fphi, F phi Fphi -> forall Fpsi, F psi Fpsi -> Fphi q' = Fpsi q') ->
     exists m, m <= size K /\ mf phi q'= init_seg m.

Lemma minimal_mod_function:
  F is_continuous -> sec is_minimal_section_of cnt ->
  exists mf, is_min_mod mf.
Proof.
  move => cont [] issec ismin.
  set P := fun phiq L => forall psi, phiq.1 and psi coincide_on L
    -> forall Fphi, F phiq.1 Fphi -> forall Fpsi, F psi Fpsi -> Fphi phiq.2 = Fpsi phiq.2.
  set R := fun phiq L => P phiq L /\
  	(forall K, P phiq K ->  exists m, m <= size K /\ L = init_seg m).
  have cond: forall phiq, exists L, R phiq L.
    move => phiq.
  	have cond : exists n, exists L, P phiq L /\ size L = n.
  		move: (cont phiq.1 phiq.2) => [L] Lprop.
  		exists (size L).
  		by exists L.
  	move: (@well_order_nat (fun n => exists L, P phiq L
  		/\ size L = n) cond) => [n] [ [L] [Lprop Leqn]] nprop.
  	exists (in_seg cnt (size L)).
  	split.
      move => psi coin.
      move: coin (list_size issec coin) => _ coin.
  		by apply: Lprop.
  	rewrite -Leqn in nprop.
  	move => K Pfi.
		exists (size L).
    split => //.
    have e : exists L : seq Q, P phiq L /\ size L = (size K) by exists K.
    by apply: (nprop (size K) e).
 	move: (@choice ((Q -> A)*Q') (list Q) R cond) => [mf] mfprop.
 	rewrite /R in mfprop.
 	move: R cond => _ _.
 	exists (fun phi q' => mf (phi, q')).
 	split.
 		move => phi q' psi.
 		apply (mfprop (phi, q')).
 	move => phi q' K mod.
 	move: (mfprop (phi,q')) => [_ b].
 	apply: (b K).
 	move => psi coin Fphi FphiFphi Fpsi FpsiFpsi.
 	apply: (mod psi) =>//.
Qed.
End MINIMAL_MODULI.

(*This should at some point go into an appropriate section: *)
Lemma extend_list:
	exists listf, forall (L: list (Q * A)), (listf L) is_choice_for (L2MF L).
Proof.
set R := (fun (L : Q * list(Q * A)) (a: A) =>
	forall b, (L2MF L.2) L.1 b -> (L2MF L.2) L.1 a).
have : forall L, exists b, R L b.
	move => [q L].
	case: (classic (exists a, List.In (q,a) L)).
		move => [a] inlist.
		by exists a.
	move => false.
	exists None.
	move => a inlist.
	exfalso; apply: false.
	by exists a.
move => cond.
move: ((@choice (Q*list(Q * A)) A R) cond) => [listf] listfprop.
exists (fun L => (fun q => listf (q,L))).
move => L q e.
split.
	by exists (listf (q,L)).
rewrite /F2MF.
move: e => [] a inlist b v.
move: (listfprop (q, L) a inlist) => /= asdf.
by rewrite v in asdf.
Qed.

Context (cnt : nat -> Q).
Notation init_seg := (in_seg cnt).

Lemma length_in_seg n:
	length (init_seg n) = n.
Proof.
by move: n; elim => // n ih; rewrite -{2}ih.
Qed.

Context (F: B ->> B').

Lemma listsf:
		exists phi',
		forall L: list (Q*A), ((exists phi, phi from_dom F /\ phi is_choice_for (L2MF L)) ->
			(phi' L) from_dom F) /\ (phi' L) is_choice_for (L2MF L).
Proof.
move: extend_list => [] listf listfprop.
set R := (fun L (psi: B) =>
	((exists phi, phi from_dom F /\ phi is_choice_for (L2MF L)) -> psi from_dom F)
	/\ psi is_choice_for (L2MF L)).
have : forall L, exists psi, R L psi.
	move => L.
  case: (classic (exists phi, phi from_dom F /\ phi is_choice_for (L2MF L))).
  	move => [psi] [] psifd psic.
    by exists psi.
  move => false.
  exists (listf L).
  by split => //.
move => cond.
move: ((@choice (list(Q * A)) (Q -> A) R) cond) => [phi'] phi'prop.
by exists phi'.
Qed.

Context (sec: Q -> nat) (isminsec: is_min_sec cnt sec).
Notation size := (size sec).

Lemma min_mod_in_seg mf:
	is_min_mod cnt sec F mf ->
	forall phi q', in_seg cnt (size (mf phi q')) = mf phi q'.
Proof.
move => mprop phi q'.
move: (mprop.2 phi q' (mf phi q') (mprop.1 phi q')) => [] m [] ineq eq'.
move: (size_in_seg isminsec m) => ineq'.
rewrite -eq' in ineq'.
rewrite -/size in ineq ineq'.
have eq'': (size (mf phi q')) = m by lia.
by rewrite eq'' eq'.
Qed.

Definition is_count Q :=
	exists cnt: nat -> Q, (F2MF cnt) is_surjective.
Notation "T 'is_countable'" := (is_count T) (at level 2).

Context (sur: (F2MF cnt) is_surjective).

Notation "B ~> B'" := (nat -> B -> B') (at level 2).

Definition F_computed_by (M: B ~> B'):=
  (forall phi Fphi, F phi Fphi -> forall q', exists n, M n phi q' = Fphi q')
    /\
  (forall phi n q' a', phi from_dom F -> M n phi q' = Some a' ->
  	exists Fphi, F phi Fphi /\ Fphi q' = Some a').

Lemma U_is_universal:
	F is_continuous -> exists psiF, F_computed_by (fun n phi q' => U n psiF phi q').
Proof.
move => Fcont.
set R := fun phi psi => ((exists psi', F phi psi') -> F phi psi).
have cond: forall phi, exists psi, R phi psi.
  move => phi.
  case: (classic (exists psi' , F phi psi')).
    move => [psi prop].
    by exists psi.
  move => false.
  by exists (fun a => None).
move: ((@choice ((Q -> A)) (Q' -> A') R) cond) => [Ff] Fprop.
rewrite /R /= in Fprop; move: R cond => _ _.

move: (minimal_mod_function Fcont isminsec) => [] mf mprop.
move: listsf => [] phi' phi'prop.

have coin:
	forall phi q', (phi' (flst phi (mf phi q'))) and phi coincide_on (mf phi q').
	move => phi q'.
	apply/ icf_flst_coin.
	by apply: (phi'prop (flst phi (mf phi q'))).2.

have mon_in_seg:
	forall q n m, n <= m -> List.In q (init_seg n) -> List.In q (init_seg m).
	move => q n.
	elim.
		move => l0.
		have eq: (n = 0) by lia.
		by rewrite eq.
	move => m ih ass.
	case: ((PeanoNat.Nat.le_succ_r n m).1 ass).
		move => ineq listin.
		replace (init_seg m.+1) with ((cnt m):: init_seg m) by trivial.
		by right; apply ih.
	move => eq listin.
	by rewrite -eq.

have ineq: forall phi q' n, phi from_dom F -> size (mf phi q') <= n ->
	size (mf (phi' (flst phi (init_seg n))) q') <= size (mf phi q').
	move => phi q' n [] Fphi FphiFphi ass.
	set K := mf (phi' (flst phi (init_seg n))) q'.
	have coin'': (phi' (flst phi (init_seg n))) and phi coincide_on (mf phi q').
		move: ((coin_icf_flst phi (phi' (flst phi (init_seg n))) (init_seg n)).1
			(phi'prop (flst phi (init_seg n))).2) => coin''.
		move: ((coin_and_list_in (phi' (flst phi (init_seg n))) phi (init_seg n)).1 coin'') => elts.
		apply/ coin_and_list_in.
		move => q listin.
		apply elts.
		rewrite -(min_mod_in_seg mprop phi q') in listin.
		by apply: (mon_in_seg q (size (mf phi q')) n).
	have coin''':
		(phi' (flst phi (init_seg n))) and (phi' (flst phi (mf phi q'))) coincide_on (mf phi q').
		apply/ coin_trans.
			by apply coin''.
		move: ((coin_icf_flst phi (phi' (flst phi (mf phi q'))) (mf phi q')).1
			(phi'prop (flst phi (mf phi q'))).2) => coin'''.
		by apply/ coin_sym.
	suffices: exists m : nat, m <= size (mf phi q') /\ K = in_seg cnt m.
		move => [] m [] leq eq.
		rewrite eq.
		move: (size_in_seg isminsec m) => ineq.
		by lia.
	apply: (mprop.2 (phi' (flst phi (init_seg n))) q' (mf phi q'))
		=> psi coin' FphiL FphiLFphiL Fpsi FpsiFpsi.
	replace (FphiL q') with (Fphi q').
	apply: (mprop.1 phi q' psi) => //.
		apply/ (coin_trans).
			apply/ coin_sym.
			by apply: coin.
		apply/ coin_trans.
			apply/ coin_sym.
			by apply: coin'''.
		done.
	apply/ (mprop.1 phi) => //.
		apply/ coin_sym.
		by apply coin''.
	done.

set psiF := (fun L =>
  if
    (leq (size (mf (phi' L.1) L.2)) (length L.1))
  then
    (inr (Ff (phi' L.1) L.2))
  else
    (inl (cnt (length L.1)))).

have length_size: forall phi q', size (mf phi q') = length (mf phi q').
	move => phi q'.
	rewrite -{2}(min_mod_in_seg mprop phi q').
	by rewrite length_in_seg.

have U_step_prop:
	forall phi q' n, phi from_dom F -> size (mf phi q') <= n ->
	U_step psiF phi q' (flst phi (init_seg n)) = inl(Ff (phi' (flst phi (init_seg n))) q').
	move => phi q' n phifd ass.
	rewrite /U_step/psiF/=.
	rewrite (length_flst_in_seg phi cnt n).
	move: (size_in_seg isminsec n) => tada.
	move: (ineq phi q' n phifd ass) => toeroe.
	case_eq (size (mf (phi' (flst phi (init_seg n))) q') <= n)%N => intros //.
	exfalso.
	have: (size (mf (phi' (flst phi (init_seg n))) q') <= n)%N by apply /leP; lia.
	by rewrite intros.
	
have Ffprop:
	forall n phi q', phi from_dom F -> size (mf (phi' (flst phi (init_seg n))) q') <= n ->
			Ff (phi' (flst phi (init_seg n))) q' = Ff phi q'.
	move => n phi q' phifd leq.
	set m := size (mf (phi' (flst phi (init_seg n))) q').
	move: (min_mod_in_seg mprop (phi' (flst phi (init_seg n))) q') => eq.
	rewrite -/m in leq eq.
	apply: (mprop.1 (phi' (flst phi (init_seg n))) q' phi).
			rewrite -eq.
			apply/ coin_and_list_in.
			move: ((icf_flst_coin phi (phi' (flst phi (init_seg n))) (init_seg n)).1
				(phi'prop (flst phi (init_seg n))).2) => coin'.
			move: ((coin_and_list_in (phi' (flst phi (init_seg n))) phi (init_seg n)).1
				coin') => cond q listin.
			apply: cond.
			by apply: (mon_in_seg q m n).
		apply Fprop.
		apply: (phi'prop (flst phi (init_seg n))).1.
		exists phi.
		split => //.
		apply/ (icf_flst_coin).
		by apply coin_ref.
	by apply Fprop.

have U_rec_prop:
	forall n phi q', phi from_dom F ->
		U_rec n psiF phi q' = inl(Ff phi q')
		\/
		U_rec n psiF phi q' = inr(flst phi (init_seg (S n))).
	elim.
		move => phi q' phifd.
		rewrite /U_rec /U_step /psiF /=.
		case_eq  (size (mf (phi' [::]) q') <= 0)%N => intros.
			left.
			replace (Ff (phi' nil) q') with (Ff phi q') => //.
			replace (Ff phi q') with (Ff (phi' nil) q') => //.
			apply/ (mprop.1).
					move: ((icf_flst_coin phi (phi' nil) (nil)).1 (phi'prop (flst phi nil)).2).
					have t: size (mf (phi' nil) q') <= 0
						by apply /leP; rewrite intros.
					have eq: size (mf (phi' nil) q') = 0 by lia.
					have isnil: mf (phi' nil) q' = nil.
						suffices:
							exists m : nat, m <= size (mf (phi' nil) q')
								/\ mf (phi' [::]) q' = init_seg m.
							move => /= [] m [] leq eq'.
							have m0 : m=0 by lia.
							by rewrite eq' m0.
						apply: (mprop.2 (phi' nil) q' (mf (phi' nil) q')).
						by apply: (mprop.1 (phi' nil) q').
					rewrite -isnil => equal.
					by apply: equal.
				apply: Fprop.
				apply: (phi'prop (nil: list (Q * A))).1.
				exists phi.
				split => //.
				move => q [] a false.
				exfalso.
				by apply false.
			by apply: Fprop.
		by right; trivial.
	move => n ih phi q' phifd /=.
	move: ih (ih phi q' phifd) => _ ih.
	case: ih => eq; rewrite eq /=.
		by left.
	rewrite /U_step/psiF.
	rewrite (length_flst_in_seg phi cnt (S n)) /=.
	case_eq (size (mf (phi' (flst phi (cnt n :: init_seg n))) q') <= n.+1)%N => intros.
		left.
		have leq: size (mf (phi' (flst phi (cnt n :: init_seg n))) q') <= n.+1 by apply /leP.
		by rewrite (Ffprop (S n) phi q' phifd leq).
 	by right.

have U_rec_prop':
	forall n phi q', phi from_dom F -> size (mf phi q') <= n ->
		U_rec n psiF phi q' = inl(Ff phi q').
	elim => //.
		move => phi q' phifd leq /=.
		rewrite (U_step_prop phi q' 0 phifd leq).
		have eq: size (mf phi q') = 0 by lia.
		move: (ineq phi q' 0 phifd leq) => leq'.
		rewrite eq in leq'.
		by rewrite (Ffprop 0 phi q' phifd leq').
	move => n ih phi q' phifd leq /=.
	case: (U_rec_prop n phi q' phifd).
		by move => eq; rewrite eq /=.
	move => eq; rewrite eq /=.
	rewrite (U_step_prop phi q' (S n) phifd leq).
	move: (ineq phi q' (S n) phifd leq) => leq'.
	have leq'':size (mf (phi' (flst phi (init_seg n.+1))) q') <= S n by lia.
	by rewrite (Ffprop (S n) phi q' phifd leq'').

exists psiF.
split.
	move => phi Fphi FphiFphi q'.
	exists (size (mf phi q')).
	rewrite /U.
	rewrite (U_rec_prop' (size (mf phi q')) phi q')=>//;last first.
		by exists Fphi.
	apply/ (mprop.1); last first.
			by apply/ FphiFphi.
		apply Fprop.
		by exists Fphi.
	by apply/ (coin_ref phi).
move => phi n q' a' []Fphi FphiFphi eq.
	exists Fphi; split => //.
	have phifd: phi from_dom F by exists Fphi.
	case: (U_rec_prop n phi q' phifd) => case_eq.
		rewrite -eq /U case_eq /=.
		replace Fphi with (Ff phi) => //.
		rewrite ((cont_to_sing Fcont).1 phi Fphi (Ff phi)) => //.
		apply/ Fprop.
		by exists Fphi.
	rewrite -eq /U case_eq /=.
	rewrite /U in eq.
	rewrite case_eq /= in eq.
	by exfalso.
Qed.
End UNIVERSAL_MACHINE.
Notation "T 'is_countable'" := (is_count T) (at level 2).