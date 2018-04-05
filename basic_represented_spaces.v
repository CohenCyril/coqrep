(* This file provides an alternative formulation of represented spaces that saves
the input and output types of the names *)
From mathcomp Require Import all_ssreflect.
Require Import all_core rs_base representation_facts.
Require Import FunctionalExtensionality ClassicalChoice.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section BASIC_REP_SPACES.
Inductive one := star.

Definition id_rep S := (fun phi (s: S) => phi star = s).

Lemma id_rep_is_rep:
	forall S: Type, (@id_rep S) \is_representation.
Proof.
by split => [ phi s s' eq eq' | s ]; [rewrite -eq -eq' | exists (fun str => s)].
Qed.

Lemma one_count:
	one \is_countable.
Proof. by exists (fun n => star); move => star; exists 0%nat; elim star. Qed.

Canonical rep_space_one := @make_rep_space
	one
	one
	one
	(@id_rep one)
	star
	one_count
	one_count
	(@id_rep_is_rep one).

Lemma nat_count:
	nat \is_countable.
Proof. exists (fun n:nat => n); move => n; by exists n. Qed.

Canonical rep_space_nat := @make_rep_space
	nat
	one
	nat
	(@id_rep nat)
	1%nat
	one_count
	nat_count
	(id_rep_is_rep nat).

Inductive Sirp := top | bot.

Definition rep_S phi s :=
	(exists n:nat, phi n = Some star) <-> s = top.

Lemma rep_S_is_rep:
 rep_S \is_representation.
Proof.
split => [ phi s s' [imp imp'] [pmi pmi'] | s].
	case (classic (exists n, phi n = Some star)) => ex; first by rewrite (imp ex) (pmi ex).
	case E: s; first by exfalso; apply ex; apply (imp' E).
	apply NNPP => neq.
	have eq: s' = top by case Q: s' => //; exfalso; apply neq.
	by apply ex; apply pmi'.
case s; last by exists (fun _ => None); split => // [[n ev]].
by exists (fun _ => some star); split => // _; by exists 0.
Qed.

Lemma option_one_count:
	(option one) \is_countable.
Proof.
by exists (fix c n := match n with
	| 0 => Some star
	| S n' => None
end) => s; case: s; [exists 0; elim: a| exists 1].
Qed.

Canonical rep_space_S := @make_rep_space
	(Sirp)
	(nat)
	(option one)
	(rep_S)
	(None)
  (nat_count)
  (option_one_count)
  (rep_S_is_rep).
End BASIC_REP_SPACES.

Section BASIC_CONSTRUCTIONS.
Definition rep_usig_prod (X: rep_space) phi (xn: nat -> X):=
	forall n, (fun p => (phi (n,p))) \is_name_of (xn n).

Lemma rep_usig_prod_is_rep (X: rep_space):
	(@rep_usig_prod X) \is_representation.
Proof.
split => [ phi xn yn phinxn phinyn | xn ].
	apply functional_extensionality => n.
	by apply/ (rep_sing X); [apply phinxn | apply phinyn ].
pose R n phi:= phi \is_name_of (xn n).
have Rtot: R \is_total.
	by move => n; have [phi phinx]:= (rep_sur X (xn n)); exists phi.
by have [phi phinxn]:= choice R Rtot; exists (fun p => phi p.1 p.2).
Qed.

Canonical rep_space_usig_prod (X: rep_space) := @make_rep_space
	(nat -> space X)
	(nat * questions X)
	(answers X)
	(@rep_usig_prod X)
	(some_answer X)
  (prod_count nat_count (countable_questions X))
  (countable_answers X)
  (@rep_usig_prod_is_rep X).

Lemma usig_base X (an: nat -> space X) phi:
	phi \is_name_of an -> forall n, (fun q => phi (n,q)) \is_name_of (an n).
Proof. done. Qed.

Definition rep_opt X phi x := match x with
	| some x => (phi (inl star)).1 = some star
		/\
		 @delta X (fun q => (phi (inr q)).2) x
	| None => (phi (inl star)).1 = None
end.

Lemma rep_opt_sing X:
	(@rep_opt X) \is_single_valued.
Proof.
move => phi x y phinx phiny.
case: x phinx.
	case: y phiny; last by move => /= Nope a [eq phina]; rewrite eq in Nope.
	move => a/= [eq phina] b [eq' phinb].
	by rewrite (rep_sing X (fun q => (phi (inr q)).2) a b).
case: y phiny => //.
move => /= a [eq phina] Nope.
by rewrite eq in Nope.
Qed.

Lemma rep_opt_rep X:
	(@rep_opt X) \is_representation.
Proof.
split; first exact: rep_opt_sing.
move => x.
case x => [a | ].
	have [phi phinx]:= (rep_sur X a).
	by exists (fun q => (Some star, if q is inr q' then phi q' else some_answer X)).
by exists (fun q => (None, some_answer X)).
Qed.

Lemma option_count T:
	T \is_countable -> (option T) \is_countable.
Proof.
move => [cnt sur].
exists (fun n => match n with
	| 0 => None
	| S n' => Some (cnt n')
end).
move => x.
case x; last by exists 0.
move => a.
have [n cntna]:= sur a.
by exists (S n); rewrite cntna.
Qed.

Canonical rep_space_opt (X: rep_space) := @make_rep_space
	(option X)
	(one + questions X)
	(option one * answers X)
	(@rep_opt X)
	((None, some_answer X))
	(sum_count one_count (countable_questions X))
	(prod_count (option_count one_count) (countable_answers X))
	(@rep_opt_rep X).

Notation unsm phi:= (fun q => (phi (inr q)).2).

Lemma unsm_prec (X: rep_space):
	(fun ox (x: X) => ox = some x) \is_prec.
Proof.
exists (fun phi q => unsm phi q).
move => phi [x [[ox [phinox eq]] _]].
rewrite eq in phinox. move: phinox => [/= stuff name].
split.
	exists x; split; first by exists (unsm phi).
	by move => psi <-; exists x.
move => t [[psi [<- phint]]].
rewrite (rep_sing _ (unsm phi) t x) => //.
split.
	exists ox; split => //; rewrite /rep_opt eq; first done.
move => s a; exists x.
rewrite (rep_sing _ phi s ox) => //.
by rewrite eq.
Qed.

Lemma option_rs_prec_inv (X: rep_space) (Y: rep_space) (f: option X -> Y):
	f \is_prec_function
	->
	(fun a => f (some a)) \is_prec_function * (f None) \is_computable_element.
Proof.
move => [M Mcmpt].
split.
exists (fun phi => (M (fun q => match q with
	| inl str => (some star, some_answer X)
	| inr q => (some star, phi q)
	end))).
by move => phi x phinx; apply Mcmpt.
by exists (M (fun _ => (None, some_answer X))); apply Mcmpt.
Qed.

Lemma option_rs_prec_ind (X: rep_space) (Y: rep_space) (f: option X -> Y):
	(fun a => f (some a)) \is_prec_function -> (f None) \is_computable_element
	-> f \is_prec_function.
Proof.
move => [M Mcmpt] [N Ncmpt].
exists (fun phi => match (phi (inl star)).1 with
	| None => N
	| Some str => M (fun q => (phi (inr q)).2)
end).
move => phi x phinx.
case: x phinx => [/=a [eq phina] |/= Nope].
by rewrite eq; apply Mcmpt.
by rewrite Nope; apply Ncmpt.
Qed.

Lemma Some_prec (X: rep_space):
	(@Some X) \is_prec_function.
Proof.
by exists (fun phi q => if q is inr q' then (Some star, phi q') else (Some star, some_answer X)).
Qed.

Definition NXN_lst (X: rep_space) (onan: rep_space_opt _)
	:= if onan is Some nan then in_seg nan.2 (S nan.1) else [::]:seq X.

Definition rep_list (X: rep_space) := (F2MF (@NXN_lst X)) o (@delta _).

Lemma rep_list_sing X:
	(@rep_list X) \is_single_valued.
Proof.
by apply comp_sing; [exact: F2MF_sing | exact (rep_sing _)].
Qed.

Lemma inseg_trunc T an (m: nat) (a: T):
	forall k, m <= k -> in_seg (fun n: nat => if n < k then an n else a) m = in_seg an m.
Proof.
elim: m => // m ih k ineq/=.
by rewrite ineq ih; last by apply ltnW.
Qed.

Lemma rep_list_rep X:
	(@rep_list X) \is_representation.
Proof.
split; first exact: rep_list_sing.
elim.
	exists (fun _ => (None, (0,some_answer X))).
	split; first by exists None.
	move => a b; exact: F2MF_tot.
move => a L [phi [[/=onan [phinonan  onanL]] _]].
have [psi psina]:= rep_sur X a.
exists (fun q => (Some star, match q with
	| inl str => (0, some_answer X)
	| inr q' =>
		match q' with
		| inl str => (size L, some_answer X)
		| inr q'' => (0, if q''.1 < (size L) then rprj (unsm phi) q'' else psi q''.2)
	end
end)).
split; last by move => c d; exact: F2MF_tot.
case: onan phinonan onanL; last first.
	move => eq <-; exists (Some (0, fun _ => a)); split; split; split => //.
move => nan phinnan nanL.
exists (Some ((size L), fun n => if n < size L then nan.2 n else a)).
split.
	split; split => //=; rewrite /rprj => n /=.
	case (n < size L) => //; apply phinnan.2.
rewrite -nanL /F2MF /NXN_lst size_inseg/=.
have ->: S nan.1 < S nan.1 = false by apply ltnn.
have ->: nan.1 < S nan.1 by apply ltnSn.
suffices: in_seg (fun n : nat => if n < nan.1.+1 then nan.2 n else a) nan.1 = in_seg nan.2 nan.1.
	by move => ->.
elim: nan.1 => // n ih.
by rewrite inseg_trunc.
Qed.

Canonical rep_space_list (X: rep_space) := @make_rep_space
	(list X)
	_
	_
	(@rep_list X)
	(Some star, (some_answer rep_space_nat, some_answer X))
	(countable_questions (rep_space_opt (rep_space_prod rep_space_nat (rep_space_usig_prod X))))
	(countable_answers (rep_space_opt (rep_space_prod rep_space_nat (rep_space_usig_prod X))))
	(@rep_list_rep X).

Definition lnm_size X (phi: names (rep_space_list X)) :=
	match (phi (inl star)).1 with
		| Some str => S (unsm phi (inl star)).1
		| None => 0
	end.

Lemma lnm_size_crct X K phi:
	phi \is_name_of K -> (@lnm_size X phi) = size K.
Proof.
move => [[[]]]; rewrite /F2MF/NXN_lst/=/lnm_size/=; last by move => [-> <-].
by move => [n an] [[-> [/=name _]] eq] _; rewrite -eq /= -name /lprj size_inseg.
Qed.

Lemma size_prec_fun X:
	(fun K: rep_space_list X => size K) \is_prec_function.
Proof.
exists (fun phi str => lnm_size phi).
move => phi K phinK.
by rewrite (lnm_size_crct phinK).
Qed.

Definition lnm_list X (phi: names (rep_space_list X)):=
	in_seg (fun n => (fun q => rprj (unsm phi) (n, q))) (lnm_size phi).

Lemma lnm_list_size X phi:
	@lnm_size X phi = size (lnm_list phi).
Proof. by rewrite /lnm_list size_inseg. Qed.

Lemma cons_prec_fun (X: rep_space):
	(fun p => cons (p.1: X) p.2) \is_prec_function.
Proof.
exists (fun (phi: names (rep_space_prod X (rep_space_list X))) q => match q with
	| inl str => (some star, (0, some_answer X))
	| inr q' => match q' with
		| inl str => (Some star, ((lnm_size (rprj phi)), some_answer X))
		| inr p => (Some star, (0,if p.1 < lnm_size (rprj phi)
		then rprj (unsm (rprj phi)) p else (lprj phi p.2)))
	end
end).
move => phi [x K] [/=phinx phinK].
have eq:= (lnm_size_crct phinK).
have phinxK: phi \is_name_of (x, K) by split.
move: phinK => [[/=y [/=phiny yK]] _].
split; last by move => a b; exact: F2MF_tot.
case: y phiny yK => [nan phiny nanK | phiny yK]; last first.
	exists (Some (0, fun n => x)).
	rewrite -yK/= in eq => //; split; last by rewrite -yK.
	by split => //; split; [rewrite /lprj/id_rep eq | rewrite eq] => /=.
exists (Some (size  K, (fun n => if n < size K then nan.2 n else x))) => /=.
split; first by do 2 split => //; rewrite eq/rprj; by move => n/=; case: (n < size K) => //; apply phiny.2.2.
rewrite -nanK /F2MF/NXN_lst size_inseg /=.
replace (nan.1.+1 < nan.1.+1) with false by by rewrite ltnn.
replace (nan.1 < nan.1.+1) with true by by rewrite ltnSn.
by rewrite inseg_trunc => //.
Qed.

Lemma list_rs_prec_pind (X Y Z: rep_space) (g: Z -> Y) (h: (rep_space_prod Z (rep_space_prod X Y)) -> Y) f:
	g \is_prec_function -> h \is_prec_function
	-> (forall zK, f zK = (fix f z K := match K with
		| nil => g z
		| cons a K => h (z, (a, f z K)) 
	end) zK.1 zK.2) -> f \is_prec_function.
Proof.
move => [gM gMcmpt] [hM hMcmpt] feq.
pose psi (n:nat) (phi:names (rep_space_list X)) (q: questions (rep_space_list X)):= match n with
	| 0 => (None, (0, some_answer X))
	| S n => (Some star, (n, if q is (inr (inr p)) then (phi (inr (inr p))).2.2 else some_answer X))
end.
pose fM' := fix fM' n (phi: names (rep_space_prod Z (rep_space_list X))) := match n with
	| 0 => gM (lprj phi)
	| S n' => hM (name_pair (lprj phi)
		(name_pair (fun q => rprj (unsm (rprj phi)) (n', q))
		(fM' n' (name_pair (lprj phi) (psi n' (rprj phi))))))
end.
exists (fun phi q => fM' (lnm_size (rprj phi)) phi q).
move => phi [z K] [/=phinz phinK].
elim: K phi phinz phinK => [ | a K].
	by rewrite feq => phi phinz phinK; rewrite /fM' (lnm_size_crct phinK)/=; apply gMcmpt.
move => ih phi phinz phinK.
replace (f (z,(a :: K))) with (h (z, (a, f (z,K)))) by by rewrite (feq (z,a::K)) feq.
rewrite (lnm_size_crct phinK).
have [[y [phiny yaK]] _]:= phinK.
case: y phiny yaK => // [[n an]] [nn [/=phinn phinan]] yaK.
rewrite /id_rep/lprj in phinn.
rewrite /F2MF/NXN_lst/= in yaK.
apply hMcmpt.
have [<- anK]:= yaK.
do 2 split => //; rewrite !lprj_pair !rprj_pair/=.
	suffices <-: n = size K by apply phinan.
	by rewrite -anK size_inseg.
case E: (size K) => [ | k].
	have ->: K = nil by case T: K E => //.
	by rewrite /fM' feq/=; apply gMcmpt.
have psinK: (psi (S k) (rprj phi)) \is_name_of K.
	split; last by move => stuf stuff; exact: F2MF_tot.
	exists (Some (k, an)); split.
	split => //.
	rewrite /F2MF/NXN_lst/=.
	have [_ <-]:= yaK.
	have ->: n = size K by rewrite -anK size_inseg.
	by rewrite E.
rewrite -E.
have {1}<-: lnm_size (rprj (name_pair (lprj phi) (psi (size K) (rprj phi)))) = size K.
	by rewrite rprj_pair/psi/lnm_size E/=.
apply ih => //.
by rewrite rprj_pair E.
Qed.

Lemma list_rs_prec_ind (X Y: rep_space) (g: Y) (h: (rep_space_prod X Y) -> Y) f:
	g \is_computable_element -> h \is_prec_function
	-> (forall K, f K = (fix f K := match K with
		| nil => g
		| cons a K => h (a, f K)
	end) K) -> f \is_prec_function.
Proof.
move => gcmpt hprec feq.
set g' := (fun str: rep_space_one => g).
have g'prec: g' \is_prec_function by apply cnst_fun_prec.
set h' := (fun p:rep_space_prod rep_space_one (rep_space_prod X Y) => h p.2).
have h'prec: h' \is_prec_function.
	move: hprec => [hM hMprop].
	exists (fun phi q => hM (rprj phi) q).
	by move => phi [z p] [phinz phinp]; apply hMprop.
suffices: (fun oK: rep_space_prod rep_space_one (rep_space_list X) => f oK.2)\is_prec_function.
	move => [fM fMprop].
	exists (fun phi q => fM (name_pair (fun _ => star) phi) q).
	move => phi x phinx.
	by apply (fMprop (name_pair (fun _ => star) phi) (star, x)).
apply/ (list_rs_prec_pind g'prec h'prec) => /=.
by move => [str K]; rewrite feq; elim:str => /=; elim: K => // a K ->.
Qed.

Lemma map_prec (X Y: rep_space) (f: X -> Y):
	f \is_prec_function -> (fun K => map f K) \is_prec_function.
Proof.
move => fprec.
have nc: (@nil Y) \is_computable_element.
	exists (fun q => (None, (0, some_answer Y))).
	split; last by move => a b; exact: F2MF_tot.
	by exists None.
suffices hprec: (fun p => (f p.1 :: p.2)) \is_prec_function by apply/ (list_rs_prec_ind nc hprec).
apply/ prec_fun_comp; first	apply diag_prec_fun.
	apply/ prec_fun_comp; first apply prod_prec_fun.
			apply/ fst_prec.
		apply/ snd_prec.
	apply/ prec_fun_comp; first apply prod_prec_fun.
			apply fprec.
		apply id_prec_fun.
	by apply cons_prec_fun.
done.
done.
done.
Qed.

Definition NXN_lst_rev (X: rep_space) (onan: rep_space_opt _)
	:= if onan is Some nan then map nan.2 (iota 0 nan.1) else [::]:seq X.

Definition rep_list_rev (X: rep_space) := (F2MF (@NXN_lst_rev X)) o (@delta _).

Lemma rep_list_rev_sing X:
	(@rep_list_rev X) \is_single_valued.
Proof.
by apply comp_sing; [exact: F2MF_sing | exact (rep_sing _)].
Qed.

Lemma map_nth_iota T (x:T) p:
	[seq nth x p n0 | n0 <- iota 0 (size p)] = p.
Proof.
apply (@eq_from_nth T x); rewrite size_map size_iota => //.
move => k E.
rewrite (@nth_map nat 0%nat T x (fun n => nth x p n) k (iota 0 (size p))); last by rewrite size_iota.
by rewrite seq.nth_iota => //.
Qed.

Lemma rep_list_rev_rep X:
	(@rep_list_rev X) \is_representation.
Proof.
split; first exact: rep_list_rev_sing.
elim.
	exists (fun _ => (None, (0,some_answer X))).
	split; first by exists None.
	move => a b; exact: F2MF_tot.
move => x K [phi [[/=y [phiny yK]] _]].
rewrite /F2MF in yK.
set n := size K.
have [psi psina]:= rep_sur X x.
set nK := map (fun n => (fun q => rprj (unsm phi) (n,q))) (iota 0 n).
exists (fun q => match q with
	| inl str => (some star, (0, some_answer X))
	| inr q' => match q' with
		| inl str => (some star, (S n, some_answer X))
		| inr p => (some star, (some_answer rep_space_nat, match p.1 with
			| 0 => psi p.2
			| S n => nth psi nK n p.2
		end))
	end
end).
rewrite /rep_list/=.
split; last by move => a b; exact: F2MF_tot.
exists (Some (S n, (fun n => nth x (x:: K) n))).
rewrite /rep_opt/=/prod_rep/=/id_rep/=/rep_usig_prod/=;
rewrite /lprj/=/rprj/=/mf_prod_prod/=/NXN_lst_rev/F2MF.
split; last by rewrite map_nth_iota.
split => //.
split => //.
move => k.
case E: (k <= n); rewrite /n in E.
	case E': k => [ | m]//=.
	rewrite /rep_opt in phiny.
	case: y phiny yK.
		move => nan [/=sm name] nanK.
		rewrite /nK.
		rewrite /prod_rep/=/id_rep/=/lprj/rprj/=/mf_prod_prod/=/rep_usig_prod/= in name.
		move: name => [nnan prop].
		have ineq: m < n by rewrite /n; apply /leP; rewrite -E'; apply /leP; rewrite E.
		rewrite (nth_map 0); last by rewrite size_iota.
		specialize (prop m); rewrite nth_iota => //.
		suffices ->: (nth x K m) = nan.2 m by trivial.
		rewrite -nanK/=.
		have -> : nan.1 = n by rewrite /n -nanK size_map size_iota.
		rewrite (nth_map 0); last by rewrite size_iota.
		by rewrite nth_iota.
	rewrite /NXN_lst_rev => _ eq; rewrite -eq/= in E.
	have k0: k= 0 by apply /eqP; rewrite -leqn0 E.
	by rewrite k0 in E'.
case: k E => // m E.
by rewrite !nth_default => //=; [rewrite ltnS | rewrite /nK size_map size_iota/n]; rewrite leqNgt E.
Qed.

Definition rep_space_list_rev (X: rep_space) := @make_rep_space
	(list X)
	_
	_
	(@rep_list_rev X)
	(Some star, (some_answer rep_space_nat, some_answer X))
	(countable_questions (rep_space_opt (rep_space_prod rep_space_nat (rep_space_usig_prod X))))
	(countable_answers (rep_space_opt (rep_space_prod rep_space_nat (rep_space_usig_prod X))))
	(@rep_list_rev_rep X).

Definition lnmr_size X (phi: names (rep_space_list_rev X)) :=
	match (phi (inl star)).1 with
		| Some str => (unsm phi (inl star)).1
		| None => 0
	end.

Lemma lnmr_size_crct X K phi:
	phi \is_name_of K -> (@lnmr_size X phi) = size K.
Proof.
move => [[[]]]; rewrite /F2MF/NXN_lst_rev/=/lnmr_size/=; last by move => [-> <-].
by move => [n an] [[-> [/=name _]] eq] _; rewrite -eq size_map size_iota -name /lprj.
Qed.

Lemma size_rev_prec_fun X:
	(fun K: rep_space_list_rev X => size K) \is_prec_function.
Proof.
exists (fun phi str => lnmr_size phi).
move => phi K phinK.
by rewrite (lnmr_size_crct phinK).
Qed.

Definition lnmr_list X (phi: names (rep_space_list X)):=
	map (fun n => (fun q => (phi (inr (inr (n, q)))).2.2)) (iota 0 (lnmr_size phi)).

Lemma lnmr_list_size X phi:
	@lnmr_size X phi = size (lnmr_list phi).
Proof. by rewrite /lnmr_list size_map size_iota. Qed.

Lemma nth_prec_rev (X: rep_space):
	(fun aK => nth (aK.1: X) (aK.2: rep_space_list_rev X)) \is_prec_function.
Proof.
exists (fun psiphi p => match lnmr_size (rprj psiphi) with
	| 0 => lprj psiphi p.2: answers X
	| S n => nth (lprj psiphi) (lnmr_list (rprj psiphi)) p.1 p.2
end).
move => phi [a K] [/=psina phinK].
rewrite /delta/=/rep_usig_prod/= => n.
rewrite (lnmr_size_crct phinK)/=.
case: K phinK => /=; first by rewrite nth_default.
move => b K phinK.
case E: (n <= size K); last first.
	have ineq: size K < n by rewrite leqNgt; apply /leP => ineq;
		have:= le_S_n n (size K) ineq; apply /leP; rewrite E.
	rewrite !nth_default => //=; last rewrite /lnmr_list size_map size_iota (lnmr_size_crct phinK) => //=.
rewrite /lnmr_list.
have ineq: n < S (size K) by rewrite ltnS.
rewrite (nth_map 0); last rewrite size_iota (lnmr_size_crct phinK) => //=.
rewrite nth_iota; last rewrite (lnmr_size_crct phinK) => //=.
rewrite /rep_list in phinK.
move: phinK => [[onan [phinonan onanK]] _].
rewrite /F2MF /NXN_lst in onanK.
case: onan onanK phinonan => // [[k an]] onanK [_ [/=phinn phinK]].
have nk: n < k.
	suffices ->: k = (size (b::K)) by trivial.
	by rewrite -onanK size_map size_iota.
rewrite -onanK (nth_map 0); last rewrite size_iota => //=.
rewrite {1}/rprj in phinK.
by rewrite nth_iota.
Qed.

Lemma cons_prec_fun_rev (X: rep_space):
	(fun p => cons (p.1: X) (p.2: rep_space_list_rev X):rep_space_list_rev X) \is_prec_function.
Proof.
have [/= nthM Mprop]:= nth_prec_rev X.
exists (fun (phi: names (rep_space_prod X (rep_space_list X))) q => match q with
	| inl str => (some star, (0, some_answer X))
	| inr q' => match q' with
		| inl str => (some star, (S (lnmr_size (rprj phi)), some_answer X))
		| inr p => (some star, (some_answer rep_space_nat, match p.1 with
			| 0 => lprj phi p.2
			| S n => nthM phi (n, p.2)
		end))
	end
end).
move => phi [x K] [/=phinx phinK].
have eq:= (lnmr_size_crct phinK).
have phinxK: phi \is_name_of (x, K) by split.
move: phinK => [[y [/=phiny yK]] _].
rewrite /rep_list/=.
split; last by move => a b; exact: F2MF_tot.
exists (Some (size (x:: K), (fun n => nth x (x:: K) n))).
rewrite /rep_opt/=/prod_rep/=/id_rep/=/rep_usig_prod/=;
rewrite /lprj/=/rprj/=/mf_prod_prod/=/NXN_lst_rev/F2MF.
split; last by rewrite map_nth_iota.
split => //.
split; first by rewrite eq.
move => k.
case E: (k <= (size K)).
	case E': k => [ | m]//=.
	apply usig_base.
	by apply/ rlzr_val_sing; [ apply F2MF_sing | apply frlzr_rlzr; apply Mprop | apply phinxK | | ].
case: k E => // m E /=.
apply usig_base.
by apply/ rlzr_val_sing; [ apply F2MF_sing | apply frlzr_rlzr; apply Mprop | apply phinxK | | ].
Qed.

Lemma list_rev_rs_prec_pind (X Y Z: rep_space) (g: Z -> Y) (h: (rep_space_prod Z (rep_space_prod X Y)) -> Y) f:
	g \is_prec_function -> h \is_prec_function
	-> (forall zK, f zK = (fix f z (K: rep_space_list_rev X) := match K with
		| nil => g z
		| cons a K => h (z, (a, f z K)) 
	end) zK.1 zK.2) -> f \is_prec_function.
Proof.
move => [gM gMcmpt] [hM hMcmpt] feq.
have [cM cMcmpt]:= cons_prec_fun X.
pose psi (n:nat) (phi:names (rep_space_list_rev X)) (q: questions (rep_space_list_rev X)):= match n with
	| 0 => (None, (0, some_answer X))
	| S n => (Some star, (n, if q is (inr (inr p)) then (phi (inr (inr (S p.1,p.2)))).2.2 else some_answer X))
end.
pose fM' := fix fM' n (phi: names (rep_space_prod Z (rep_space_list_rev X))) := match n with
	| 0 => gM (lprj phi)
	| S n' => hM (name_pair (lprj phi) (name_pair (fun q =>
		((rprj phi) (inr (inr (0, q)))).2.2:answers X) (fM' n' (name_pair (lprj phi) (psi n (rprj phi))))))
end.
exists (fun phi q => fM' (lnmr_size (rprj phi): nat) phi q).
move => phi [z K] [/=phinz phinK].
elim: K phi phinz phinK => [ | a K].
	by rewrite feq => phi phinz phinK; rewrite /fM' (lnmr_size_crct phinK)/=; apply gMcmpt.
move => ih phi phinz phinK.
replace (f (z,(a :: K))) with (h (z, (a, f (z,K)))) by by rewrite (feq (z,a::K)) feq.
rewrite (lnmr_size_crct phinK).
move: phinK => [[y [phiny yaK]] _].
case: y phiny yaK => // [[n an]] [_ [/=phinn phinan]] yaK.
rewrite /id_rep/lprj in phinn.
rewrite /F2MF/NXN_lst_rev/= in yaK.
have eq: a = an 0 by case: n phinn yaK => //= n phinn [-> yak].
have psinK : (psi n (rprj phi)) \is_name_of K.
	rewrite /psi/=/delta/=/rep_list/=/F2MF/=/NXN_lst_rev/=.
	split; last by move => b c; apply: F2MF_tot.
	rewrite/ rel_comp.
	case E: n => [ | m]; first by rewrite E/= in yaK.
	exists (Some (m, (fun n => an (S n)))) => /=.
	split; last first.
		rewrite E in yaK.
		move : yaK => [_ <-]/=.
		apply /(@eq_from_nth _ a).
			by rewrite !size_map !size_iota.
		move => i ass /=.
		have im: i < m by rewrite size_map size_iota in ass.
		rewrite !(nth_map 0) => //; try rewrite size_iota//.
		rewrite !nth_iota => //=.
	split => //; split => //=.
	rewrite /id_rep/lprj.
	rewrite /rep_usig_prod/= => k.
	by rewrite /rprj/=; apply phinan.
specialize (ih (name_pair (lprj phi) (psi n (rprj phi))) phinz psinK).
pose phia0 q := (rprj phi (inr (inr (0, q)))).2.2.
have phia0na: phia0 \is_name_of a by rewrite eq;apply phinan.
have np:
	(name_pair (lprj phi)
		(name_pair phia0 [eta fM' (lnmr_size (psi n (rprj phi))) (name_pair (lprj phi) (psi n (rprj phi)))]))
			\is_name_of (z,(a,f (z, K))) by trivial.
apply/ rlzr_val_sing; [ apply F2MF_sing | apply frlzr_rlzr; apply hMcmpt | | | ].
		exact: np.
	by rewrite feq.
rewrite (lnmr_size_crct psinK)/F2MF.
rewrite /name_pair/phia0.
by have /= ->: n = size (a :: K) by rewrite -yaK size_map size_iota.
Qed.

Lemma list_rev_rs_prec_ind (X Y: rep_space) (g: Y) (h: (rep_space_prod X Y) -> Y) f:
	g \is_computable_element -> h \is_prec_function
	-> (forall K, f K = (fix f (K: rep_space_list_rev X) := match K with
		| nil => g
		| cons a K => h (a, f K)
	end) K) -> f \is_prec_function.
Proof.
move => gcmpt hprec feq.
set g' := (fun str: rep_space_one => g).
have g'prec: g' \is_prec_function by apply cnst_fun_prec.
set h' := (fun p:rep_space_prod rep_space_one (rep_space_prod X Y) => h p.2).
have h'prec: h' \is_prec_function.
	move: hprec => [hM hMprop].
	exists (fun phi q => hM (rprj phi) q).
	by move => phi [z p] [phinz phinp]; apply hMprop.
suffices: (fun oK: rep_space_prod rep_space_one (rep_space_list_rev X) => f oK.2)\is_prec_function.
	move => [fM fMprop].
	exists (fun phi q => fM (name_pair (fun _ => star) phi) q).
	move => phi x phinx.
	by apply (fMprop (name_pair (fun _ => star) phi) (star, x)).
apply/ (list_rev_rs_prec_pind g'prec h'prec) => /=.
by move => [str K]; rewrite feq; elim:str => /=; elim: K => // a K ->.
Qed.

Lemma map_prec_rev (X Y: rep_space) (f: X -> Y):
	f \is_prec_function -> (fun (K:rep_space_list_rev X) => map f K) \is_prec_function.
Proof.
move => fprec.
have nc: (@nil Y) \is_computable_element.
	exists (fun q => (None, (0, some_answer Y))).
	split; last by move => a b; exact: F2MF_tot.
	by exists None.
suffices hprec: (fun p => (f p.1 :: p.2)) \is_prec_function by apply/ (list_rev_rs_prec_ind nc hprec).
apply/ prec_fun_comp; first	apply diag_prec_fun.
	apply/ prec_fun_comp; first apply prod_prec_fun.
			apply/ fst_prec.
		apply/ snd_prec.
	apply/ prec_fun_comp; first apply prod_prec_fun.
			apply fprec.
		apply id_prec_fun.
	by apply cons_prec_fun.
done.
done.
done.
Qed.

End BASIC_CONSTRUCTIONS.

Section BASIC_PROPERTIES.
(* This Definition is equivalent to the notion Arno introduces in "https://arxiv.org/pdf/1204.3763.pdf".
One of the drawbacks fo the version here is that it does not have a computable version.*)
Definition is_dscrt X :=
	forall Y (f: (space X) -> (space Y)), (F2MF f) \has_continuous_realizer.
Notation "X '\is_discrete'" := (is_dscrt X) (at level 2).

Lemma dscrt_rel X:
	X \is_discrete -> (forall Y (f: (space X) ->> (space Y)), f \has_continuous_realizer).
Proof.
move => dscrt Y f_R.
case: (classic (exists y:Y, true)) => [[y _] | ]; last first.
	move => next;	exists (F2MF (fun _ => (fun _:questions Y => some_answer Y))).
	split; first by move => phi [y _]; exfalso; apply next; exists y.
	by move => phi val phifd; exists nil => Fphi /= <- psi _ Fpsi <-.
have [f icf]:= exists_choice f_R y.
have [F [Frf Fcont]]:= (dscrt Y f).
exists F; split => //.
apply/ tight_trans; first by apply Frf.
by apply tight_comp_l; apply icf_F2MF_tight.
Qed.

Lemma one_dscrt: rep_space_one \is_discrete.
Proof.
move => X f.
have [phi phinfs]:= rep_sur X (f star).
exists (F2MF (fun _ => phi)).
split; last by exists nil => Fphi <- psi _ Fpsi <-.
apply frlzr_rlzr => psi str psinstr.
by elim str.
Qed.

Lemma nat_dscrt: rep_space_nat \is_discrete.
Proof.
move => X f.
pose R phi psi:= forall n, phi \is_name_of n -> psi \is_name_of (f n).
have [F icf]:= exists_choice R (fun _ => some_answer X).
exists (F2MF F).
split.
	apply frlzr_rlzr => phi n phinn.
	have [ psi psinfn] := rep_sur X (f n).
	suffices Rphipsi: R phi psi by apply/ (icf phi psi Rphipsi).
	move => n' phinn'.
	by have <-: n = n' by rewrite -(rep_sing rep_space_nat phi n n').
move => n q _.
exists (cons star nil).
move => Fphi /= <- psi coin Fpsi <-.
suffices <-: n = psi by trivial.
apply functional_extensionality => str.
by elim str; rewrite coin.1.
Qed.

(*
Lemma iso_one (X :rep_space) (somex: X):
	(rep_space_one c-> X) ~=~ X.
Proof.
pose f (xf: rep_space_one c-> X) := (projT1 xf) star.
pose L := fix L n := match n with
	| 0 => nil
	| S n => cons (star, star) (L n)
end.
pose F n (phi: names (rep_space_one c-> X)) q := match (phi ((L n), q)) with
	| inl q => None
	| inr a => Some a
end.
have: (eval F) \is_realizer_of f.
move => phi [x [[xf [phinxf fxfx]]] prop].
have [xF icf] := exists_choice (projT1 xf) somex.
split.
	exists x.
	split.
		pose psi (str: one) := star.
		have []:= (phinxf psi).
		(exists (xF star)).
		split; first by exists star; split => //; apply/ icf; apply fxfx.
		move => s psins; exists x; elim s; apply fxfx.
	move => [x' [[phi' [evl phi'nx']]prop']] stuff.
	exists (phi').
	split.
		move => q.
		have [c val]:= evl q.
		exists c.
		apply/ icf'.
pose pT1g (x: X) := F2MF (fun _: rep_space_one => x).
have crlzr: forall x:X, has_cont_rlzr (pT1g x) by move => x; apply one_dscrt.
have sing: forall (x: X), (pT1g x) \is_single_valued by move => x; apply F2MF_sing.
have tot: forall (x: X), (pT1g x) \is_total by move => x; apply F2MF_tot.
pose g (x:X) := exist_fun (conj (conj (sing x) (tot x)) (crlzr x)).
exists f'.
exists (F2MF g).
split.
	admit.
split.
	apply prim_rec_comp.
	pose psi:= fun (phi: names X) => (fun p: seq (one * one) * (questions X) => inr (phi p.2): sum one _).
	exists (psi).
	apply frlzr_rlzr.
	move => phi x phinx/=.
	rewrite /is_fun_name/is_rlzr/=.
	move => p pfd.
	split.
		exists x.
		split.
			exists phi.
			split => //.
			by exists 0.
		move => phi' ev.
		exists x.
		suffices: phi = phi' by move <-.
		apply functional_extensionality => q.
		apply Some_inj.
		have [/=n <-]:= (ev q).
		replace (Some (phi q)) with (U (psi phi) n p q) => //.
		have U0: U (psi phi) 0 p q = Some (phi q) by trivial.
		apply/ U_mon; last by apply U0.
		by replace (pickle 0) with 0 by trivial; lia.
	move => x' [[phi' [ev phi'nx']] prop].
	split.
		exists star.
		split; first by rewrite /id_rep; case (p star).
		suffices eq: phi = phi'	by apply ((\rep_valid X).1 phi x x') => //; rewrite eq.
		apply functional_extensionality => q.
		apply Some_inj.
		have [/=n <-]:= (ev q).
		replace (Some (phi q)) with (U (psi phi) n p q) => //.
		have U0: U (psi phi) 0 p q = Some (phi q) by trivial.
		apply/ U_mon; last by apply U0.
		by replace (pickle 0) with 0 by trivial; lia.
	by move => str eq; exists x.
split.
	rewrite F2MF_comp => x y.
	by rewrite /f /g /pT1g/F2MF/=.
rewrite comp_tot.
split.
	move => [x [b c]].
	rewrite /f in b.
	rewrite -c /g/pT1g/F2MF/=.
	apply eq_sub.
	apply functional_extensionality => str/=.
	elim str.
	apply functional_extensionality => x'/=.
	rewrite /= in b.
Admitted.

Lemma wiso_usig X:
	wisomorphic (rep_space_usig_prod X) (rep_space_cont_fun rep_space_nat X).
Proof.
have crlzr: forall xn: nat -> X, hcr (F2MF xn).
	move => xn.
	pose R phi psi := psi \is_name_of (xn (phi star)).
	have Rtot: R \is_total by move => phi; apply (rep_sur X).
	have [F icf]:= choice R Rtot.
	(*
	exists F; split.
		by apply rlzr_mfrlzr => phi x phinx; rewrite -phinx; apply/icf.
	move => phi q phifd; exists ([::star]) => Fphi /= FphiFphi psi coin.
	have eq: phi = psi.
		by apply functional_extensionality => /= str; elim: str; apply coin.
	by rewrite -eq => Fpsi FpsiFpsi; rewrite -FpsiFpsi -FphiFphi.*)
Admitted. *)
End BASIC_PROPERTIES.

