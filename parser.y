%{
    #include<bits/stdc++.h>
    #include<iostream>
    #include<string>
    #include<list>
    #include<iterator>
    #include<utility>
    #include<fstream>
    #include "symbolTable.h"
    
    using namespace std;
    
    extern FILE* yyin;
    extern int lineCount;   
    extern int errorCount;
    extern SymbolTable symbolTable;

    list<pair<string, string> > newDeclaredVars;  // Contains variables <name, type> declared in the current scope
    list<pair<string, string> > parameters;   // Contains the parameter list <name, type> of the currently declared function
    string varType;

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

    void errorMessage(string message) {
        errorCount++;
        errorFile << "Error at line " << lineCount << ": " << message << "\n\n";
    }

    void insertId(string idName, string type) {
        SymbolInfo* idInfo = symbolTable.insert(idName, type);
        if(idInfo == NULL) {
            errorMessage("Multiple declaration of " + idName);
        }
    }

    void insertNewDeclaredVars() {
        list<pair<string, string> >::iterator it = newDeclaredVars.begin();

        while(it != newDeclaredVars.end()) {            
            if(symbolTable.insert((*it).first, "ID", (*it).second) == NULL) {
                errorMessage("Multiple declaration of " + (*it).first);
            }
            newDeclaredVars.erase(it++);
        }
    }

    /** 
    * Checks if the ID is already declared or not
    * If declared then throw an error
    * else inserts the function in the root scope
    * and updates the return type
    */
    void handleFunctionDeclaration(string name, string returnType) {
        FunctionInfo* functionInfo = (FunctionInfo*)symbolTable.insert(name, "ID", true);
        if(functionInfo == NULL) {
            errorMessage("Multiple declaration of " + name);
        } else {
            functionInfo->setReturnType(returnType);
            // Add all the parameters to the function and then remove
            // those from the parameter list
            list<pair<string, string> >::iterator it = parameters.begin();
            
            while(it != parameters.end()) {
                functionInfo->addParameter((*it).second);
                parameters.erase(it++);
            }
        }
    }

    void handleFunctionDefinition(string name, string returnType) {
        // Check if the ID name already exists in the scope
        SymbolInfo* symbolInfo = symbolTable.lookUpCurrentScope(name);
        bool hasDeclared = false;

        if(symbolInfo != NULL) {
            cout << "In if of " + name + "\n";
            symbolTable.printCurrentScopeTable();
            // Check if it is a function
            // if not then throw an error
            if(!symbolInfo->getIsFunction()) {
                errorMessage("Multiple declaration of " + name);
                return;
            }
            
            // Else set hasDeclared
            hasDeclared = true;
            // If it is a function then check if it is already defined
            // If defined then throw an error
            if(((FunctionInfo*)symbolInfo)->getIsDefined()) {
                errorMessage("Multiple definition of the function " + name);
                return;
            }
            // else, it is a function which is declared but not yet defined
            // check the consistency of the definition with the declaration
            else {
                FunctionInfo* functionInfo = (FunctionInfo*)symbolInfo;
                // check the return type
                if(returnType != functionInfo->getReturnType()) {
                    errorMessage("Return type of the function " + name + " does not match with the declaration");
                    return;
                }

                if(functionInfo->getNumberOfParameters() != parameters.size()) {
                    errorMessage("Number of parameters does not match with the function declaration");
                    return;
                }

                // Check if the parameter types matched with the function declaration
                int i = 0;
                for(pair<string, string> parameter : parameters) {
                    if(parameter.second != functionInfo->getParameterTypeAtIdx(i)) {
                        errorMessage("Function parameter/s does not match with the declaration");
                        return;
                    }

                    i++;
                }
            } 
        }
        // As the function is error free,
        // If the function is not declared then insert it into the root scope
        FunctionInfo* functionInfo;
        if(!hasDeclared) {
            functionInfo = (FunctionInfo*)symbolTable.insert(name, "ID", true);
            functionInfo->setIsDefined();
            functionInfo->setReturnType(returnType);
        } else {
            functionInfo = (FunctionInfo*)symbolInfo;
            functionInfo->setIsDefined();
        }
        // create new scope and insert all the parameters and newDeclaredVars in the scope
        symbolTable.enterScope();

        list<pair<string, string> >::iterator it = parameters.begin();
            
        while(it != parameters.end()) {
            if(!hasDeclared)
                functionInfo->addParameter((*it).second);
            
            if(symbolTable.insert((*it).first, "ID", (*it).second) == NULL) {
                errorMessage("Multiple declaration of " + (*it).first);
            }
            parameters.erase(it++);
        }

        insertNewDeclaredVars();

        // Print the symbol table and then exit the current scope
        logFile << symbolTable.getNonEmptyList() << "\n\n";
        symbolTable.exitScope();
    }

    void printSummary() {
        logFile << symbolTable.getNonEmptyList() << '\n';
        logFile << "Total lines: " << lineCount << "\n";
        logFile << "Total errors: " << errorCount << "\n";
    }
%}

%define parse.error verbose

%union {
    SymbolInfo* symbolInfo;
}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN
%token STRING NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON ASSIGNOP
%token<symbolInfo> CONST_INT CONST_FLOAT CONST_CHAR ADDOP MULOP RELOP LOGICOP INCOP ID ARITHASSIGNOP

%type<symbolInfo> program unit func_declaration func_definition parameter_list compound_statement var_declaration
type_specifier declaration_list statements statement expression_statement variable expression
logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

%destructor {delete $$;} <symbolInfo>

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
        logFoundRule("start", "program", "");
        printSummary();

        delete $1;
    }
;

program
:   program unit {
        $$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "VARIABLE");
        logFoundRule("program", "program unit", $$->getName());
        delete $1;
        delete $2;
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
        insertNewDeclaredVars();
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
:   type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
        string returnType = $1->getName();
        string id = $2->getName();
        $$ = new SymbolInfo(returnType + " " + id + "(" + $4->getName() + ");", "VARIABLE");
        logFoundRule("func_declaration", "type_specifier ID LPAREN parameter_list RPAREN SEMICOLON", $$->getName());

        handleFunctionDeclaration(id, returnType);
        
        delete $1;
        delete $2;
        delete $4;
    }
|   type_specifier ID LPAREN RPAREN SEMICOLON {
        string returnType = $1->getName();
        string id = $2->getName();
        
        handleFunctionDeclaration(id, returnType);
        
        $$ = new SymbolInfo(returnType + " " + id + "();", "VARIABLE");
        logFoundRule("func_declaration", "type_specifier ID LPAREN RPAREN SEMICOLON", $$->getName()); 
        delete $1;
        delete $2;
    }
;

func_definition
:   type_specifier ID LPAREN parameter_list RPAREN compound_statement {
        string returnType = $1->getName();
        string id = $2->getName();
        
        $$ = new SymbolInfo(returnType + " " + id + "(" + $4->getName() + ")" + $6->getName(), "VARIABLE");
        logFoundRule("func_definition", "type_specifier ID LPAREN parameter_list RPAREN compound_statement", $$->getName());
        
        handleFunctionDefinition(id, returnType);

        // clear the parameters and var declarations
        parameters.clear();
        newDeclaredVars.clear();

        delete $1;
        delete $2;
        delete $4;
        delete $6;
    }
|   type_specifier ID LPAREN RPAREN compound_statement {
        string returnType = $1->getName();
        string id = $2->getName();

        $$ = new SymbolInfo(returnType + " " + id + "()" + $5->getName(), "VARIABLE");
        logFoundRule("func_definition", "type_specifier ID LPAREN RPAREN compound_statement", $$->getName());

        handleFunctionDefinition(id, returnType);

        // clear the parameters and var declarations
        parameters.clear();
        newDeclaredVars.clear();

        delete $1;
        delete $2;
        delete $5;
    }
;

parameter_list
:   parameter_list COMMA type_specifier ID {
        string id = $4->getName();
        string type = $3->getName();

        // Save the name and type of the parameter
        parameters.push_back(make_pair(id, type));

        $$ = new SymbolInfo($1->getName() + "," + type + " " + id, "VARIABLE");
        logFoundRule("parameter_list", "parameter_list COMMA type_specifier ID", $$->getName());

        delete $1;
        delete $3;
        delete $4;
    }
|   parameter_list COMMA type_specifier {
        string type = $3->getName();

        // Save the name and type of the parameter
        parameters.push_back(make_pair("", type));

        $$ = new SymbolInfo($1->getName() + "," + type, "VARIABLE");
        logFoundRule("parameter_list", "parameter_list COMMA type_specifier", $$->getName());
        delete $1;
        delete $3;
    }
|   type_specifier ID {
        string type = $1->getName();
        string id =  $2->getName();

        // Save the name and type of the parameter
        parameters.push_back(make_pair(id, type));

        $$ = new SymbolInfo(type + " " + id, "VARIABLE");
        logFoundRule("parameter_list", "type_specifier ID", $$->getName());

        delete $1;
        delete $2;
    }
|   type_specifier {
        string type = $1->getName();

        // Save the name and type of the parameter
        parameters.push_back(make_pair("", type));

        $$ = $1;
        logFoundRule("parameter_list", "type_specifier", $$->getName());
    }
;

compound_statement
:   LCURL statements RCURL {
        $$ = new SymbolInfo("{\n" + $2->getName() + "\n}", "VARIABLE");
        logFoundRule("compound_statement", "LCURL statements RCURL", $$->getName());
        
        delete $2;
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
        
        varType.clear();
        delete $1;
        delete $2;
    }
;

type_specifier
:   INT {
        varType = "int";

        $$ = new SymbolInfo("int", "VARIABLE");
        logFoundRule("type_specifier", "INT", $$->getName());
    }
|   FLOAT {
        varType = "float";

        $$ = new SymbolInfo("float", "VARIABLE");
        logFoundRule("type_specifier", "FLOAT", $$->getName());
    }
|   DOUBLE {
        varType = "double";

        $$ = new SymbolInfo("double", "VARIABLE");
        logFoundRule("type_specifier", "DOUBLE", $$->getName());
    }
|   CHAR {
        varType = "char";

        $$ = new SymbolInfo("char", "VARIABLE");
        logFoundRule("type_specifier", "CHAR", $$->getName());
    }
|   VOID {
        varType = "void";

        $$ = new SymbolInfo("void", "VARIABLE");
        logFoundRule("type_specifier", "VOID", $$->getName());
    }
;

declaration_list
:   declaration_list COMMA ID {
        string id = $3->getName();
        newDeclaredVars.push_back(make_pair(id, varType));

        $$ = new SymbolInfo($1->getName() + "," + id, "VARIABLE");
        logFoundRule("declaration_list", "declaration_list COMMA ID", $$->getName());
        
        delete $1;
        delete $3;
    }

|   declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
        string id = $3->getName();
        newDeclaredVars.push_back(make_pair(id, varType + "*"));

        $$ = new SymbolInfo($1->getName() + "," + id + "[" + $5->getName() + "]", "VARIABLE");
        logFoundRule("declaration_list", "declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", $$->getName());
        delete $1;
        delete $3;
        delete $5;
    }
|   ID {
        newDeclaredVars.push_back(make_pair($1->getName(), varType));

        $$ = $1;
        logFoundRule("declaration_list", "ID", $$->getName());
    }
|   ID LTHIRD CONST_INT RTHIRD {
        string id = $1->getName();
        newDeclaredVars.push_back(make_pair(id, varType + "*"));

        $$ = new SymbolInfo(id + "[" + $3->getName() + "]", "VARIABLE");
        logFoundRule("declaration_list", "ID LTHIRD CONST_INT RTHIRD", $$->getName());

        delete $1;
        delete $3;
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
        delete $1;
        delete $2;
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
        delete $3;
        delete $4;
        delete $5;
        delete $7;
    }
    
|   IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
        $$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName(), "VARIABLE");
        logFoundRule("statement", "IF LPAREN expression RPAREN statement", $$->getName());
        delete $3;
        delete $5;
    }
|   IF LPAREN expression RPAREN statement ELSE statement {
        $$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName() + "else" + $7->getName(), "VARIABLE");
        logFoundRule("statement", "IF LPAREN expression RPAREN statement ELSE statement", $$->getName());
        delete $3;
        delete $5;
        delete $7;
    }
|   WHILE LPAREN expression RPAREN statement {
        $$ = new SymbolInfo("while(" + $3->getName() + ")" + $5->getName(), "VARIABLE");
        logFoundRule("statement", "WHILE LPAREN expression RPAREN statement", $$->getName());
        delete $3;
        delete $5;
    }
|   PRINTLN LPAREN ID RPAREN SEMICOLON {
        $$ = new SymbolInfo("printf(" + $3->getName() + ");", "VARIABLE");
        logFoundRule("statement", "PRINTLN LPAREN ID RPAREN SEMICOLON", $$->getName());
        delete $3;
    }
|   RETURN expression SEMICOLON {
        $$ = new SymbolInfo("return " + $2->getName() + ";", "VARIABLE");
        logFoundRule("statement", "RETURN expression SEMICOLON", $$->getName());
        delete $2;
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
        delete $1;
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
        delete $1;
        delete $3;
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
        delete $1;
        delete $3;
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
        delete $1;
        delete $2;
        delete $3;
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
        delete $1;
        delete $2;
        delete $3;
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
        delete $1;
        delete $2;
        delete $3;
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
        delete $1;
        delete $2;
        delete $3;
    }
;

unary_expression
:   ADDOP unary_expression {
        $$ = new SymbolInfo($1->getName() + $2->getName(), "VARIABLE");
        logFoundRule("unary_expression", "ADDOP unary_expression", $$->getName());
        delete $1;
        delete $2;
    }
|   NOT unary_expression {
        $$ = new SymbolInfo("!" + $2->getName(), "VARIABLE");
        logFoundRule("unary_expression", "NOT unary_expression", $$->getName());
        delete $2;
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
        delete $1;
        delete $3;
    }
|   LPAREN expression RPAREN {
        $$ = new SymbolInfo("(" + $2->getName() + ")", "VARIABLE");
        logFoundRule("factor", "LPAREN expression RPAREN", $$->getName());
        delete $2;
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
        delete $1;
        delete $2;
    }
|   INCOP variable %prec PREFIX_INCOP {
        $$ = new SymbolInfo($1->getName() + $2->getName(), "VARIABLE");
        logFoundRule("factor", "INCOP variable", $$->getName());
        delete $1;
        delete $2;
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
        delete $1;
        delete $3;
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