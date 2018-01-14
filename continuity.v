(* This file provides a definition of continuity of functions between spaces of the form
Q -> A for some arbitrary types Q and A. It also proves some basic Lemmas about this notion.*)
Load functions.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicits Defensive.

Section CONTINUITY_DEFINITION.
Context (Q I Q' I' : Type).
(* Q is for questions, I is for information*)
Notation B := (Q -> I).
Notation B' := (Q' -> I').
(* B is for Baire space. B should be thought of as a language: An element of B is a - not
neccessarily meaningful - conversation: when a question q: Q, is asked in such a conversation,
some information phi(q): I is returned as answer. Usually the questions and answers can be
encoded as natural numbers, which will give the usual Baire space nat->nat. *)

(* Two conversations phi and psi coincide on a list L of questions about the object, if they
give the same answers for any question that is included in L. *)
Fixpoint equal_on (phi psi: B) L :=
  match L with
    | nil => True
    | cons s K => (phi s = psi s) /\ (equal_on phi psi K)
  end.
Notation "phi 'and' psi 'coincide_on' L" := (equal_on phi psi L) (at level 2).

(* The set of meaningful conversations in a language is a subset of the Baire space corre-
sponding to that language. For instance if one is given a dictionary, that asigns to each
pair of a question q and am answer i a property P on an abstract space X, i.e. a set of objects
x such that i a valid answer to the question q about x, one may consider the subset of all
conversations that are descriptions of an object in the sense that they do not provide any
contradictory information and uniquely identify an abstract object *)

Context (F: B ->> B').
(* F is a multivalued function and a good example of such a function is a translation between
dictionaires. I.e. the case where (dom F) and (range F) are generated by some dictionaries D
and D' and for a description phi of x according to D, the set F(phi) consists of all valid
descriptions x with respect to the dictionary D'. *)

(* Such a translation is continuous if for each question about an object in the second
language, an answer can be found from a dscription in the first language by asking a finite
number of questions. *)
Definition is_cont :=
  forall phi q', exists L, forall psi, phi and psi coincide_on L ->
  	 forall Fphi, F phi Fphi -> forall Fpsi, F psi Fpsi ->
  	 	Fphi q' = Fpsi q'.

Definition is_mod (F:B ->> B') mf :=
  forall phi q', forall (psi : B), phi and psi coincide_on (mf phi q') ->
  	forall Fphi : B', F phi Fphi -> (forall Fpsi, F psi Fpsi -> Fphi q' = Fpsi q').
End CONTINUITY_DEFINITION.

Notation "phi 'and' psi 'coincide_on' L" := (equal_on phi psi L) (at level 2).
Notation "F 'is_continuous'" := (is_cont F) (at level 2).
Notation "mf 'is_modulus_of' F" := (is_mod F mf) (at level 2).

Section CONTINUITY_LEMMAS.
Context (Q I Q' I' : Type).
Notation B := (Q -> I).
Notation B' := (Q' -> I').

Lemma coin_ref (phi: B):
	forall L, phi and phi coincide_on L.
Proof.
	by elim.
Qed.

Lemma app_coincide L K (phi psi: B):
	phi and psi coincide_on (L ++ K) <-> (phi and psi coincide_on L /\ phi and psi coincide_on K).
Proof.
split.
	move: L.
	elim.
		by replace (nil ++ K) with (K); split.
	move => a L ih.
	replace ((a :: L) ++ K) with ((a :: L)%SEQ ++ K)%list by trivial.
	rewrite -(List.app_comm_cons L K a).
	move => [ass1 ass2].
	split; try apply ih; try apply ass2.
	by split => //; apply ih; apply ass2.
move: L.
elim.
	move => [_ coin].
	by replace (nil ++ K) with (K).
move => a L ih [[ass1 ass2] ass3].
replace ((a :: L) ++ K) with ((a :: L)%SEQ ++ K)%list by trivial.
rewrite -(List.app_comm_cons L K a).
by split; try apply ih; try apply ass2.
Qed.

Lemma continuous_extension (F G: B ->> B'):
	G tightens F -> G is_continuous -> F is_single_valued -> F is_continuous.
Proof.
move => GeF Gcont Fsing phi q'.
move: (Gcont phi q') => [] L Lprop.
exists L => psi pep Fphi FphiFphi Fpsi FpsiFpsi.
move: GeF (@tightening_of_single_valued B B' F G Fsing GeF) => _ GeF.
apply: (Lprop psi pep Fphi _ Fpsi _).
	by apply: (GeF phi Fphi).
by apply: (GeF psi Fpsi).
Qed.

Require Import FunctionalExtensionality.

Lemma cont_to_sing (F: B ->> B'):
	F is_continuous -> F is_single_valued.
Proof.
move => cont phi Fpsi Fpsi' v1 v2.
apply functional_extensionality => a.
move: cont (cont phi a) => _ [L] cont.
have: (forall K, phi and phi coincide_on K) by elim.
move => equal.
by rewrite -((cont phi (equal L) Fpsi') v2).
Qed.
End CONTINUITY_LEMMAS.

Section CONTINUITY_LEMMAS_CLASSICAL_CHOICE.
Require Import ClassicalChoice.
Context (Q I Q' I' Q'' I'' : Type).
Notation B := (Q -> I).
Notation B' := (Q' -> I').
Notation B'' := (Q'' -> I'').

Lemma exists_modulus (F: B ->> B'):
	F is_continuous -> exists mf, mf is_modulus_of F.
Proof.
move => cont.
set R:= fun phiq L => forall psi, phiq.1 and psi coincide_on L -> forall Fphi, F phiq.1 Fphi -> 
	(forall Fpsi, F psi Fpsi -> Fphi phiq.2 = Fpsi phiq.2).
have: forall phiq, exists L, R phiq L.
	move => [phi q'].
	move: (cont phi q') => [L] prop.
	exists L.
		move => psi H.
	 	by apply (prop psi H).
move => cond.
move: cond (choice R cond) => _ [mf] cond.
exists (fun phi q => mf (phi, q)).
move => phi q.
by apply (cond (phi, q)).
Qed.

Lemma continuous_composition (F: B ->> B') (G: B' ->> B''):
		F is_continuous -> G is_continuous -> G o F is_continuous.
Proof.
move => Fcont Gcont.
move => phi q''.
move: (exists_modulus Fcont) => [mf] ismod.
case (classic (exists Fphi, F phi Fphi)).
	move => [] Fphi FphiFphi.
	set gather := fix gather K := match K with
		| nil => nil
		| cons q' K' => app (mf phi q') (gather K')
	end.
	move: (Gcont Fphi q'') => [L] Lprop.
	exists (gather L).
	move => psi.
	case: (classic (exists Fpsi, F psi Fpsi)).
		move => [] Fpsi FpsiFpsi coin GFphi [] [] Fphi' [] FphiFphi' GFphi'GFphi cond'.
		have: Fphi and Fpsi coincide_on L.
			specialize (Lprop Fpsi).
			move: L Fphi FphiFphi Fpsi FpsiFpsi Lprop coin .
			elim=> //.
			move => a L ih Fphi FphiFphi Fpsi FpsiFpsi assump coin.
			move: coin ((app_coincide (mf phi a) (gather L) phi psi).1 coin) => _ [coin1 coin2].
			split.
				by apply: (ismod phi a psi) => //.
			apply ih => //.
			move => coin'.
			apply assump.
			split.
				by apply (ismod phi a psi).
			done.
		move => coin' GFpsi [] [] Fpsi' [] FpsiFpsi' GFpsi'GFpsi cond.
		apply (Lprop Fpsi) => //.
		rewrite ((cont_to_sing Fcont) phi Fphi Fphi') => //.
		rewrite ((cont_to_sing Fcont) psi Fpsi Fpsi') => //.
	move => false coin a b c [][]Fpsi [] FpsiFpsi .
	exfalso; apply false.
	by exists Fpsi.
move => false.
exists nil.
move => a b c [][] Fphi [] FphiFphi.
exfalso; apply false.
by exists Fphi.
Qed.
End CONTINUITY_LEMMAS_CLASSICAL_CHOICE.