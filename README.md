# BNF
## An EBNF parser written in the Swift programming language.

The BNF description (syntax description) of the grammar:
``
Syntax       : { Grammar | Tokens | Productions } ;
Grammar      : 'grammar' Identifier ';' ;
Tokens       : 'tokens' '{' { Identifier ':' Literal } '}' ;
Productions  : 'productions' '{' { Production } '}' ;
Production   : Identifier ':' Expression ';' ;
Expression   : Term { "|" Term } ;
Term         : Factor { Factor } ;
Factor       : Identifier
                            | Literal
                            | "[" Expression "]"
                            | "(" Expression ")"
                            | "{" Expression "}"
                            | "{:" CODE_STRING ":}" ;
Identifier    : letter { letter | "_" | "-" } ;
Literal       : """" character { character } """"
                            | "'" character { character } "'" ;
``
The alphabet of the `Literal` is currently limited to ASCII characters.
This grammar definition is very close to the BNF grammar definition given
by Niklaus Wirth [1], which resembles the EBNF definition [2] very closely.

Punctuation characters are: '|', "[", "]", "(", ")" "{:", ":}".

References:
[1] https://en.wikipedia.org/wiki/Wirth_syntax_notation
[2] https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form

A simple grammar definition may look something like the example below:

``
grammar lr_dragon;
tokens {
    id : "[a-zA-Z]+"
}
productions {
    E     : E '+' T | T ;
    T     : T '*' F | F ;
    F     : '(' E ')' | 'id' ;
}
``
