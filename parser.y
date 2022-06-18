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
        logFoundRule("func_declaration", "type_specifier ID LPAREN RPAREN SEMICOLON", $$->getName()); 
    }
;

func_definition
:   type_specifier ID LPAREN parameter_list RPAREN compound_statement {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ")" + $6->getName(), "VARIABLE");
        logFoundRule("func_definition", "type_specifier ID LPAREN parameter_list RPAREN compound_statement", $$->getName());
    }
|   type_specifier ID LPAREN RPAREN compound_statement {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + "()" + $5->getName(), "VARIABLE");
        logFoundRule("func_definition", "type_specifier ID LPAREN RPAREN compound_statement", $$->getName());
    }
;

parameter_list
:   parameter_list COMMA type_specifier ID {
        $$ = new SymbolInfo($1->getName() + "," + $3->getName() + " " + $4->getName(), "VARIABLE");
        logFoundRule("parameter_list", "parameter_list COMMA type_specifier ID", $$->getName());
    }
|   parameter_list COMMA type_specifier {
        $$ = new SymbolInfo($1->getName() + "," + $3->getName(), "VARIABLE");
        logFoundRule("parameter_list", "parameter_list COMMA type_specifier", $$->getName());
    }
|   type_specifier ID {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName(), "VARIABLE");
        logFoundRule("parameter_list", "type_specifier ID", $$->getName());
    }
|   type_specifier {
        $$ = $1;
        logFoundRule("parameter_list", "type_specifier", $$->getName());
    }
;

compound_statement
:   LCURL statements RCURL {
        $$ = new SymbolInfo("{\n" + $2->getName() + "\n}", "VARIABLE");
        logFoundRule("compound_statement", "LCURL statements RCURL", $$->getName());
    }
|   LCURL RCURL {
        $$ = new SymbolInfo("{}", "VARIABLE");
        logFoundRule("compound_statement", "LCURL RCURL", $$->getName());
    }
;

var_declaration
:   type_specifier declaration_list SEMICOLON {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + ";", "VARIABLE");
        logFoundRule("var_declaration", "type_specifier declaration_list SEMICOLON", $$->getName());
    }
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
|   declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
        $$ = new SymbolInfo($1->getName() + "," + $3->getName() + "[" + $5->getName() + "]", "VARIABLE");
        logFoundRule("declaration_list", "declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", $$->getName());
    }
|   ID {
        $$ = $1;
        logFoundRule("declaration_list", "ID", $$->getName());
    }
|   ID LTHIRD CONST_INT RTHIRD {
        $$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", "VARIABLE");
        logFoundRule("declaration_list", "ID LTHIRD CONST_INT RTHIRD", $$->getName());
    }
;

statements
:   statement {
        $$ = $1;
        logFoundRule("statements", "statement", $$->getName());
    }
|   statements statement {
        $$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "VARIABLE");
        logFoundRule("statements", "statements statement", $$->getName());
    }
;

statement
:   var_declaration {
        $$ = $1;
        logFoundRule("statement", "var_declaration", $$->getName());
    }
|   expression_statement {
        $$ = $1;
        logFoundRule("statement", "expression_statement", $$->getName());
    }
|   compound_statement {
        $$ = $1;
        logFoundRule("statement", "compound_statement", $$->getName());
    }
|   FOR LPAREN expression_statement expression_statement expression RPAREN statement {
        $$ = new SymbolInfo("for(" + $3->getName() + $4->getName() + $5->getName() + ")" + $7->getName(), "VARIABLE");
        logFoundRule("statement", "FOR LPAREN expression_statement expression_statement expression RPAREN statement", $$->getName());
    }
    
|   IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
        $$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName(), "VARIABLE");
        logFoundRule("statement", "IF LPAREN expression RPAREN statement", $$->getName());
    }
|   IF LPAREN expression RPAREN statement ELSE statement {
        $$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName() + "else" + $7->getName(), "VARIABLE");
        logFoundRule("statement", "IF LPAREN expression RPAREN statement ELSE statement", $$->getName());
    }
|   WHILE LPAREN expression RPAREN statement {
        $$ = new SymbolInfo("while(" + $3->getName() + ")" + $5->getName(), "VARIABLE");
        logFoundRule("statement", "WHILE LPAREN expression RPAREN statement", $$->getName());
    }
|   PRINTLN LPAREN ID RPAREN SEMICOLON {
        $$ = new SymbolInfo("printf(" + $3->getName() + ");", "VARIABLE");
        logFoundRule("statement", "PRINTLN LPAREN ID RPAREN SEMICOLON", $$->getName());
    }
|   RETURN expression SEMICOLON {
        $$ = new SymbolInfo("return " + $2->getName() + ";", "VARIABLE");
        logFoundRule("statement", "RETURN expression SEMICOLON", $$->getName());
    }
;

expression_statement
:   SEMICOLON {
        $$ = new SymbolInfo(";", "VARIABLE");
        logFoundRule("expression_statement", "SEMICOLON", $$->getName());
    }
|   expression SEMICOLON {
        $$ = new SymbolInfo($1->getName() + ";", "VARIABLE");
        logFoundRule("expression_statement", "expression SEMICOLON", $$->getName());
    }
;

variable
:   ID {
        $$ = $1;
        logFoundRule("variable", "ID", $$->getName());
    }
|   ID LTHIRD expression RTHIRD {
        $$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", "VARIABLE");
        logFoundRule("variable", "ID LTHIRD expression RTHIRD", $$->getName());
    }
;

expression
:   logic_expression {
        $$ = $1;
        logFoundRule("expression", "logic_expression", $$->getName());
    }
|   variable ASSIGNOP logic_expression {
        $$ = new SymbolInfo($1->getName() + " = " + $3->getName(), "VARIABLE");
        logFoundRule("expression", "variable ASSIGNOP logic_expression", $$->getName());
    }
;

logic_expression
:   rel_expression {
        $$ = $1;
        logFoundRule("logic_expression", "rel_expression", $$->getName());
    }
|   rel_expression LOGICOP rel_expression {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "VARIABLE");
        logFoundRule("logic_expression", "rel_expression LOGICOP rel_expression", $$->getName());
    }
;

rel_expression
:   simple_expression {
        $$ = $1;
        logFoundRule("rel_expression", "simple_expression", $$->getName());
    }
|   simple_expression RELOP simple_expression {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "VARIABLE");
        logFoundRule("rel_expression", "simple_expression RELOP simple_expression", $$->getName());
    }
;

simple_expression
:   term {
        $$ = $1;
        logFoundRule("simple_expression", "term", $$->getName());
    }
|   simple_expression ADDOP term {
        $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "VARIABLE");
        logFoundRule("simple_expression", "simple_expression ADDOP term", $$->getName());
    }
;

term
:   unary_expression {
        $$ = $1;
        logFoundRule("term", "unary_expression", $$->getName());
    }
|   term MULOP unary_expression {
        $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "VARIABLE");
        logFoundRule("term", "term MULOP unary_expression", $$->getName());
    }
;

unary_expression
:   ADDOP unary_expression {
        $$ = new SymbolInfo($1->getName() + $2->getName(), "VARIABLE");
        logFoundRule("unary_expression", "ADDOP unary_expression", $$->getName());
    }
|   NOT unary_expression {
        $$ = new SymbolInfo("!" + $2->getName(), "VARIABLE");
        logFoundRule("unary_expression", "NOT unary_expression", $$->getName());
    }
|   factor {
        $$ = $1;
        logFoundRule("unary_expression", "factor", $$->getName());
    }
;

factor
:   variable {
        $$ = $1;
        logFoundRule("factor", "variable", $$->getName());
    }
|   ID LPAREN argument_list RPAREN {
        $$ = new SymbolInfo($1->getName() + "(" + $3->getName() + ")", "VARIABLE");
        logFoundRule("factor", "ID LPAREN argument_list RPAREN", $$->getName());
    }
|   LPAREN expression RPAREN {
        $$ = new SymbolInfo("(" + $2->getName() + ")", "VARIABLE");
        logFoundRule("factor", "LPAREN expression RPAREN", $$->getName());
    }
|   CONST_INT {
        $$ = $1;
        logFoundRule("factor", "CONST_INT", $$->getName());
    }
|   CONST_FLOAT {
        $$ = $1;
        logFoundRule("factor", "CONST_FLOAT", $$->getName());
    }
|   variable INCOP %prec POSTFIX_INCOP {
        $$ = new SymbolInfo($1->getName() + $2->getName(), "VARIABLE");
        logFoundRule("factor", "variable INCOP", $$->getName());
    }
|   INCOP variable %prec PREFIX_INCOP {
        $$ = new SymbolInfo($1->getName() + $2->getName(), "VARIABLE");
        logFoundRule("factor", "INCOP variable", $$->getName());
    }
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
:   arguments COMMA logic_expression {
        $$ = new SymbolInfo($1->getName() + ", " + $3->getName(), "VARIABLE");
        logFoundRule("arguments", "arguments COMMA logic_expression", $$->getName());
    }
|   logic_expression {
        $$ = $1;
        logFoundRule("arguments", "logic_expression", $$->getName());
    }
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