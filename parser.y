%{
    #include<iostream>
    #include<string>
    #include<fstream>
    #include "symbolTable.h"
    #include "symbolInfo.h"
    
    using namespace std;
    
    extern FILE* yyin;
    extern int lineCount;   
    extern int errorCount;

    SymbolTable symbolTable(7);

    ofstream logFile;
    ofstream errorFile;

    int yyparse(void);
    int yylex(void);
    void yyerror(string s) {
        cout << "Line no. " << lineCount << ": " <<  s << "\n";
        errorCount++;
    }

    void logFoundRule(string variable, string rule, string matchedString) {
        logFile << "Line " << lineCount << ": " << variable << " : " << rule << "\n\n";
        logFile << matchedString << "\n\n";
    }
%}

%define parse.error verbose

%union {
    SymbolInfo* symbolInfo;
}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN
%token STRING NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%token<symbolInfo> CONST_INT CONST_FLOAT CONST_CHAR ADDOP MULOP RELOP ASSIGNOP LOGICOP INCOP ID

%type<symbolInfo> start program unit func_declaration func_definition parameter_list compound_statement var_declaration
type_specifier declaration_list statements statement expression_statement variable expression
logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

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
:   program {
        $$ = $1;
        logFoundRule("start", "program", $$->getName());
    }
;

program
:   program unit {
        $$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "VARIABLE");
        logFoundRule("program", "program unit", $$->getName());
    }
|   unit {
        $$ = $1;
        logFoundRule("program", "unit", $$->getName());
    }
;

unit
:   var_declaration {
        $$ = $1;
        logFoundRule("unit", "var_declaration", $$->getName());
    }
|   func_declaration {
        $$ = $1;
        logFoundRule("unit", "func_declaration", $$->getName());
    }
|   func_definition {
        $$ = $1;
        logFoundRule("unit", "func_definition", $$->getName());
    }
;

func_declaration
:   type_specifier ID LPAREN parameter_list RPAREN {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ")", "VARIABLE");
        logFoundRule("func_declaration", "type_specifier ID LPAREN parameter_list RPAREN", $$->getName());
    }
|   type_specifier ID LPAREN RPAREN SEMICOLON {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "VARIABLE");
        logFoundRule("func_declaration", "type_specifier ID LPAREN parameter_list RPAREN", $$->getName()); 
    }
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
:   INT {
        $$ = new SymbolInfo("int", "VARIABLE");
        logFoundRule("type_specifier", "INT", $$->getName());
    }
|   FLOAT {
        $$ = new SymbolInfo("float", "VARIABLE");
        logFoundRule("type_specifier", "FLOAT", $$->getName());
    }
|   DOUBLE {
        $$ = new SymbolInfo("double", "VARIABLE");
        logFoundRule("type_specifier", "DOUBLE", $$->getName());
    }
|   CHAR {
        $$ = new SymbolInfo("char", "VARIABLE");
        logFoundRule("type_specifier", "CHAR", $$->getName());
    }
|   VOID {
        $$ = new SymbolInfo("void", "VARIABLE");
        logFoundRule("type_specifier", "VOID", $$->getName());
    }
;

declaration_list
:   declaration_list COMMA ID {
        $$ = new SymbolInfo($1->getName() + "," + $3->getName(), "VARIABLE");
        logFoundRule("declaration_list", "declaration_list COMMA ID", $$->getName());
    }
|   declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
|   ID {
        $$ = $1;
        logFoundRule("declaration_list", "ID", $$->getName());
    }
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
|   PRINTLN LPAREN ID RPAREN SEMICOLON
|   RETURN expression SEMICOLON
;

expression_statement
:   SEMICOLON
|   expression SEMICOLON
;

variable
:   ID {
        $$ = $1;
        logFoundRule("variable", "ID", $$->getName());
    }
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
:   arguments {
        $$ = $1;
        logFoundRule("argument_list", "arguments", $$->getName());
    }
|       {
        $$ = new SymbolInfo("", "VARIABLE");
        logFoundRule("argument_list", "arguments", "");
    }
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

    logFile.open("1805087_log.txt");
    errorFile.open("1805087_error.txt");

    yyin = fin;
    yyparse();

    errorFile.close();
    logFile.close();
    fclose(fin);

    return 0;
}