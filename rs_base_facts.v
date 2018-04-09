From mathcomp Require Import all_ssreflect.
Require Import all_core rs_base rs_base_prod rs_base_fun rs_base_sub.
Require Import FunctionalExtensionality Psatz .

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section COMPUTABILITIES_AND_COMPOSITION.
Set Printing Implicit.

Lemma prec_fun_cmpt_elt (X Y: rep_space) (f: X -> Y) (x: X):
	x \is_computable_element -> f \is_prec_function -> (f x) \is_computable_element.
Proof.
move => [phi phinx] [M Mrf].
by exists (M phi); apply Mrf.
Defined.

Lemma prec_fun_prec (X Y: rep_space) (f: X -> Y):
	f \is_prec_function -> (F2MF f) \is_prec.
Proof.
move => [M Mprop]; by exists M; apply frlzr_rlzr.
Qed.

Lemma cmpt_elt_mon_cmpt (X Y: rep_space) (f: X c-> Y):
	f \is_computable_element -> (projT1 f) \is_monotone_computable.
Proof. move => [psiF comp]; exists (U psiF); split => //; exact: U_mon. Qed.

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

Lemma prec_comp (X Y Z: rep_space) (f: X ->> Y) (g: Y ->> Z) h:
	f \is_prec -> g \is_prec -> h =~= g o f -> h \is_prec.
Proof.
move => [M comp] [N comp'] eq.
exists (fun phi => N (M phi)); rewrite eq.
suffices ->: F2MF (fun phi => N (M phi)) =~= (F2MF N) o (F2MF M) by apply rlzr_comp.
by rewrite F2MF_comp.
Defined.

Lemma prec_fun_prec_comp (X Y Z: rep_space) (f: X ->> Y) (g: Y -> Z):
	f \is_total -> f \is_prec -> g \is_prec_function
	-> forall h, (forall x y, f x y -> h x = g y) -> h \is_prec_function.
Proof.
move => ftot [M comp] [N comp'] h eq.
exists (fun phi => N (M phi)).
move => phi x phinx.
have [y fxy]:= ftot x.
have prop: phi \from_dom (f o (delta (r:=X))).
	exists y; split; first by exists x.
	by move => x' phinx'; rewrite (rep_sing X phi x' x).
have [y' [[psi [<- name]] _]]:= (comp phi prop).1.
rewrite (eq x y') => //; first by apply comp'.
have cond: ((delta (r:=Y)) o (F2MF M) phi y').
	split; first by exists (M phi).
	by move => Mpsi <-; exists y'.
have [[x' [phinx' fx'y']] _] := (comp phi prop).2 y' cond.
by rewrite (rep_sing X phi x x').
Qed.

Lemma prec_fun_cmpt_comp (X Y Z: rep_space) (f: X -> Y) (g: Y -> Z):
	f \is_prec_function -> g \is_computable_function
	-> forall h, (forall x, h x = g (f x)) -> h \is_computable_function.
Proof.
move => [M comp] [N comp'] h eq.
exists (fun n phi => N n (M phi)).
have eq': (F2MF h) =~= ((F2MF g) o (F2MF f)) by rewrite F2MF_comp/ F2MF => r; rewrite -(eq r).
rewrite eq'.
apply/ tight_trans; last first.
	by rewrite comp_assoc; apply tight_comp_r; apply ((frlzr_rlzr _ _).1 comp).
apply/ tight_trans; last by rewrite -comp_assoc; apply tight_comp_l; apply comp'.
by rewrite comp_assoc; apply/ tight_comp_r; rewrite F2MF_comp.
Qed.

(*Lemma cmpt_fun_comp (X Y Z: rep_space) (f: X -> Y) (g: Y -> Z):
	f \is_monotone_computable -> g \is_computable_function
	-> forall h, (forall x, h x = g (f x)) -> h \is_computable_function.
Proof.
move => [M comp] [N comp'] h eq.
exists (fun phi => N (M phi)).
by move => phi x phinx; rewrite eq; apply comp'; apply comp.
Defined.*)

Lemma prec_fun_cmpt (X Y: rep_space) (f: X -> Y):
	f \is_prec_function -> f \is_computable_function.
Proof.
move => [N Nir]; exists (fun n phi q' => Some (N phi q')).
apply/ tight_trans; last by apply frlzr_rlzr; apply Nir.
apply tight_comp_r; apply: prec_F2MF_op 0.
Qed.

Definition fun_comp X Y Z (f: X c-> Y) (g: Y c-> Z) :(X c-> Z) :=
	exist_c (comp_sing (projT2 g).1.1 (projT2 f).1.1)
		(comp_tot (projT2 f).1.2 (projT2 g).1.2)
		(comp_hcr (projT2 f).2 (projT2 g).2).

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
Admitted.
*)

End COMPUTABILITIES_AND_COMPOSITION.

Section SPECIAL_FUNCTIONS.

Lemma cnst_fun_prec (X Y: rep_space) (y: Y):
	y \is_computable_element -> (fun _: X => y) \is_prec_function.
Proof. by move => /=[psi psiny]; exists (fun _ => psi). Defined.

Lemma prec_cmpt (X Y:rep_space) (f: X ->> Y):
	f \is_prec -> f \is_computable.
Proof.
move => [N Nir]; exists (fun n phi q' => Some (N phi q')).
by apply/ tight_trans; first by apply/ tight_comp_r;	apply (prec_F2MF_op 0).
Qed.

Lemma id_prec X:
	@is_prec X X (F2MF id).
Proof. by exists id; apply frlzr_rlzr. Defined.

Lemma id_prec_fun X:
	(@id (space X)) \is_prec_function.
Proof. by exists id. Defined.

Lemma id_cmpt X:
	@is_comp X X (F2MF id).
Proof. exact: (prec_cmpt (id_prec X)). Qed.

Lemma id_hcr X:
	@hcr X X (F2MF id).
Proof.
exists (F2MF id).
split; first by apply frlzr_rlzr.
move => phi q' _.
exists [ ::q'].
move => Fphi /= <- psi coin Fpsi <-.
apply coin.1.
Qed.

Definition id_fun X :=
	(exist_fun (id_hcr X)).

Lemma id_comp_elt X:
	(id_fun X) \is_computable_element.
Proof.
pose id_name p := match p.1: seq (questions X* answers X) with
		| nil => inl (p.2:questions X)
		| (q,a):: L => inr (a: answers X)
	end.
exists (id_name).
rewrite /delta /= /is_fun_name/=.
rewrite /rlzr id_comp.
rewrite -{1}(comp_id (rep X)).
apply tight_comp_r.
apply/ (mon_cmpt_op); first exact: U_mon.
by move => phi q; exists 1.
Qed.

Definition diag (X: rep_space):= (fun x => (x,x): rep_space_prod X X).

Lemma diag_hcr (X: rep_space):
	(F2MF (@diag X)) \has_continuous_realizer.
Proof.
exists (F2MF (fun phi => name_pair phi phi)).
split; first by apply frlzr_rlzr.
move => phi q.
case: q => q; by exists [:: q] => Fphi/= <- psi [eq _] Fpsi <-; rewrite /name_pair eq.
Qed.

Lemma diag_prec_fun (X: rep_space):
	(@diag X) \is_prec_function.
Proof.
by exists (fun phi => name_pair phi phi).
Defined.

Lemma diag_prec (X: rep_space):
	(F2MF (@diag X)) \is_prec.
Proof.
by exists (fun phi => name_pair phi phi); rewrite -frlzr_rlzr.
Qed.

Lemma diag_cmpt_fun (X: rep_space):
	(@diag X) \is_computable_function.
Proof.
apply prec_fun_cmpt; apply diag_prec_fun.
Qed.

Lemma diag_cmpt (X: rep_space):
	(F2MF (@diag X)) \is_computable.
Proof.
apply prec_cmpt; apply diag_prec.
Qed.
End SPECIAL_FUNCTIONS.

Lemma prod_space_cont (X Y Z: rep_space) (f: Z c-> X) (g: Z c-> Y):
	exists (F: rep_space_cont_fun Z (rep_space_prod X Y)),
		((F2MF (@fst X Y)) o (projT1 F) =~= (projT1 f))
		/\
		((F2MF (@snd X Y)) o (projT1 F) =~= (projT1 g)).
Proof.
set F := (((projT1 f) ** (projT1 g)) o (F2MF (fun z => (z, z)))).
have Fsing: F \is_single_valued.
	apply comp_sing; last exact: F2MF_sing.
	apply mfpp_sing; split; [apply (projT2 f).1.1 | apply (projT2 g).1.1].
have Ftot: F \is_total.
	apply comp_tot; first exact: F2MF_tot.
	apply mfpp_tot; split; [apply (projT2 f).1.2 | apply (projT2 g).1.2].
have Fhcr: F \has_continuous_realizer.
	by apply comp_hcr; [apply diag_hcr | apply mfpp_hcr; [apply (projT2 f).2 | apply (projT2 g).2 ]].
exists (exist_c Fsing Ftot Fhcr).
split.
	rewrite /=/F F2MF_comp.
	rewrite sing_comp => //=; rewrite /mf_prod_prod/=; [ | | ].
			rewrite /F2MF => z x.
			split => [val| fzx [x' y] [fzx' gzy]]; last by rewrite ((projT2 f).1.1 z x x').
			have [x' fzx']:= (projT2 f).1.2 z.
			have [y gzy]:= (projT2 g).1.2 z.
			by rewrite -(val (x',y) (conj fzx' gzy)) => //.
		move => z p p' [fzp fzp'] [gzp gzp'].
		by apply injective_projections; [rewrite ((projT2 f).1.1 z p.1 p'.1) | rewrite ((projT2 g).1.1 z p.2 p'.2)].
	move => z.
	have [x fzx]:= (projT2 f).1.2 z.
	have [y gzy]:= (projT2 g).1.2 z.
	by exists (x, y).
rewrite /=/F F2MF_comp sing_comp => //=; rewrite /mf_prod_prod/=; [ | | ].
rewrite /F2MF => z y.
split => [val| gzy [x y'] [fzx gzy']]; last by rewrite ((projT2 g).1.1 z y y').
have [y' gzy']:= (projT2 g).1.2 z.
have [x fzx]:= (projT2 f).1.2 z.
by rewrite -(val (x,y') (conj fzx gzy')) => //.
	move => z p p' [fzp fzp'] [gzp gzp'].
	by apply injective_projections; [rewrite ((projT2 f).1.1 z p.1 p'.1) | rewrite ((projT2 g).1.1 z p.2 p'.2)].
move => z.
have [x fzx]:= (projT2 f).1.2 z.
have [y gzy]:= (projT2 g).1.2 z.
by exists (x, y).
Qed.


Lemma fst_cmpt (X Y: rep_space):
	(exist_fun (@fst_cont X Y)) \is_computable_element.
Proof.
exists (fun Lq => match Lq.1  with
	| nil => inl (inl Lq.2)
	| cons a K => inr a.2.1
end).
set psi:= (fun Lq => match Lq.1  with
	| nil => inl (inl Lq.2)
	| cons a K => inr a.2.1
end).
have eq: eval (U psi) =~= F2MF (@lprj X Y).
	move => phi Fphi.
	split => ass; last by rewrite -ass; exists 1.
	apply functional_extensionality => q.
	have [n val] := ass q.
	have U1: U psi 1 phi q = Some (lprj phi q) by trivial.
	apply Some_inj.
	rewrite -val.
	apply esym.
	apply/ U_mon; last apply U1.
	rewrite /pickle/=.
	by case: n val => // n val; lia.
rewrite /delta/=/is_fun_name/= eq.
by apply frlzr_rlzr => phi x [phinx _].
Qed.

Lemma snd_cmpt (X Y: rep_space):
	(exist_fun (@snd_cont X Y)) \is_computable_element.
Proof.
exists (fun Lq => match Lq.1  with
	| nil => inl (inr Lq.2)
	| cons a K => inr a.2.2
end).
set psi:= (fun Lq => match Lq.1  with
	| nil => inl (inr Lq.2)
	| cons a K => inr a.2.2
end).
have eq: eval (U psi) =~= F2MF (@rprj X Y).
	move => phi Fphi.
	split => ass; last by rewrite -ass; exists 1.
	apply functional_extensionality => q.
	have [n val] := ass q.
	have U1: U psi 1 phi q = Some (rprj phi q) by trivial.
	apply Some_inj.
	rewrite -val.
	apply esym.
	apply/ U_mon; last apply U1.
	rewrite /pickle/=.
	by case: n val => // n val; lia.
rewrite /delta/=/is_fun_name/= eq.
by apply frlzr_rlzr => phi x [_ phinx].
Qed.

(*
Lemma prod_space_cmpt (X Y Z: rep_space) (f: Z c-> X) (g: Z c-> Y):
	f \is_computable_element -> g \is_computable_element ->
	exists (F: Z c-> (rep_space_prod X Y)) (P:	F \is_computable_element),
		((F2MF (@fst X Y)) o (projT1 F) =~= (projT1 f))
		/\
		((F2MF (@snd X Y)) o (projT1 F) =~= (projT1 g)).
Proof.
move => [phi phinf] [psi psing].
have [F Fprop]:= prod_space_cont f g.
exists F; split; last exact: Fprop.
suffices eq: projT1 F =~= (((projT1 f) ** (projT1 g)) o (F2MF (fun z => (z, z)))).
exists (fun Lq => match Lq.2 with
	|inl q' => match phi (Lq.1, q') with
		| inl q'' => inl q''
		| inr a => inr (a, some_answer Y)
	end
	|inr q' => match psi (Lq.1, q') with
		| inl q'' => inl q''
		| inr a => inr (some_answer X, a)
	end
end).
set psiF:=(fun Lq => match Lq.2 with
	|inl q' => match phi (Lq.1, q') with
		| inl q'' => inl q''
		| inr a => inr (a, some_answer Y)
	end
	|inr q' => match psi (Lq.1, q') with
		| inl q'' => inl q''
		| inr a => inr (some_answer X, a)
	end
end).
*)


Section FUNCTION_SPACES.

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

Lemma eval_rlzr X Y:
	(eval (fun n psiphi q => U (lprj psiphi) n (rprj psiphi) q)) \is_realizer_of (@evaluation X Y).
Proof.
set R:=(fun n psiphi q => U (lprj psiphi) n (rprj psiphi) q).
move => psiphi [y [[[f x] [[/=psinf phinx] fxy]] prop]].
rewrite /is_fun_name/= in psinf.
have eq: (eval (U (lprj psiphi))) (rprj psiphi) = (eval R) psiphi by trivial.
have Rsing: (oeval R) \is_single_valued.
	apply mon_sing_op => /= n m phi q' a' nlm Rnphiqa.
	apply/ U_mon; [ apply nlm | apply Rnphiqa ].
have [Fpsiphi val]:= (@rlzr_dom _ _ (sval f) _ psinf (rprj psiphi) x phinx ((projT2 f).1.2 x)).
have Fpsiphiny: Fpsiphi \is_name_of y.
	by apply/ rlzr_val_sing; [ apply (projT2 f).1.1 | apply psinf | apply phinx | apply fxy | ].
split.
	exists y; split; first by exists Fpsiphi.
	move => psi eval; rewrite (Rsing psiphi psi Fpsiphi) => //; exists y.
	by apply/ rlzr_val_sing; [ apply (projT2 f).1.1 | apply psinf | apply phinx | apply fxy | ].
move => y' [[Fphi [val' Fphiny]]cond].
split.
	exists (f,x); split => //.
	rewrite (Rsing psiphi Fphi Fpsiphi) in Fphiny => //.
	by rewrite (rep_sing Y Fpsiphi y' y).
move => [f' x'] [psinf' phinx'].
exists y; rewrite (rep_sing (X c-> Y) (lprj psiphi) f' f) => //.
by rewrite (rep_sing X (rprj psiphi) x' x).
Qed.

Lemma eval_cmpt X Y:
	(@evaluation X Y) \is_computable.
Proof.
exists (fun n psiphi q => U (lprj psiphi) n (rprj psiphi) q).
exact: eval_rlzr.
Qed.

(*Lemma eval_hcr X Y:
	(@evaluation X Y) \has_continuous_realizer.
Proof.
exists (eval (fun n psiphi q => U (lprj psiphi) n (rprj psiphi) q)).
split; first exact: eval_rlzr.
move => psiphi q [Fpsiphi val].
have [n evl] := val q.
Admitted.*)
End FUNCTION_SPACES.































