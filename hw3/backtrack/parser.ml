(*
Name: Ataias Pereira Reis & ID: 260590875
Name: Ahmad Saif & ID: 260329527

"We certify that both partners contributed equally to the work
submitted here and that it represents solely our own efforts"*)

module  Parser : PARSER = 
struct

(* In this exercise, you implement a  parser for a
 simple context free grammar using exceptions. The grammar parses arithmetic
 expressions with +,*, and ()'s.  The n represents an integer and is a
 terminal symbol. Top-level start symbol for this grammar is E.  

E -> S;
S -> P + S | P   % P = plus sub-expressions
P -> A * P | A   % A = arithmetic expression, 
A -> n | (S)


Expressions wil be lexed into a list of tokens of type Token shown
 below. The parser's job is to translate this list into an abstract
 syntax tree, given by type Exp also shown below. 

*)

module L = Lexer

type exp = Sum of exp * exp | Prod of exp * exp | Int of int

(* Success exceptions *)
(* SumExpr (S, toklist') : 
    Indicates that we successfully parsed a list of tokens called toklist
   into an S-Expression S and a remaining list of tokens called toklist'
   toklist' is what remains from toklist after we peeled of all the tokens
   necessary to build the S-Expression S.
 *)

exception SumExpr of exp * L.token list

(* ProdExpr (S, toklist') : 
    Indicates that we successfully parsed a list of tokens called toklist
   into an P-Expression P and a remaining list of tokens called toklist'
   toklist' is what remains from toklist after we peeled of all the tokens
   necessary to build the P-Expression P.
 *)

exception ProdExpr of exp * L.token list
(* AtomicExpr (A, toklist') : 
    Indicates that we successfully parsed a list of tokens called toklist
   into an A-Expression A and a remaining list of tokens called toklist'
   toklist' is what remains from toklist after we peeled of all the tokens
   necessary to build the A-Expression A.
 *)

exception AtomicExpr of exp * L.token list

(* Indicating failure to parse a given list of tokens *)

 exception Error of string

(* Example: 
   parse [INT(9),PLUS,INT(8),TIMES,INT(7),SEMICOLON]
   ===> Sum(Int 9, Prod (Int 8, Int 7))

   Example of what the Lexer.lex outputs

# Lexer.lex "(2 + 3) * 4;";;
- : Lexer.token list =
[Lexer.LPAREN; Lexer.INT 2; Lexer.PLUS; Lexer.INT 3; Lexer.RPAREN;
 Lexer.TIMES; Lexer.INT 4; Lexer.SEMICOLON]
#

# Parser.parse "(2 + 3) * 4;";;
- : Parser.exp =
Parser.Prod (Parser.Sum (Parser.Int 2, Parser.Int 3), Parser.Int 4)
#

# Lexer.lex  "9 + 8 * (4 + 7);";;
- : Lexer.token list =
[Lexer.INT 9; Lexer.PLUS; Lexer.INT 8; Lexer.TIMES; Lexer.LPAREN;
 Lexer.INT 4; Lexer.PLUS; Lexer.INT 7; Lexer.RPAREN; Lexer.SEMICOLON]

 # Lexer.lex "9 + 8;";;
- : Lexer.token list =
[Lexer.INT 9; Lexer.PLUS; Lexer.INT 8; Lexer.SEMICOLON]

*)

 exception NotImplemented 
let rec parseExp toklist = match toklist with
   | [] -> raise (Error "Expected Expression: Nothing to parse")
   | tlist ->  
    try parseSumExp tlist with 
      | NotImplemented -> raise NotImplemented
      | SumExpr (exp, L.RPAREN::tl) -> raise (AtomicExpr(exp,tl))
      | SumExpr (exp, [L.SEMICOLON]) -> exp
      | Error msg -> raise (Error msg)
      | _ -> raise (Error "Error: Expected Semicolon")

 and parseSumExp toklist = match toklist with
 | [] -> raise (Error "Expected Expression: Nothing to parse in parseSumExp")

 |toklist -> try parseProdExp toklist with   
             |ProdExpr(exp,tlist) -> 
	       match tlist with 
               |L.PLUS::tl -> (try parseSumExp tl
                              with 
			      |SumExpr(r_exp,r_tlist) -> 
			        raise (SumExpr((Sum (exp,r_exp)),r_tlist)))
	       |_ -> raise (SumExpr(exp,tlist))  	      
             	 
 and parseProdExp toklist = match toklist with
 | [] -> raise (Error "Expected Expression: Nothing to parse in parseProdExp")
 |toklist -> try parseAtom toklist with 
             |AtomicExpr(exp,tlist) -> 
	       match tlist with 
               |L.TIMES::tl -> (try parseProdExp tl 
                                with
			        |ProdExpr(r_exp,r_tlist) ->
                                  raise (ProdExpr((Prod (exp,r_exp)),r_tlist)))    
	       |_ -> raise (ProdExpr (exp,tlist))
             
	      
 and parseAtom toklist =  match toklist with
 | [] -> raise (Error "Expected Expression: Nothing to parse in parseAtom") 
 | L.INT x::tl -> raise (AtomicExpr((Int x),tl))
 | L.LPAREN::tl -> parseExp tl
 |_ -> raise (Error "Not Int x or LPAREN in parseAtom")

let parse string  = parseExp (L.lex string)

end


