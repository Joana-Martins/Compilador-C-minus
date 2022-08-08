
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "tables.h"

// Literals Table
// ----------------------------------------------------------------------------

#define LITERAL_MAX_SIZE 128
#define LITERALS_TABLE_MAX_SIZE 100

struct lit_table {
    char t[LITERALS_TABLE_MAX_SIZE][LITERAL_MAX_SIZE];
    int size;
};

LitTable* create_lit_table() {
    LitTable *lt = malloc(sizeof * lt);
    lt->size = 0;
    return lt;
}

int add_literal(LitTable *lt, char *s) {
    for (int i = 0; i < lt->size; i++) {
        if (strcmp(lt->t[i], s) == 0) {
            return i;
        }
    }
    strcpy(lt->t[lt->size], s);
    int idx_added = lt->size;
    lt->size++;
    return idx_added;
}

char* get_literal(LitTable *lt, int idx) {
    return lt->t[idx];
}

void print_lit_table(LitTable *lt) {
    fprintf(stderr, "Literals table:\n");
    for (int i = 0; i < lt->size; i++) {
        fprintf(stderr, "Entry %d -- %s\n", i, get_literal(lt, i));
    }
}

void free_lit_table(LitTable *lt) {
    free(lt);
}

// Variables Table
// ----------------------------------------------------------------------------

#define VAR_MAX_SIZE 128
#define VAR_TABLE_MAX_SIZE 100

typedef struct {
  char name[VAR_MAX_SIZE];
  int line;
  int scope;
  int size; // 0 - simple var; >0 - array (complex) var with given size
  int offset;
} VarEntry;

struct var_table {
    VarEntry t[VAR_TABLE_MAX_SIZE];
    int size;
};

VarTable* create_var_table() {
    VarTable *vt = malloc(sizeof * vt);
    vt->size = 0;
    return vt;
}

int lookup_var(VarTable *vt, char *var, int scope) {
    for (int i = 0; i < vt->size; i++) {
        if (strcmp(vt->t[i].name, var) == 0 && get_var_scope(vt, i) == scope)  {
            return i;
        }
    }
    return -1;
}

int add_fresh_var(VarTable *vt, char *var, int line, int scope, int size) {
    strcpy(vt->t[vt->size].name, var);
    vt->t[vt->size].line = line;
    vt->t[vt->size].scope = scope;
    vt->t[vt->size].size = size;
    vt->t[vt->size].offset = 0;
    int idx_added = vt->size;
    vt->size++;
    return idx_added;
}

char* get_var_name(VarTable *vt, int idx) {
    return vt->t[idx].name;
}

int get_var_line(VarTable *vt, int idx) {
    return vt->t[idx].line;
}

int get_var_scope(VarTable *vt, int idx) {
    return vt->t[idx].scope;
}

int get_var_size(VarTable *vt, int idx) {
    return vt->t[idx].size;
}

int get_var_offset(VarTable *vt, int idx) {
    return vt->t[idx].offset;
}

void compute_offsets(VarTable *vt) {
    // TODO
}

void print_var_table(VarTable *vt) {
    fprintf(stderr, "Variables table:\n");
    for (int i = 0; i < vt->size; i++) {
         fprintf(stderr, "Entry %d -- name: %s, line: %d, scope: %d, size: %d\n",
                 i, get_var_name(vt, i), get_var_line(vt, i), get_var_scope(vt, i),
                 get_var_size(vt, i));
    }
}

void free_var_table(VarTable *vt) {
    free(vt);
}

// Functions Table
// ----------------------------------------------------------------------------

#define FUNC_MAX_SIZE 128
#define FUNC_TABLE_MAX_SIZE 100

typedef struct {
  char name[FUNC_MAX_SIZE];
  int line;
  int arity;
  AST* fpointer;
} FuncEntry;

struct func_table {
    FuncEntry t[FUNC_TABLE_MAX_SIZE];
    int size;
};

FuncTable* create_func_table() {
    FuncTable *ft = malloc(sizeof * ft);
    ft->size = 0;
    return ft;
}

int lookup_func(FuncTable *ft, char *func) {
    for (int i = 0; i < ft->size; i++) {
        if (strcmp(ft->t[i].name, func) == 0)  {
            return i;
        }
    }
    return -1;
}

int add_fresh_func(FuncTable *ft, char *func, int line) {
    strcpy(ft->t[ft->size].name, func);
    ft->t[ft->size].line = line;
    ft->t[ft->size].arity = 0;
    ft->t[ft->size].fpointer = NULL;
    int idx_added = ft->size;
    ft->size++;
    return idx_added;
}

void set_func_arity(FuncTable *ft, int idx, int arity) {
    ft->t[idx].arity = arity;
}

void add_func_pointer(FuncTable *ft, int idx, AST* fpointer) {
    ft->t[idx].fpointer = fpointer;
}

char* get_func_name(FuncTable *ft, int idx) {
    return ft->t[idx].name;
}

int get_func_line(FuncTable *ft, int idx) {
    return ft->t[idx].line;
}

int get_func_arity(FuncTable *ft, int idx) {
    return ft->t[idx].arity;
}

AST* get_func_pointer(FuncTable *ft, int idx) {
    return ft->t[idx].fpointer;
}

void print_func_table(FuncTable *ft) {
    fprintf(stderr, "Functions table:\n");
    for (int i = 0; i < ft->size; i++) {
         fprintf(stderr, "Entry %d -- name: %s, line: %d, arity: %d\n",
                 i, get_func_name(ft, i), get_func_line(ft, i), get_func_arity(ft, i));
    }
}

void free_func_table(FuncTable *ft) {
    free(ft);
}
