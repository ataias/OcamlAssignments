(*
Name: Ataias Pereira Reis & ID: 260590875
Name: Ahmad Saif & ID: 260329527

"We certify that both partners contributed equally to the work
submitted here and that it represents solely our own efforts"*)

open Type
module M = Minml
open Unify

type context = Ctx of (M.name * tp) list

let empty = Ctx []

exception Unimplemented
exception NotFound

(*gets the type of a certain name given a list *)
let rec assoc x y = match y with
  | [] -> raise NotFound
  | (z, r)::rest -> if x = z then r else assoc x rest

(*Looks in a context and gets the type of the name*)
let rec lookup ctx x = let Ctx list = ctx in assoc x list

(*Adds an element to a context*)
let extend ctx (x, v) = let Ctx list = ctx in Ctx ((x,v)::list)

(*Adds several elements to a context*)
let rec extend_list ctx l = match l with
  | [] -> ctx
  | (x,y) :: pairs -> extend_list (extend ctx (x, y)) pairs

exception TypeError of string

let fail message = raise (TypeError message)

let primopType p = match p with
  | M.Equals   -> Arrow(Product[Int; Int], Bool)
  | M.LessThan -> Arrow(Product[Int; Int], Bool)
  | M.Plus     -> Arrow(Product[Int; Int], Int)
  | M.Minus    -> Arrow(Product[Int; Int], Int)
  | M.Times    -> Arrow(Product[Int; Int], Int)
  | M.Negate   -> Arrow(Int, Int)

and  primopOutput p = match p with
  | M.Equals   -> Bool
  | M.LessThan -> Bool
  | M.Plus     -> Int
  | M.Minus    -> Int
  | M.Times    -> Int
  | M.Negate   -> Int

and primopInput p = match p with
  | M.Equals   -> [Int; Int]
  | M.LessThan -> [Int; Int]
  | M.Plus     -> [Int; Int]
  | M.Minus    -> [Int; Int]
  | M.Times    -> [Int; Int]
  | M.Negate   -> [Int]

(* Question 3. *)
let msg = "Expression does not typecheck"
let get y = match y with |Some Arrow(x,y) -> x |Some k -> k  |None -> fail "No annotation";;
let takeOutSome y = match y with |Some k -> k | None -> fail "Problem";;
(* infer : context -> M.exp -> tp  *)
let isFunction f = match f with |Arrow(x,y) -> true | _ -> false;;
let checkArrow a = match a with |Arrow(x,y) -> (x,y) |_ -> fail msg;;
let checkProduct p = match p with |Product list -> list |_ -> fail msg;;
(*Basic cases examples
1) Working
let exp = Top.parse "2+2;";;
Typecheck.infer Typecheck.empty exp;; 
2) Works for if-cases
3) 
*)
let rec infer ctx exp = match exp with
  | M.Var y -> lookup ctx y
  | M.Int n -> Int
  | M.Bool b -> Bool
  | M.If(e, e1, e2) -> if (infer ctx e)=Bool 
                     then (let (x,y) = (infer ctx e1, infer ctx e2) in 
			   if x = y then x else fail msg)
		     else fail msg
  | M.Primop (po, args) -> if (primopInput po) = (List.map (fun s->infer ctx s) args) then primopOutput po else fail msg
  | M.Tuple exps -> Product (List.map (fun x -> infer ctx x) exps)
  | M.Fn (x, t, e) -> if(t!=None) then let tp = takeOutSome(t) in infer (extend ctx (x,tp)) e else fail msg 
  | M.Rec (x, t, e) -> let fT = get t in infer (extend ctx (x,fT)) e
  | M.Let ([M.Val(M.Rec(x,t,e), name)], exp) -> let fT = takeOutSome(t) in let typeE = (infer (inferdec (extend ctx (name, fT)) []) e) in let (x,y) = checkArrow (takeOutSome t) in if typeE = y then infer (inferdec (extend ctx (name, fT)) []) exp else fail msg
  | M.Let (decs, e2) -> infer (inferdec ctx decs) e2
  | M.Apply (e1, e2) -> if isFunction (infer ctx e1) then (let funT = infer ctx e1 in let argT = infer ctx e2 in let (iT,oT) = checkArrow(funT) in if iT = argT then oT else fail msg) else fail msg
  | M.Anno (e, t) -> if (infer ctx e) = t then t else fail msg 

and inferdec ctx dec = match dec with 
  | [] -> ctx
  | M.Val(exp,name)::tl -> inferdec (extend ctx (name, infer ctx exp)) tl 
  | M.Valtuple(exp,names)::tl -> let list = checkProduct(infer ctx exp) in inferdec (extend_list ctx (List.map2 (fun x y -> (x,y)) names list)) tl
  | M.ByName(exp,name)::tl -> inferdec (extend ctx (name, infer ctx exp)) tl 
