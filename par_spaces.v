(* This file provides an alternative formulation of represented spaces that saves
the input and output types of the names *)
From mathcomp Require Import all_ssreflect.
Require Import universal_machine multi_valued_functions machines.
Require Import FunctionalExtensionality Psatz.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section REPRESENTED_SPACES.
Definition is_rep S T (delta: S ->> T) :=
  delta is_single_valued /\ delta is_surjective.
Notation "delta 'is_representation'" := (is_rep delta) (at level 2).
(* S ->> T is a notation for S -> T -> Prop. This defines a representation to be a
surjective and singlevalued multi-valued function. Due to delta being single-valued
this can also be phrased as a representation being a partial surjection. *)

Definition is_rep_of S T (delta: S ->> T) (P : T -> Prop) :=
  delta is_single_valued_wrt (fun t t' => t = t') /\ delta is_surjective_wrt P.
Notation "delta 'is_representation_of' elements" := (is_rep_of delta elements) (at level 2).
(* To make subspaces work, we allow predicates as the underlying set of a represented space. *)

Definition is_rep_of_wrt S T (delta: S ->> T) (P: T -> Prop) (R: T-> T -> Prop) :=
  delta is_single_valued_wrt R /\ delta is_surjective_wrt P.
Notation "delta 'is_representation_wrt' equals 'of' elements" :=
  (is_rep_of_wrt delta elements equals) (at level 2).
(* This is to make it possible to identify elements arbirarily, i.e. make quotients work. *)

Lemma R_sym S T delta P R:
	@is_rep_of_wrt S T delta P R -> forall s t, P s -> P t -> (R s t -> R t s).
Proof.
move => [] sing sur t t' Pt Pt' Rtt'.
	move: (sur t Pt) => [] s [] dst sprop.
	move: (sing.2 s t t' dst Rtt') => dst'.
	by apply/ (sing.1 s).
Qed.

Lemma R_trans S T delta P R:
	@is_rep_of_wrt S T delta P R -> forall s r t, P s -> P r -> P t -> R s r -> R r t -> R s t.
Proof.
move => rep s r t Ps Pr Pt Rsr Rrt'.
move: (rep.2 r Pr) => [] s' [] ds'r sprop.
move: (rep.1.2 s' r t ds'r Rrt') => ds't.
move: (R_sym rep Ps Pr Rsr) => Rrs.
move: (rep.1.2 s' r s ds'r Rrs) => dst.
apply/ (rep.1.1).
apply dst.
apply ds't.
Qed.

Lemma R_equiv S T delta P R:
	@is_rep_of_wrt S T delta P R ->
		(forall t, P t -> R t t)
		/\
		(forall s t, P s -> P t -> (R s t -> R t s) /\ forall r, P r -> R s r -> R r t -> R s t).
Proof.
move => rep.
split.
	move => t Pt.
	move: ((rep.2 t Pt)) => [] s' [] ds't sprop.
	by apply (rep.1.1 s' t t).
split.
by apply/ (R_sym rep).
move => r Pr Rsr Rrt.
apply/ (R_trans rep) => //.
by apply Pr => //.
done.
done.
Qed.

Lemma sur_rep_b S T (delta: S ->> T) :
  delta is_representation <-> delta is_representation_of (fun x => True).
Proof.
split.
- move => [issing issur].
	split.
		split.
 			move => s t t' dst dst'.
 			by apply: (issing.1 s t t').
 		move => s t t' dst eq.
 		by rewrite -eq.
  move => t _ .
  move: (issur t) => [] s dst.
  by exists s.
move => [issing issur].
split.
	split.
		move => s t t' dst dst'.
  	by apply: (issing.1 s t t').
	move => s t t' dst eq.
	by rewrite -eq.
move => t.
have: True.
	done.
move => true.
move: (issur t true) => []s []dst_.
by exists s.
Qed.

Lemma sur_rep S T (delta: S ->> T) :
  delta is_representation -> delta is_representation_of (fun x => True).
Proof.
  move: (sur_rep_b delta) => [cond cond'].
  exact: cond.
Qed.

Lemma sur_rep_sing_b S T (delta: S ->> T) (P: T -> Prop) :
  delta is_representation_of P <-> delta is_representation_wrt (fun x y => x = y) of P.
Proof.
done.
Qed.

Lemma sur_rep_sing S T (delta: S ->> T) (P: T -> Prop) :
  delta is_representation_of P -> delta is_representation_wrt (fun x y => x = y) of P.
Proof.
move: (sur_rep_sing_b delta P) => [cond cond'].
exact: cond.
Qed.
(* To construct a represented space it is necessary to provide a proof that the
representation is actually a representation. The names can be an arbitrary type
but will usually be something that can be computed on, i.e. Baire space or something.
At some point I will probably change the names to be a size_type. The type of names
must be inherited for the rather irrelevant full function-space construction to
work. This may change depending on whether other function space constructions also
need this or not. *)
Structure type := make_rep_space {
  space : Type;
  elements : space -> Prop;
  equals : space -> space -> Prop;
  questions : Type;
  answers : Type;
	No_answer:answers;
  delta : (questions -> answers) ->> space;
  countable_questions: questions is_countable;
  countable_answers: answers is_countable;
  representation_is_valid : delta is_representation_wrt equals of elements
  }.
Notation names X := ((questions X) -> (answers X)).

Definition prod_rep X Y :=
	(fun (phipsi : (questions X + questions Y -> answers X + answers Y)) x =>
      delta (fun q => match phipsi (inl q) with
        | inl a => a
        | inr b => No_answer X
      end) x.1 /\ delta (fun q => match phipsi (inr q) with
        | inl a => No_answer Y
        | inr b => b
      end) x.2).

Lemma prod_rep_is_rep (X Y : type):
  (@prod_rep X Y) is_representation_wrt
  (fun x y => equals x.1 y.1 /\ equals x.2 y.2)
    of
  (fun x => elements x.1 /\ elements x.2).
Proof.
move: (@representation_is_valid X) (@representation_is_valid Y)
  => [xsing xsur] [ysing ysur].
split.
	split.
		move => phipsi [x y] [x' y'] /= [inx iny] [inx' iny'].
    split.
      apply: xsing.1 => //.
      	by apply: inx.
      by apply: inx'.
    apply: ysing.1 => //.
      by apply iny.
    by apply iny'.
	move => phipsi.
	move => [] x y [] x' y' /=[] inx iny [] ex ey.
	split.
		apply/ xsing.2.
			by apply inx.
		done.
	apply/ ysing.2.
		by apply iny.
	done.
move => [] x y /=[Px Py].
move: (xsur x Px) => [] phi []dphix phiprop.
move: (ysur y Py) => [] psi []dpsiy psiprop.
exists (fun q => match q with
	| inl qx => inl (phi qx)
	| inr qy => inr (psi qy)
end).
rewrite /prod_rep.
split => //= [] s t' [] dx dy [] dt1 dt2.
split.
	apply: phiprop.
		by apply dx.
	by apply dt1.
apply: psiprop.
	by apply dy.
by apply dt2.
Qed.

(* This is the product of represented spaces. At some point I should prove that this
is the product in some category, but I am unsure what the morphisms are supposed to be. *)

Notation rep_space := type.
Notation "'rep'" := @delta (at level 2).
Notation "phi 'is_name_of' x" := (delta phi x) (at level 2).
Notation "x 'is_element'" := (elements x) (at level 2).
Notation "x 'is_from' X" := (@elements X x) (at level 2).
Notation "x 'equal' y" := (@equals x y) (at level 2).

Lemma sum_is_countable Q Q':
  Q is_countable -> Q' is_countable -> (Q + Q') is_countable.
Proof.
move => [cnt1] sur1 [cnt2] sur2.
set cnt' := fix cnt' n acc := match n with
	| 0 => inl (cnt1 acc) 
	| 1 => inr (cnt2 acc)
	| S (S n') => (cnt' n' (S acc))
end.

have prop: forall n k, cnt' (2 * n) k = inl(cnt1 (n + k)).
	elim => //.
	move => n ih k.
	replace (2*n.+1) with ((2*n).+2) by by rewrite /muln/muln_rec; lia.
	rewrite /= (ih (k.+1)).
	by replace (n + k.+1) with (n.+1 + k) by by rewrite /addn/addn_rec; lia.
have prop2: forall n k, cnt' (2 * n + 1) k = inr(cnt2 (n + k)).
	elim => //.
	move => n ih k.
	replace (2*n.+1) with ((2*n).+2) by by rewrite /muln/muln_rec; lia.
	rewrite /= (ih (k.+1)).
	by replace (n + k.+1) with (n.+1 + k) by by rewrite /addn/addn_rec; lia.

exists (fun n => cnt' n 0).
rewrite /is_sur.
apply sum_rect.
	move => s.
	move: (sur1 s) => [n] idx.
	exists (2*n).
	move: n s idx.
	rewrite /F2MF.
	elim.
		move => s idx.
		by rewrite -idx.
	move => n ih s idx.
	replace (2 * n.+1) with ((2 * n).+2) by by rewrite /muln/muln_rec; lia.
		rewrite -idx /=.
		rewrite prop.
		by replace (S n) with (n + 1) by by rewrite /addn/addn_rec; lia.
	move => s.
	move: (sur2 s) => [n] idx.
	exists (2*n + 1).
	move: n s idx.
	rewrite /F2MF.
	elim.
		move => s idx.
		by rewrite -idx.
	move => n ih s idx.
	replace (2 * n.+1) with ((2 * n).+2) by by rewrite /muln/muln_rec; lia.
		rewrite -idx /=.
		rewrite prop2.
		by replace (S n) with (n + 1) by by rewrite /addn/addn_rec; lia.
Qed.

Canonical rep_space_prod X Y := @make_rep_space
  (space X * space Y)
  (fun x => x.1 is_element /\ x.2 is_element)
  (fun x y => equals x.1 y.1 /\ equals x.2 y.2)
  (@questions X + @questions Y)
  (@answers X + @answers Y)
  (inl (No_answer X))
  (@prod_rep X Y)
  (sum_is_countable (countable_questions X) (countable_questions Y))
  (sum_is_countable (countable_answers X) (countable_answers Y))
  (@prod_rep_is_rep X Y).

Lemma prod_is_countable Q Q':
  Q is_countable -> Q' is_countable -> (Q * Q') is_countable.
Proof.
move => [] cntQ surQ [] cntQ' surQ'.
rewrite /is_count.

Lemma list_is_countable Q:
  Q is_countable -> Q' is_countable -> (Q + Q') is_countable.
Proof.

(*Definition make_rep_space_from_sur
  (space : Type)
  (questions : Type)
  (answers : Type)
  (delta : (questions->answers) ->> space) (representation_is_valid : is_rep delta) :=
  @make_rep_space space
    (fun x=> True)
    (fun x y => x= y)
    questions
    answers
    (sur_rep_sing (sur_rep representation_is_valid))
  .*)

Lemma fun_rep_on_range S X (f : S -> X) :
  (F2MF f) is_representation_of (range (F2MF f)).
Proof.
split.
	split => s t t' fst H;by rewrite -H.
move => t [] s fst.
exists s.
split => //.
move => s' x' fs't fs't'.
by exists s'.
Qed.

(*
Definition make_rep_space_from_fun
  (space : Type)
  (names : Type)
  (inhe : names)
  (delta : names -> space) :=
    @rep_space.make_rep_space
      space
      (range (F2MF delta))
      (fun x y => x = y)
      names
      inhe
      (F2MF delta)
      (sur_rep_sing (fun_rep_on_range delta))
    .
*)

Lemma single_valued_rep_on_range S T (f : S ->> T) :
  f is_single_valued -> f is_representation_of (range f).
Proof.
move => sing.
split => //.
move => t [] s fst.
exists s.
split => //.
move => s' t' _ fs't'.
by exists s'.
Qed.

(*
Definition make_rep_space_from_mfun
  (space: Type)
  (names : Type)
  (inhe:names)
  (delta: names ->> space)
  (sing: delta is_single_valued) :=
    @rep_space.make_rep_space
      space
      (range delta)
      (fun x y => x = y)
      names
      inhe
      delta
      (sur_rep_sing (single_valued_rep_on_range sing)).

Definition make_rep_space_from_fun
  (space : Type)
  (questions : Type)
  (answers : Type)
  (delta: (questions->option answers) -> space) :=
    @make_rep_space
      space
      (range (F2MF delta))
      (fun x y => x = y)
      questions
      answers
      (F2MF delta)
      (sur_rep_sing (fun_rep_on_range delta))
    .
*)

Definition is_mf_realizer (X Y : rep_space) F (f : (space X) ->> (space Y)) :=
  forall phi x y, delta phi x -> delta (F phi) y -> f x y.
(* One candidate for the morphisms: The multivalued realizable functions. *)

Definition is_realizer (X Y : rep_space) F (f: space X -> space Y) := is_mf_realizer F (F2MF f).
(* A second candidate: the total singlevalued realizable functions *)
Notation "F 'is_realizer_of' f" := (is_realizer F f) (at level 2).
Arguments is_realizer {X Y}.

Definition is_prim_rec (X Y : rep_space) (f : space X -> space Y) :=
  exists F, is_realizer F f.
Notation "f 'is_primitive_recursive'" := (is_prim_rec f) (at level 2).

Notation "X ~> Y" := (nat -> (names X) -> (questions Y) -> answers Y) (format "X ~> Y", at level 2).
(* I think about this type as a type of machines: For M : B ~> B' I "read M s n = nothing" as
"the Machine can't say anything about the return value yet" and "M s n = some t" as "after n
steps the machine considers t to be the best answer". Since no assumption about concurrency
have been made, in general a machine will produce an infinite list of return values. *)

Definition eval (X Y : rep_space) (M : X ~> Y) : ((names X) ->> (names Y)) :=
  fun (phi : names X) (psi : names Y) => forall (a : questions Y), exists n, M n phi a = psi a.
(* if M is a machine then eval M is the function the machine computes. Since no assumptions
about convergence or concurrency have been made, the computed multivalued function need
neither be singlevalued nor total. *)
