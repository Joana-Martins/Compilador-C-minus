
%output "parser.c"
%defines "parser.h"
%define parse.error verbose
%define parse.lac full
%define parse.trace

%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "ast.h"
#include "parser.h"
#include "tables.h"

int yylex();
void yyerror(const char *s);

AST* new_var(int size);
AST* check_var();

AST* new_func();
AST* add_params(AST* id, AST* params);

AST* new_fcall();
void add_args(AST* fcnode, AST* args);

extern int yylineno;
extern char id_copy[64];

LitTable *lt;
VarTable *vt;
FuncTable *ft;

AST *ast;
int scope;
%}

%define api.value.type {AST*}

%token ELSE IF INPUT INT OUTPUT RETURN VOID WHILE WRITE
%token SEMI COMMA LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE
%token ASSIGN
%token LT LE GT GE EQ NEQ

%token NUM
%token ID
%token STRING

%left PLUS MINUS
%left TIMES OVER

%start program

%%

program:
  func_decl_list    { ast = $1; }
;

func_decl_list:
  func_decl_list func_decl  { add_child($1, $2); $$ = $1; }
| func_decl                 { $$ = new_subtree(FUNC_LIST_NODE, 1, $1); }
;

func_decl:
  func_header func_body     { $$ = new_subtree(FUNC_DECL_NODE, 2, $1, $2); scope++; }
;

func_header:
  ret_type ID { $2 = new_func(); } LPAREN params RPAREN { $$ = add_params($2, $5); }
;

func_body:
  LBRACE opt_var_decl opt_stmt_list RBRACE  { $$ = new_subtree(FUNC_BODY_NODE, 2, $2, $3); }
;

opt_var_decl:
  %empty            { $$ = new_subtree(VAR_LIST_NODE, 0); }
| var_decl_list     { $$ = $1; }
;

opt_stmt_list:
  %empty        { $$ = new_subtree(BLOCK_NODE, 0); }
| stmt_list     { $$ = $1; }
;

ret_type:
  INT       { }
| VOID      { }
;

params:
  VOID          { $$ = new_node(PARAM_LIST_NODE, 0); }
| param_list    { $$ = $1; }
;

param_list:
  param_list COMMA param    { add_child($1, $3); $$ = $1; }
| param                     { $$ = new_subtree(PARAM_LIST_NODE, 1, $1); }
;

param:
  INT ID                { $$ = new_var(0); }
| INT ID LBRACK RBRACK  { $$ = new_var(-1); }
;

var_decl_list:
  var_decl_list var_decl    { add_child($1, $2); $$ = $1; }
| var_decl                  { $$ = new_subtree(VAR_LIST_NODE, 1, $1); }
;

var_decl:
  INT ID SEMI                       { $$ = new_var(0); }
| INT ID LBRACK NUM RBRACK SEMI     { $$ = new_var(get_data($4)); free($4); }
;

stmt_list:
  stmt_list stmt    { add_child($1, $2); $$ = $1; }
| stmt              { $$ = new_subtree(BLOCK_NODE, 1, $1); }
;

stmt:
  assign_stmt       { $$ = $1; }
| if_stmt           { $$ = $1; }
| while_stmt        { $$ = $1; }
| return_stmt       { $$ = $1; }
| func_call SEMI    { $$ = $1; }
;

assign_stmt:
  lval ASSIGN arith_expr SEMI   { $$ = new_subtree(ASSIGN_NODE, 2, $1, $3); }
;

id_var:
    ID { $$ = check_var(); }
;

lval:
  id_var                    { $$ = $1; }
| id_var LBRACK NUM RBRACK  { add_child($1, $3); $$ = $1; }
| id_var LBRACK ID { $3 = check_var(); } RBRACK { add_child($1, $3); $$ = $1; }
;

if_stmt:
  IF LPAREN bool_expr RPAREN block              { $$ = new_subtree(IF_NODE, 2, $3, $5); }
| IF LPAREN bool_expr RPAREN block ELSE block   { $$ = new_subtree(IF_NODE, 3, $3, $5, $7); }
;

block:
  LBRACE opt_stmt_list RBRACE   { $$ = $2; }
;

while_stmt:
  WHILE LPAREN bool_expr RPAREN block   { $$ = new_subtree(WHILE_NODE, 2, $3, $5); }
;

return_stmt:
  RETURN SEMI               { $$ = new_subtree(RETURN_NODE, 0); }
| RETURN arith_expr SEMI    { $$ = new_subtree(RETURN_NODE, 1, $2); }
;

func_call:
  output_call       { $$ = $1; }
| write_call        { $$ = $1; }
| user_func_call    { $$ = $1; }
;

input_call:
  INPUT LPAREN RPAREN   { $$ = new_subtree(INPUT_NODE, 0); }
;

output_call:
  OUTPUT LPAREN arith_expr RPAREN   { $$ = new_subtree(OUTPUT_NODE, 1, $3); }
;

write_call:
  WRITE LPAREN STRING RPAREN        { $$ = new_subtree(WRITE_NODE, 1, $3); }
;

user_func_call:
  ID { $1 = new_fcall(); } LPAREN opt_arg_list RPAREN { add_args($1, $4); $$ = $1; }
;

opt_arg_list:
  %empty        { $$ = new_subtree(ARG_LIST_NODE, 0); }
| arg_list      { $$ = $1; }
;

arg_list:
  arg_list COMMA arith_expr     { add_child($1, $3); $$ = $1; }
| arith_expr                    { $$ = new_subtree(ARG_LIST_NODE, 1, $1); }
;

bool_expr:
  arith_expr LT arith_expr      { $$ = new_subtree(LT_NODE, 2, $1, $3); }
| arith_expr LE arith_expr      { $$ = new_subtree(LE_NODE, 2, $1, $3); }
| arith_expr GT arith_expr      { $$ = new_subtree(GT_NODE, 2, $1, $3); }
| arith_expr GE arith_expr      { $$ = new_subtree(GE_NODE, 2, $1, $3); }
| arith_expr EQ arith_expr      { $$ = new_subtree(EQ_NODE, 2, $1, $3); }
| arith_expr NEQ arith_expr     { $$ = new_subtree(NEQ_NODE, 2, $1, $3); }
;

arith_expr:
  arith_expr PLUS arith_expr    { $$ = new_subtree(PLUS_NODE, 2, $1, $3); }
| arith_expr MINUS arith_expr   { $$ = new_subtree(MINUS_NODE, 2, $1, $3); }
| arith_expr TIMES arith_expr   { $$ = new_subtree(TIMES_NODE, 2, $1, $3); }
| arith_expr OVER arith_expr    { $$ = new_subtree(OVER_NODE, 2, $1, $3); }
| LPAREN arith_expr RPAREN      { $$ = $2; }
| lval                          { $$ = $1; }
| input_call                    { $$ = $1; }
| user_func_call                { $$ = $1; }
| NUM                           { $$ = $1; }
;

%%

AST* new_var(int size) {
    int lk_idx = lookup_var(vt, id_copy, scope);
    if (lk_idx == -1) {
        int vt_idx = add_fresh_var(vt, id_copy, yylineno, scope, size);
        AST* vnode = new_node(VAR_DECL_NODE, vt_idx);
        return vnode;
    } else {
        fprintf(stderr,
            "SEMANTIC ERROR (%d): variable '%s' already declared at line %d.\n",
            yylineno, id_copy, get_var_line(vt, lk_idx));
        exit(1);
    }
}

AST* check_var() {
    int lk_idx = lookup_var(vt, id_copy, scope);
    if (lk_idx != -1) {
        return new_node(VAR_USE_NODE, lk_idx);
    } else {
        fprintf(stderr, "SEMANTIC ERROR (%d): variable '%s' was not declared.\n",
            yylineno, id_copy);
        exit(1);
    }
}


AST* new_func() {
    int lk_idx = lookup_func(ft, id_copy);
    if (lk_idx == -1) {
        int ft_idx = add_fresh_func(ft, id_copy, yylineno);
        return new_node(FUNC_NAME_NODE, ft_idx);
    } else {
        fprintf(stderr,
            "SEMANTIC ERROR (%d): function '%s' already declared at line %d.\n",
            yylineno, id_copy, get_func_line(ft, lk_idx));
        exit(1);
    }
}

AST* add_params(AST* id, AST* params) {
    set_func_arity(ft, get_data(id), get_child_count(params));
    return new_subtree(FUNC_HEADER_NODE, 2, id, params);
}

AST* new_fcall() {
    int lk_idx = lookup_func(ft, id_copy);
    if (lk_idx != -1) {
        return new_node(FUNC_CALL_NODE, lk_idx);
    } else {
        fprintf(stderr, "SEMANTIC ERROR (%d): function '%s' was not declared.\n",
            yylineno, id_copy);
        exit(1);
    }
}

void add_args(AST* fcnode, AST* args) {
    int fidx = get_data(fcnode);
    int farity = get_func_arity(ft, fidx);
    int arg_count = get_child_count(args);
    if (arg_count == farity) {
        add_child(fcnode, args);
    } else {
        fprintf(stderr,
        "SEMANTIC ERROR (%d): function '%s' was called with %d arguments but declared with %d parameters.\n",
        yylineno, get_func_name(ft, fidx), arg_count, farity);
        exit(1);
    }
}

// Error handling.
void yyerror (char const *s) {
    fprintf(stderr, "PARSE ERROR (%d): %s\n", yylineno, s);
    exit(1);
}

// Main.
int main() {
    yydebug = 0; // Toggle this variable to enter debug mode.

    // Initialization of tables before parsing.
    lt = create_lit_table();
    vt = create_var_table();
    ft = create_func_table();
    scope = 0;

    if (yyparse() == 0) {
        fprintf(stderr, "PARSE SUCCESSFUL!\n\n");
        print_dot(ast);
        print_lit_table(lt); fprintf(stderr, "\n\n");
        print_var_table(vt); fprintf(stderr, "\n\n");
        print_func_table(ft);
    }

    free_lit_table(lt);
    free_var_table(vt);
    free_func_table(ft);
    free_tree(ast);

    return 0;
}

