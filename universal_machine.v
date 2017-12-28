(* This file is supposed to contain the definition of a universal machine and the proof
that the machine is actually universal. The universal machine is a machine of type two
and it should work for any continuous function from B -> B. Usually B is the Baire space,
here, i.e. the set of all mappings from strings to strings. However, since I don't want
to rely on a handwritten type of strings as I attempted in the file "operators.v" I use
more generaly a space S -> T as substitute for B. *)
Load functions.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicits Defensive.

Fixpoint equal_on (S T : Type) (phi psi : S -> T) (L : list S) :=
  match L with
    | nil => True
    | cons s K => (phi s = psi s) /\ (equal_on phi psi K)
  end.
Notation "phi 'and' psi 'coincide_on' L" := (equal_on phi psi L) (at level 2).

Definition is_cont (S T S' T' : Type) (F : (S -> T) ->> (S'-> T')) :=
      forall phi (s': S'), exists (L : list S), forall psi, phi and psi coincide_on L ->
          forall Fphi Fpsi : S' -> T', F phi Fphi -> F psi Fpsi -> Fphi s' = Fpsi s'.
Notation "F 'is_continuous'" := (is_cont F) (at level 2).

Require Import FunctionalExtensionality.
Lemma cont_to_sing (S T S' T' : Type) F: @is_cont S T S' T' F -> F is_single_valued.
Proof.
  move => cont phi psi psi' [psivphi psi'vphi].
  apply functional_extensionality => a.
  move: cont (cont phi a) => _ [L] cont.
  have: (forall K, phi and phi coincide_on K).
  by elim.
  move => equal.
  by apply: (cont phi (equal L) psi psi').
Qed.

Definition iscont (S T S' T': Type) (F: (S-> T) -> S' -> T') :=
  forall phi (s': S'), exists (L : list S), forall psi,
    phi and psi coincide_on L -> F phi s' = F psi s'.

Lemma continuity S T S' T' (F: (S-> T) -> S' -> T') :  iscont F <-> is_cont (F2MF F).
Proof.
  split.
  - move => cont phi s'.
    move: cont (cont phi s') => _ [L cond].
    exists L => psi coin Fphi Fpsi iv iv'.
    rewrite -iv -iv'.
    by apply (cond psi).
  - move => cont phi s'.
    move: cont (cont phi s') => _ [L cond].
    exists L => psi coin. 
    by apply: (cond psi coin (F phi) (F psi)).
Qed.

Fixpoint U' (S T S' T' : Type) n (psi: S' * list T -> S + T') (phi: S -> T) (L: S' * list T) :=
match n with
  | 0 => None
  | S n => match psi L with
    | inr c => Some c
    | inl c => U' n psi phi (L.1, cons (phi c) L.2)
  end
end.

Definition U (S T S' T' : Type) n (psi: S' * list T -> S + T') (phi: S -> T) a :=
U' n psi phi (a,nil).
(* This is what I want to prove to be a universal machine. *)

Lemma U_is_universal S T S' T' (F:(S -> T) ->> (S' -> T')):
  (exists s: S, True) -> F is_continuous ->
    exists psi, forall phi Fphi, F phi Fphi -> forall a, exists n, U n psi phi a = Some (Fphi a).
Proof.
  move => [s _] cont.
Admitted.