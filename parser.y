%{
    #include<iostream>
    #include<string>
    #include "symbolTable.h"

    extern FILE* yyin;

    using namespace std;

    int yyparse(void);
    int yylex(void);
    void yyerror(string s){
        cout << s << "\n";
    }
%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE
%token ID ADDOP MULOP RELOP ASSIGNOP LOGICOP INCOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%token CONST_INT CONST_FLOAT CONST_CHAR STRING

%left COMMA
%right ASSIGNOP
%left LOGICOP
%left RELOP
%left ADDOP
%left MULOP
%left LCURL RCURL
%left LPAREN RPAREN

%right PREFIX_INCOP
%left POSTFIX_INCOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start
:   program
;

program
:   program unit
|   unit
;

unit
:   var_declaration
|   func_declaration
|   func_definition
;

func_declaration
:   type_specifier ID LPAREN parameter_list RPAREN
|   type_specifier ID LPAREN RPAREN SEMICOLON
;

func_definition
:   type_specifier ID LPAREN parameter_list RPAREN compound_statement
|   type_specifier ID LPAREN RPAREN compound_statement
;

parameter_list
:   parameter_list COMMA type_specifier ID
|   parameter_list COMMA type_specifier
|   type_specifier ID
|   type_specifier
;

compound_statement
:   LCURL statements RCURL
|   LCURL RCURL
;

var_declaration
:   type_specifier declaration_list SEMICOLON
;

type_specifier
:   INT
|   FLOAT
|   DOUBLE
|   CHAR
|   VOID
;

declaration_list
:   declaration_list COMMA ID
|   declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
|   ID
|   ID LTHIRD CONST_INT RTHIRD
;

statements
:   statement
|   statements statement
;

statement
:   var_declaration
|   expression_statement
|   compound_statement
|   FOR LPAREN expression_statement expression_statement expression
    RPAREN statement
|   IF LPAREN expression RPAREN statement               %prec LOWER_THAN_ELSE
|   IF LPAREN expression RPAREN statement ELSE statement
|   WHILE LPAREN expression RPAREN statement
|   RETURN expression SEMICOLON
;

expression_statement
:   SEMICOLON
|   expression SEMICOLON
;

variable
:   ID
|   ID LTHIRD expression RTHIRD
;

expression
:   logic_expression
|   variable ASSIGNOP logic_expression
;

logic_expression
:   rel_expression
|   rel_expression LOGICOP rel_expression
;

rel_expression
:   simple_expression
|   simple_expression RELOP simple_expression
;

simple_expression
:   term
|   simple_expression ADDOP term
;

term
:   unary_expression
|   term MULOP unary_expression
;

unary_expression
:   ADDOP unary_expression
|   NOT unary_expression
|   factor
;

factor
:   variable
|   ID LPAREN argument_list RPAREN
|   LPAREN expression RPAREN
|   CONST_INT
|   CONST_FLOAT
|   variable INCOP              %prec POSTFIX_INCOP
|   INCOP variable              %prec PREFIX_INCOP
;

argument_list
:   arguments
|
;

arguments
:   arguments COMMA logic_expression
|   logic_expression
;

%%

int main(int argc, char* argv[]) {
    if(argc != 2) {
        cout << "Please provide input file name and try again\n";
        return 0;
    }

    FILE* fin = fopen(argv[1], "r");
    
    if(fin == NULL) {
        printf("Cannot open input file\n");
        return 0;
    } 

    yyin = fin;
    yyparse();
    fclose(fin);

    return 0;
}