
%option outfile="scanner.c"
%option noyywrap
%option nounput
%option noinput
%option yylineno

%{
#include <stdio.h>
#include "ast.h"
#include "parser.h"
#include "tables.h"

extern LitTable *lt;

#define ID_SIZE 64
char id_copy[ID_SIZE];

void yyerror(const char *s);

#define process_token(type) return type

#define process_id() \
    for (int i = 0; i < ID_SIZE; i++) id_copy[i] = 0; \
    strcpy(id_copy, yytext)

%}

number      [0-9]+
identifier  [a-zA-Z][0-9a-zA-Z]*
string      \"[^"]*\"
ignore      [ \t\n]+

/* Single line comments */
SLC         "//"[^\n]*\n
/* Multi-line comments */
%x          MLC

%%

"/*"            { BEGIN(MLC); } /* Enter special state. */
<MLC>"*/"       { BEGIN(INITIAL); } /* Go back to normal state. */
<MLC>.|\n       { } /* Ignore everything that is inside a comment. */

{ignore}        { } /* Eat up whitespace. */
{SLC}           { }

"else"          { process_token(ELSE); }
"if"            { process_token(IF); }
"input"         { process_token(INPUT); }
"int"           { process_token(INT); }
"output"        { process_token(OUTPUT); }
"return"        { process_token(RETURN); }
"void"          { process_token(VOID); }
"while"         { process_token(WHILE); }
"write"         { process_token(WRITE); }

"+"             { process_token(PLUS); }
"-"             { process_token(MINUS); }
"*"             { process_token(TIMES); }
"/"             { process_token(OVER); }

"<"             { process_token(LT); }
"<="            { process_token(LE); }
">"             { process_token(GT); }
">="            { process_token(GE); }
"=="            { process_token(EQ); }
"!="            { process_token(NEQ); }

"="             { process_token(ASSIGN); }

";"             { process_token(SEMI); }
","             { process_token(COMMA); }
"("             { process_token(LPAREN); }
")"             { process_token(RPAREN); }
"["             { process_token(LBRACK); }
"]"             { process_token(RBRACK); }
"{"             { process_token(LBRACE); }
"}"             { process_token(RBRACE); }

{number}        { yylval = new_node(NUM_NODE, atoi(yytext)); process_token(NUM); }
{identifier}    { process_id(); process_token(ID); }
{string}        { yylval = new_node(STRING_NODE, add_literal(lt, yytext)); process_token(STRING); }

                /* Be sure to keep this as the last rule */
.               { fprintf(stderr, "SCANNING ERROR (%d): Unknown symbol %s\n", yylineno, yytext);
                  exit(1); }

%%
