%{
package desel

import (
    "os"
    "strings"
)

type Node struct{
    category int
    values   []interface{}
    tokens   []Tokens
}

const (                   // tokens
    N_comment = iota      // []
    N_set_definition      // [name, has_homonymous, elements]
    N_element_definition  // [name, has_homonymous, sets]
    N_sets_definition     // [sets]
    N_elements_definition // [elements]
    N_not                 // [set or element]
    N_and                 // [set, set]
    N_or                  // [set, set]
    N_minus               // [expression]
    N_set                 // [name]
    N_element             // [name]
)
%}

%union{
    token Token
    expr  Expression
}

%type<expr> statements
%type<expr> statement
%type<expr> expression
%type<expr> expression-and
%type<expr> expression-min
%type<expr> wrapped-expression
%token<token> T_comment
%token<token> T_whitespaces
%token<token> T_pre_set
%token<token> T_pre_element
%token<token> T_label
%token<token> T_lparen
%token<token> T_rparen
%token<token> T_and
%token<token> T_minus
%token<token> T_not
%token<token> T_newline

%%

statements  : statements statement
    {
        $$ = append($1, $2)
    }
            |
    {
        $$ = []Token{}
    }
statement   : set-definition
            | element-definition
            | sets-definition 
            | elements-definition 
            | comment
    {
        $$ = $1
    }

/*
expression  : T_not T_whitespaces {
                $$ = Not { 
            }

expression = opt-not-ws, wrapped-expression;
           | expression-and, { ( ws, minus, ws | wws ), expression-and };
expression-and = expression-min, { ws, and, ws, expression-min };
expression-min = set-with-prefix-opt-not;
wrapped-expression = "(", ws, expression, ws, ")";
*/

eol : T_comment T_newline
    {
        $$ = []Token{$1}
    }
            | T_newline
    {
        $$ = []Token{}
    }

homonymous-element  : T_whitespaces T_pre_element T_whitespaces
    { $$ = []Token{}{$1, $2, $3} }
                    | T_pre_element T_whitespaces
    { $$ = []Token{}{$1, $2} }
                    |
    { $$ = []Token{}{} }

set-definition  : T_pre_set T_label homonymous-element set-definition-items eol
                    additional-set-definitions
    { // has homonymous element
        $$ = Node {
            N_set_definition,
            []interface{}{$2, len($3) != 1, $4},
            append([]Token{$1, $2}, append($3, []Token{$4, $5}...)...),
        }
    }

additional-set-definitions  : T_pre_set T_whitespaces set-definition-items eol
    {
    }
                            : eol

set-definition-items    : set-definition-items T_whitespaces set-definition-item
    {
        $$ = append($1, $2, $3)
    }
                        |
    {
        $$ = []Node{}
    }

set-definition-item :

set-definition = set-with-prefix, [ homonymous-element ],
                 { wws, set-definition-item }, inline-comment, ws-newline,
                 { comment | additional-set-definition, inline-comment, ws-newline };
set-definition-item = element-with-opt-not, homonymous-set
                    | expression;

element-definition = element-with-prefix, [ homonymous-set ],
                     { wws, element-definition-item, }, inline-comment, ws-newline,
                     { comment | additional-element-definition, inline-comment, ws-newline };
additional-element-definition = prefix-of-element, { wws, element-definition-item };
element-definition-item = set-with-opt-not;

sets-definition = 2 * prefix-of-set,
                  { wws, sets-definition-item },
                  inline-comment, ws-newline;
sets-definition-item = set, [ homonymous-element ],
                       { wws, ( element-with-prefix-and-opt-not | wrapped-expression ) };

elements-definition = 2 * prefix-of-element,
                      { wws, elements-definition-item },
                      inline-comment, ws-newline;
elements-definition-item = element, [ homonymous-set ],
                           { wws, set-with-prefix-and-opt-not };

homonymous-set = ws, prefix-of-set;
homonymous-element = ws, prefix-of-element;

set = [ prefix-of-set ], label;
element = [ prefix-of-element ], label;
set-with-prefix = prefix-of-set, label;
element-with-prefix = prefix-of-element, label;
set-with-opt-not = set-with-prefix-and-opt-not
                 | label-with-opt-not;
set-with-prefix-and-opt-not = opt-not-ws, element-with-prefix;
element-with-opt-not = element-with-prefix-and-opt-not
                     | label-with-opt-not;
element-with-prefix-and-opt-not = opt-not-ws, element-with-prefix;
label-with-opt-not = opt-not-ws, wrapped-label
                   | opt-not-wws, label;
label = label-characters | wrapped_label;
wrapped-label = '"', utf-characters, '"'
              | "'", utf-characters, "'";
inline-comment = ws, prefix-of-inline-comment, utf-characters;
comment = prefix-of-comment, utf-characters, newline;

%%

func Parse(tokens []Token) (Node, error) {
}
