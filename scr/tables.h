
#ifndef TABLES_H
#define TABLES_H

#include "ast.h"

// Literals Table
// ----------------------------------------------------------------------------

struct lit_table;
typedef struct lit_table LitTable;

LitTable* create_lit_table();
int add_literal(LitTable *lt, char *s);
char* get_literal(LitTable *lt, int idx);
void print_lit_table(LitTable *lt);
void free_lit_table(LitTable *lt);

// Variables Table
// ----------------------------------------------------------------------------

struct var_table;
typedef struct var_table VarTable;

VarTable* create_var_table();
int lookup_var(VarTable *vt, char *var, int scope);
int add_fresh_var(VarTable *vt, char *var, int line, int scope, int size);
char* get_var_name(VarTable *vt, int idx);
int get_var_line(VarTable *vt, int idx);
int get_var_scope(VarTable *vt, int idx);
int get_var_size(VarTable *vt, int idx);
int get_var_offset(VarTable *vt, int idx);
void compute_offsets(VarTable *vt);
void print_var_table(VarTable *vt);
void free_var_table(VarTable *vt);

// Functions Table
// ----------------------------------------------------------------------------

struct func_table;
typedef struct func_table FuncTable;

FuncTable* create_func_table();
int lookup_func(FuncTable *ft, char *func);
int add_fresh_func(FuncTable *ft, char *func, int line);
void set_func_arity(FuncTable *ft, int idx, int arity);
void add_func_pointer(FuncTable *ft, int idx, AST* fpointer);
char* get_func_name(FuncTable *ft, int idx);
int get_func_line(FuncTable *ft, int idx);
int get_func_arity(FuncTable *ft, int idx);
AST* get_func_pointer(FuncTable *ft, int idx);
void print_func_table(FuncTable *ft);
void free_func_table(FuncTable *ft);

#endif // TABLES_H

