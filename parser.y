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
    
    extern string toUpper(string str);

    list<pair<string, string> > parameters;   // Contains the parameter list <name, type> of the currently declared function
    string varType;     // Contains recent variable type
    string funcName, funcReturnType;
    bool hasDeclaredId = false, hasFuncDeclared = false, hasFuncDefined = false;

    ofstream logFile;
    ofstream errorFile;

    int yyparse(void);
    int yylex(void);

    

    void logFoundRule(string variable, string rule, string matchedString) {
        logFile << "Line " << lineCount << ": " << variable << " : " << rule << "\n\n";
        logFile << matchedString << "\n\n";
    }

    void errorMessage(string message) {
        errorCount++;
        errorFile << "Error at line " << lineCount << ": " << message << "\n\n";
        logFile << "Error at line " << lineCount << ": " << message << "\n\n";
    }

    void yyerror(string s) {
        errorMessage(s);
    }

    void insertId(string idName, string type) {
        SymbolInfo* idInfo = symbolTable.insert(idName, "ID", "CONST_" + toUpper(type));
        if(idInfo == NULL) {
            errorMessage("Multiple declaration of " + idName);
        }
    }

    void typeCheck(SymbolInfo* lSymbol, SymbolInfo* rSymbol) {
        string lType = lSymbol->getType();
        if(lType != rSymbol->getType()) {
            if(lType[lType.size()-1] == '*')
                errorMessage("Type Mismatch: " + lSymbol->getName() + " is an array");
            else
                errorMessage("Type Mismatch");
        }
    }

    /** 
    * Checks if the ID is already declared or not
    * If declared then throw an error
    * else inserts the function in the root scope
    * and updates the return type
    */
    void handleFuncDeclaration(string name, string returnType) {
        funcName = name;
        funcReturnType = returnType;
        FunctionInfo* functionInfo = (FunctionInfo*)symbolTable.insert(name, "ID", true);

        if(functionInfo == NULL) {
            SymbolInfo* symbolInfo = symbolTable.lookUp(name);
            if(symbolInfo->getIsFunction()) {
                hasFuncDeclared = true;
                functionInfo = (FunctionInfo*)symbolInfo;

                if(functionInfo->getIsDefined())
                    hasFuncDefined = true;    
            } else {
                errorMessage("Multiple declaration of " + funcName);
                hasDeclaredId = true;
            }
        } else {
            functionInfo->setReturnType(returnType);
            // Add all the parameters to the function and then remove
            // those from the parameter list
            list<pair<string, string> >::iterator it = parameters.begin();
            
            while(it != parameters.end()) {
                functionInfo->addParameter((*it).second);
                it++;
            }
        }
    }

    void handleFunctionDefinition() {
        // Check if it is a function
        // if not then throw an error
        if(hasDeclaredId) {
            return;
        }
        // if the function is already defined, throw an error
        if(hasFuncDefined) {
            errorMessage("Multiple definition of the function " + funcName);
            return;
        }

        // Look up the functionInfo that has been inserted recently in the func_prototype
        FunctionInfo* functionInfo = (FunctionInfo*)symbolTable.lookUpCurrentScope(funcName);
        // Set isDefined
        functionInfo->setIsDefined();
        // else if it is a function which is declared but not yet defined
        // check the consistency of the definition with the declaration
        if(hasFuncDeclared) {
            // check the return type
            if(funcReturnType != functionInfo->getReturnType()) {
                errorMessage("Return type of the function " + funcName + " does not match with the declaration");
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
        } else {
            // The function has neither declared nor defined before
            // so, set the parameter list
            list<pair<string, string> >::iterator it = parameters.begin();
                
            while(it != parameters.end()) {
                functionInfo->addParameter((*it).second);
                
                parameters.erase(it++);
            }
        }
        
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

%type<symbolInfo> program unit func_prototype func_declaration func_definition parameter_list compound_statement var_declaration
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
        // insertNewDeclaredVars();
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

func_prototype
:   type_specifier ID LPAREN parameter_list RPAREN {
        string returnType = $1->getName();
        string id = $2->getName();
        $$ = new SymbolInfo(returnType + " " + id + "(" + $4->getName() + ")", "parameter_list");

        handleFuncDeclaration(id, returnType);

        delete $1;
        delete $2;
        delete $4;
}
|   type_specifier ID LPAREN RPAREN {
        string returnType = $1->getName();
        string id = $2->getName();
        $$ = new SymbolInfo(returnType + " " + id + "()", "");

        handleFuncDeclaration(id, returnType);

        delete $1;
        delete $2;
}

func_declaration
:   func_prototype SEMICOLON {
        $$ = new SymbolInfo($1->getName() + ";", "VARIABLE");
        logFoundRule("func_declaration", "type_specifier ID LPAREN " + $1->getType() + " RPAREN SEMICOLON", $$->getName());

        if(hasFuncDeclared)
            errorMessage("Multiple declaration of " + funcName);
        
        hasDeclaredId = hasFuncDeclared = hasFuncDefined = false;
        funcName.clear();
        funcReturnType.clear();
        parameters.clear();
        delete $1;
    }
;

func_definition
:   func_prototype compound_statement {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName(), "VARIABLE");
        logFoundRule("func_definition", "type_specifier ID LPAREN " + $1->getType() + " RPAREN compound_statement", $$->getName());
        
        handleFunctionDefinition();

        hasDeclaredId = hasFuncDeclared = hasFuncDefined = false;
        funcName.clear();
        funcReturnType.clear();
        parameters.clear();
        delete $1;
        delete $2;
    }
;

enter_scope
:   {
    symbolTable.enterScope();

    // Insert the parameters in the scope
    list<pair<string, string> >::iterator it = parameters.begin();

    while(it != parameters.end()) {        
        if(symbolTable.insert((*it).first, "ID", (*it).second) == NULL)
            errorMessage("Multiple declaration of the parameter name " + (*it).first);
        it++;
    }
}

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
:   LCURL enter_scope statements RCURL {
        $$ = new SymbolInfo("{\n" + $3->getName() + "\n}", "VARIABLE");
        logFoundRule("compound_statement", "LCURL statements RCURL", $$->getName());
        
        // Print the symbol table and then exit the current scope
        logFile << symbolTable.getNonEmptyList() << "\n\n";
        symbolTable.exitScope();

        delete $3;
    }
|   LCURL enter_scope RCURL {
        $$ = new SymbolInfo("{}", "VARIABLE");
        logFoundRule("compound_statement", "LCURL RCURL", $$->getName());

        logFile << symbolTable.getNonEmptyList() << "\n\n";
        symbolTable.exitScope();
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
        // newDeclaredVars.push_back(make_pair(id, varType));
        insertId(id, varType);

        $$ = new SymbolInfo($1->getName() + "," + id, "VARIABLE");
        logFoundRule("declaration_list", "declaration_list COMMA ID", $$->getName());
        
        delete $1;
        delete $3;
    }

|   declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
        string id = $3->getName();
        insertId(id, varType + "*");

        $$ = new SymbolInfo($1->getName() + "," + id + "[" + $5->getName() + "]", "VARIABLE");
        logFoundRule("declaration_list", "declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", $$->getName());

        delete $1;
        delete $3;
        delete $5;
    }
/* |   declaration_list COMMA ID LTHIRD error RTHIRD {
        string id = $3->getName();
        insertId(id, varType + "*");
        
        $$ = new SymbolInfo($1->getName() + "," + id + "[]", "VARIABLE");

        errorMessage("Expression inside third brackets not an integer");
        
        

        delete $1;
        delete $3;
        
        yyclearin;
        yyerrok;
} */
|   ID {
        insertId($1->getName(), varType);

        $$ = $1;
        logFoundRule("declaration_list", "ID", $$->getName());
    }
|   ID LTHIRD CONST_INT RTHIRD {
        string id = $1->getName();
        insertId(id, varType + "*");

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
        $$ = new SymbolInfo("return " + $2->getName() + ";", $2->getType());
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
        $$ = new SymbolInfo($1->getName() + ";", $1->getType());
        logFoundRule("expression_statement", "expression SEMICOLON", $$->getName());
        delete $1;
    }
;

variable
:   ID {
        string id = $1->getName();
        logFoundRule("variable", "ID", id);

        SymbolInfo* symbolInfo = symbolTable.lookUp(id);
        if(symbolInfo == NULL) {
            errorMessage("Undeclared variable " + id);
            $$ = new SymbolInfo(id, "UNDEC");
        } else {
            $$ = new SymbolInfo(symbolInfo->getName(), ((IdInfo*)symbolInfo)->getIdType());
        }
        
        delete $1;
    }
|   ID LTHIRD expression RTHIRD {
        string id = $1->getName();
        string varType = "VARIABLE";
        SymbolInfo* symbolInfo = symbolTable.lookUp(id);

        
        logFoundRule("variable", "ID LTHIRD expression RTHIRD", $$->getName());
        // check if the id is an array or not
        if(symbolInfo == NULL) {
            errorMessage("Undeclared variable " + id);
        } else if(symbolInfo->getType() == "ID") {
            IdInfo* idInfo = (IdInfo*)symbolInfo;
            string idType = idInfo->getIdType();

            if(idType.size() > 0 && idType[idType.size()-1] != '*')
                errorMessage("Type Mismatch: " + id + " is not an array");
            else {
                // the type of the variable will be the original type of the array elements
                // So, truncate the '*'
                varType = idType.substr(0, idType.size() - 1);
            }
        } else {
            errorMessage("Type Mismatch: " + id + " is not an array");
        }
        
        if($3->getType() != "CONST_INT")
            errorMessage("Expression inside third bracket not an integer");
        
        $$ = new SymbolInfo(id + "[" + $3->getName() + "]", varType);

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
        $$ = new SymbolInfo($1->getName() + " = " + $3->getName(), $1->getType());
        logFoundRule("expression", "variable ASSIGNOP logic_expression", $$->getName());

        // Undeclared variables are detected in 'variable' rule
        // and are handled there
        if($1->getType() != "UNDEC")
            typeCheck($1, $3);

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
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "CONST_INT");
        logFoundRule("logic_expression", "rel_expression LOGICOP rel_expression", $$->getName());

        // No need for a type check because, it is okay to have any arbitrary const on 
        // both sides of logical operator

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
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "CONST_INT");
        logFoundRule("rel_expression", "simple_expression RELOP simple_expression", $$->getName());

        typeCheck($1, $3);

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
        $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), $3->getType());
        logFoundRule("simple_expression", "simple_expression ADDOP term", $$->getName());

        typeCheck($1, $3);

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
        string mulop = $2->getName();
        
        $$ = new SymbolInfo($1->getName() + mulop + $3->getName(), $1->getType());
        logFoundRule("term", "term MULOP unary_expression", $$->getName());

        if(mulop == "%" && ($1->getType() != "CONST_INT" || $3->getType() != "CONST_INT")) {
            errorMessage("Non-Integer operand on modulus operator");
        } else {
            typeCheck($1, $3);
        }
        delete $1;
        delete $2;
        delete $3;
    }
;

unary_expression
:   ADDOP unary_expression {
        $$ = new SymbolInfo($1->getName() + $2->getName(), $2->getType());
        logFoundRule("unary_expression", "ADDOP unary_expression", $$->getName());
        delete $1;
        delete $2;
    }
|   NOT unary_expression {
        $$ = new SymbolInfo("!" + $2->getName(), $2->getType());
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
        string id = $1->getName();
        string varName = id + "(" + $3->getName() + ")";
    
        logFoundRule("factor", "ID LPAREN argument_list RPAREN", varName);
    
        SymbolInfo* symbolInfo = symbolTable.lookUp(id);
        
        if(symbolInfo == NULL) {
            // if it was not declared before
            errorMessage(id + " is not a function");
            $$ = new SymbolInfo(varName, "VARIABLE");
        } else if(symbolInfo->getIsFunction()) {
            // if it is a function then set the return type as the type of the expression
            $$ = new SymbolInfo(varName, ((FunctionInfo*)symbolInfo)->getReturnType());
        } else {
            // then it must be an id. Set the id type as the type of the expression
            errorMessage(id + " is not a function");
            $$ = new SymbolInfo(varName, ((IdInfo*)symbolInfo)->getIdType());
        }
            
        delete $1;
        delete $3;
    }
|   LPAREN expression RPAREN {
        $$ = new SymbolInfo("(" + $2->getName() + ")", $2->getType());
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
        $$ = new SymbolInfo($1->getName() + $2->getName(), $1->getType());
        logFoundRule("factor", "variable INCOP", $$->getName());
        delete $1;
        delete $2;
    }
|   INCOP variable %prec PREFIX_INCOP {
        $$ = new SymbolInfo($1->getName() + $2->getName(), $2->getType());
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
|   {
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