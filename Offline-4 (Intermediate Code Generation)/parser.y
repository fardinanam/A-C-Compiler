%{
    #include<bits/stdc++.h>
    #include<iostream>
    #include<string>
    #include<list>
    #include<iterator>
    #include<utility>
    #include<fstream>
    #include "symbolTable.h"
    #include "fileUtils.h"
    
    using namespace std;
    
    extern FILE* yyin;
    extern int lineCount;   
    extern int errorCount;
    
    extern string toUpper(string str);

    SymbolTable symbolTable(31);

    int labelCount = 0;
    int tempCount = 0;
    int asmLineCount = 0;
    int asmDataSegmentEndLine = 0;
    int asmCodeSegmentEndLine = 0;
    list<pair<string, string> > parameters; // Contains the parameter list <name, type> of the currently declared function
    list<SymbolInfo*> argList;              // Contans argument list while calling a function
    string varType;                         // Contains recent variable type
    string funcName, funcReturnType;
    bool hasDeclaredId = false, hasFuncDeclared = false, hasFuncDefined = false, hasFoundReturn = false;

    ofstream logFile;
    ofstream errorFile;
    ofstream codeFile;

    int yyparse(void);
    int yylex(void);

    /**
    * @returns a new label name that can be used in the assembly code
    */
    string newLabel() {
        string label = "L_" + to_string(++labelCount);
        return label;
    }

    /**
    * @returns a new template name that can be used in the assembly code
    */
    string newTemp() {
        string temp = "t" + to_string(tempCount++);
        return temp;
    }

    void logFoundRule(string variable, string rule, string matchedString) {
        logFile << "Line " << lineCount << ": " << variable << " : " << rule << "\n\n";
        logFile << matchedString << "\n\n";
    }

    void logFoundRule(string variable, string rule) {
        logFile << "Line " << lineCount << ": " << variable << " : " << rule << "\n\n";
    }

    void logMatchedString(string matchedString) {
        logFile << matchedString << "\n\n";
    }

    void errorMessage(string message) {
        errorCount++;
        errorFile << "Error at line " << lineCount << ": " << message << "\n\n";
        logFile << "Error at line " << lineCount << ": " << message << "\n\n";
    }

    void yyerror(string s) {
        errorMessage("Syntax Error");
        // cout << s << endl;
    }

    /**
     * increases the end line of code segment along with asmLineCount
     * @param incAmount amount by which the end line of code segment should be increased
     */
    void increaseCodeSegmentEndLine(int incAmount) {
        asmCodeSegmentEndLine += incAmount;
        asmLineCount += incAmount;
    }

    void insertId(string idName, string type, int arraySize = 0) {
        if(symbolTable.hasFunctionWithName(idName)) {
            errorMessage("Multiple declaration of " + idName + ". " + idName + " is a function");
        } else {
            SymbolInfo* idInfo = symbolTable.insert(idName, "ID", "CONST_" + toUpper(type), arraySize);
            if(idInfo == NULL) {
                errorMessage("Multiple declaration of " + idName);
            } else if(symbolTable.getCurrentScopeID() != "1" && errorCount == 0) {
                if(arraySize == 0) {
                    write("code.asm", "\t\tPUSH BX    ;line no " + to_string(lineCount) + ": " + idName + " declared", true);
                    increaseCodeSegmentEndLine(1);
                } else {
                    string str = "\t\t;line no " + to_string(lineCount) + ": declaring array " + idName + " with size " + to_string(arraySize);
                    for(int i=0; i<arraySize; i++) {
                        str += "\n\t\tPUSH BX";
                    }
                    str += "\n\t\t;array declared";
                    write("code.asm", str, true);
                    increaseCodeSegmentEndLine(arraySize + 2);
                }

                cout << idName << " offset = " << ((IdInfo*)idInfo)->getStackOffset() << endl;
            }
        }
    }

    /**
     * Checks if the two symbols have the same type or not.
     * If the types are not the same, it shows the message.
     * @param lSymbol left symbolInfo
     * @param rSymbol right symbolInfo
     * @param message show this error message if type mismatch occurs
     */
    void typeCheck(SymbolInfo* lSymbol, SymbolInfo* rSymbol, string message) {
        string lType = lSymbol->getType();
        string rType = rSymbol->getType();

        if(lType == "UNDEC" || rType == "UNDEC")
            return;

        if(lType != rSymbol->getType()) {
            if(lType[lType.size()-1] == '*')
                errorMessage(message +", " + lSymbol->getName() + " is an array");
            else if(rType[rType.size()-1] == '*')
                errorMessage(message + ", " + rSymbol->getName() + " is an array");
            else {
                errorMessage(message);
            }
        }
    }

    /**
     * Checks if the right symbols can be type casted to left symbol or not.
     * If type casting is not possible, it shows the message.
     * @param lSymbol left symbolInfo
     * @param rSymbol right symbolInfo
     * @param message show this error message if type casting fails
     */
    string typeCast(SymbolInfo* lSymbol, SymbolInfo* rSymbol, string message) {
        string lType = lSymbol->getType();
        string rType = rSymbol->getType();

        // if any of the two is an array then there should be no type casting
        if(lType[lType.size()-1] == '*' || rType[rType.size()-1] == '*') 
            typeCheck(lSymbol, rSymbol, message);
        // if lType is float then rType can be any of float, int or char
        // and it will be type casted to float
        else if(lType == "CONST_FLOAT")
            return "CONST_FLOAT";
        // if lType is int then rType can be any of int or char
        // and it will be type casted to int
        else if(lType == "CONST_INT" && (rType == "CONST_CHAR"  || rType == "CONST_INT"))
            return "CONST_INT";
        // else lType and rType have to be the same
        else 
            typeCheck(lSymbol, rSymbol, message);
        
        return lType;
    }

    /**
     * Checks if any of the symbol can be type casted to upper type
     * to match with the other symbol type.
     * If type casting is not possible, it shows the message.
     * @param lSymbol left symbolInfo
     * @param rSymbol right symbolInfo
     * @param message show this error message if type casting fails
     */
    string typeCastIgnoreSide(SymbolInfo* lSymbol, SymbolInfo* rSymbol, string message) {
        string lType = lSymbol->getType();
        string rType = rSymbol->getType();

        // if any of the two is an array then there should be no type casting
        if(lType[lType.size()-1] == '*' || rType[rType.size()-1] == '*') 
            typeCheck(lSymbol, rSymbol, message);
        // if any of the two is float then return float
        else if(lType == "CONST_FLOAT" || rType == "CONST_FLOAT")
            return "CONST_FLOAT";
        // if any of the two is int then return int
        else if(lType == "CONST_INT" || rType == "CONST_INT")
            return "CONST_INT";   
        // else lType and rType have to be the same
        else 
            typeCheck(lSymbol, rSymbol, message);    
        
        return lType;
    }

    bool isVoidFunc(string type) {
        if(type == "FUNC_VOID") {
            errorMessage("Void function used in expression");
            return true;
        } else {
            return false;
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
            
            int i = 0;
            while(it != parameters.end()) {
                // function definition must have parameter names
                if((*it).first == "")
                    errorMessage(to_string(i + 1) + "th parameter's name not given in function definition of " + funcName);

                functionInfo->addParameter("CONST_" + toUpper((*it).second));
                it++;
                i++;
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

        if(funcReturnType == functionInfo->getReturnType() && functionInfo->getName() != "main" &&
            functionInfo->getReturnType() != "CONST_VOID" && !hasFoundReturn) {
            errorMessage("Function definition of non void return type ended without any return statement");
        }
    }

    void printSummary() {
        logFile << symbolTable.getNonEmptyList() << '\n';
        logFile << "Total lines: " << lineCount << "\n";
        logFile << "Total errors: " << errorCount << "\n";
    }

    void declareGlobalVariable(string name, string type) {
        if(varType == "float") {
            cout << "Error: float type variable is not supported" << endl;
            errorMessage("float type variable is not supported");
        }

        if(errorCount > 0) {
            return;
        }

        string code = "\t" + name + " DW ?";
        asmLineCount++;
        writeAt("code.asm", code, asmDataSegmentEndLine++);
    }

    void declareGlobalArray(string name, string type, string arraySize) {
        if(varType == "float") {
            cout << "Error: float type variable is not supported" << endl;
            errorMessage("float type variable is not supported");
        }

        if(errorCount > 0) {
            return;
        }

        string code = "\t" + name + " DW " + arraySize + " DUP(?)";
        asmLineCount++;
        writeAt("code.asm", code, asmDataSegmentEndLine++);
    }

    void declareProcedure(string id) {
        if(errorCount > 0) {
            return;
        }

        string code = "\t" + toUpper(id) + " PROC";
        write("code.asm", code, true);
        increaseCodeSegmentEndLine(1);
    }

    void endProcedure(string id) {
        if(errorCount > 0) {
            return;
        }

        string code = "\t" + toUpper(id) + " ENDP";
        write("code.asm", code, true);
        increaseCodeSegmentEndLine(1);
    }

    void initializeAsmMain() {
        if(errorCount > 0) {
            return;
        }

        string code = "\t\tMOV AX, @DATA\n\t\tMOV DS, AX";
        write("code.asm", code, true);
        increaseCodeSegmentEndLine(2);
    }

    void terminateAsmMain() {
        if(errorCount > 0) {
            return;
        }

        string code = "\t\tMOV AH, 4CH\n\t\tINT 21H";
        write("code.asm", code, true);
        increaseCodeSegmentEndLine(2);
    }

    void writeInCodeSegment(string str, int noOfLines = 1) {
        if(errorCount > 0) {
            return;
        }

        write("code.asm", str, true);
        increaseCodeSegmentEndLine(noOfLines);
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
        logFoundRule("start", "program");
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
        string returnType = "CONST_" + toUpper($1->getName());
        string id = $2->getName();
        $$ = new SymbolInfo($1->getName() + " " + id + "(" + $4->getName() + ")", "parameter_list");

        handleFuncDeclaration(id, returnType);

        declareProcedure(id);

        if(id == "main") {
            initializeAsmMain();
        }

        delete $1;
        delete $2;
        delete $4;
}
|   type_specifier ID LPAREN parameter_list error RPAREN {
        string returnType = "CONST_" + toUpper($1->getName());
        string id = $2->getName();
        $$ = new SymbolInfo($1->getName() + " " + id + "(" + $4->getName() + ")", "parameter_list");

        handleFuncDeclaration(id, returnType);

        delete $1;
        delete $2;
        delete $4;
}
|   type_specifier ID LPAREN RPAREN {
        string returnType = "CONST_" + toUpper($1->getName());
        string id = $2->getName();
        $$ = new SymbolInfo($1->getName() + " " + id + "()", "");

        handleFuncDeclaration(id, returnType);

        declareProcedure(id);

        if(id == "main") {
            initializeAsmMain();
        }

        delete $1;
        delete $2;
}

func_declaration
:   func_prototype SEMICOLON {
        symbolTable.enterScope();
        symbolTable.exitScope();

        $$ = new SymbolInfo($1->getName() + ";", "VARIABLE");
        logFoundRule("func_declaration", "type_specifier ID LPAREN " + $1->getType() + " RPAREN SEMICOLON");

        if(hasFuncDeclared)
            errorMessage("Multiple declaration of " + funcName);
        
        hasDeclaredId = hasFuncDeclared = hasFuncDefined = false;
        funcName.clear();
        funcReturnType.clear();
        parameters.clear();

        logMatchedString($$->getName());
        delete $1;
    }
|   func_prototype error {
        symbolTable.enterScope();
        symbolTable.exitScope();

        $$ = $1;

        if(hasFuncDeclared)
            errorMessage("Multiple declaration of " + funcName);
        
        hasDeclaredId = hasFuncDeclared = hasFuncDefined = false;
        funcName.clear();
        funcReturnType.clear();
        parameters.clear();

        logMatchedString($$->getName());
}
;

func_definition
:   func_prototype compound_statement {
        $$ = new SymbolInfo($1->getName() + $2->getName(), "VARIABLE");
        logFoundRule("func_definition", "type_specifier ID LPAREN " + $1->getType() + " RPAREN compound_statement");
        
        handleFunctionDefinition();

        hasDeclaredId = hasFuncDeclared = hasFuncDefined = hasFoundReturn = false;
        funcName.clear();
        funcReturnType.clear();
        parameters.clear();

        logMatchedString($$->getName());
        delete $1;
        delete $2;
    }
;

enter_scope
:   {
        if(hasFuncDeclared) {
            FunctionInfo* functionInfo = (FunctionInfo*)symbolTable.lookUp(funcName);

            // check the return type
            if(funcReturnType != functionInfo->getReturnType()) {
                errorMessage("Return type mismatch with function declaration in function " + funcName);
            }

            if(functionInfo->getNumberOfParameters() != parameters.size()) {
                errorMessage("Total number of arguments mismatch with declaration in function " + funcName);
            }

            // Check if the parameter types matched with the function declaration
            int i = 0;
            for(pair<string, string> parameter : parameters) {
                if(("CONST_" + toUpper(parameter.second)) != functionInfo->getParameterTypeAtIdx(i)) {
                    errorMessage("Function parameter/s does not match with the declaration");
                }
                // function definition must have parameter names
                if(parameter.first == "")
                    errorMessage(to_string(i + 1) + "th parameter's name not given in function definition of " + funcName);
                i++;
            }
        }     

        symbolTable.enterScope();

        // Insert the parameters in the scope
        list<pair<string, string> >::iterator it = parameters.begin();

        while(it != parameters.end()) {      
            if((*it).first != "" && symbolTable.insert((*it).first, "ID", "CONST_" + toUpper((*it).second)) == NULL)
                errorMessage("Multiple declaration of " + (*it).first + " in parameter");
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
        logFoundRule("parameter_list", "parameter_list COMMA type_specifier ID");

        if(type == "void")
            errorMessage("Variable type cannot be void");

        logMatchedString($$->getName());

        delete $1;
        delete $3;
        delete $4;
    }
|   parameter_list COMMA type_specifier {
        string type = $3->getName();

        // Save the name and type of the parameter
        parameters.push_back(make_pair("", type));

        $$ = new SymbolInfo($1->getName() + "," + type, "VARIABLE");
        logFoundRule("parameter_list", "parameter_list COMMA type_specifier");
        
        if(type == "void")
            errorMessage("Variable type cannot be void");

        logMatchedString($$->getName());
        delete $1;
        delete $3;
    }
|   parameter_list COMMA error {
        $$ = $1;
        logMatchedString($$->getName());
}
|   type_specifier ID {
        string type = $1->getName();
        string id =  $2->getName();

        // Save the name and type of the parameter
        parameters.push_back(make_pair(id, type));

        $$ = new SymbolInfo(type + " " + id, "VARIABLE");
        logFoundRule("parameter_list", "type_specifier ID");

        if(type == "void")
            errorMessage("Variable type cannot be void");

        logMatchedString($$->getName());
        delete $1;
        delete $2;
    }
|   type_specifier {
        string type = $1->getName();

        // Save the name and type of the parameter
        parameters.push_back(make_pair("", type));

        $$ = $1;
        logFoundRule("parameter_list", "type_specifier");

        if(type == "void")
            errorMessage("Variable type cannot be void");
        
        logMatchedString($$->getName());
    }
;

compound_statement
:   LCURL enter_scope statements RCURL {
        $$ = new SymbolInfo("{\n" + $3->getName() + "\n}", "VARIABLE");
        logFoundRule("compound_statement", "LCURL statements RCURL", $$->getName());

        if(funcName == "main") {
            terminateAsmMain();
        }

        endProcedure(funcName);
        
        // Print the symbol table and then exit the current scope
        logFile << symbolTable.getNonEmptyList() << "\n\n";
        symbolTable.exitScope();

        delete $3;
    }
|   LCURL enter_scope RCURL {
        $$ = new SymbolInfo("{}", "VARIABLE");
        logFoundRule("compound_statement", "LCURL RCURL", $$->getName());

        if(funcName == "main") {
            terminateAsmMain();
        }
        
        endProcedure(funcName);
        
        logFile << symbolTable.getNonEmptyList() << "\n\n";
        symbolTable.exitScope();
    }
;

var_declaration
:   type_specifier declaration_list SEMICOLON {
        $$ = new SymbolInfo($1->getName() + " " + $2->getName() + ";", "VARIABLE");
        logFoundRule("var_declaration", "type_specifier declaration_list SEMICOLON");

        if(varType == "void")
            errorMessage("Variable type cannot be void");
        
        logMatchedString($$->getName());

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
|   VOID {
        varType = "void";

        $$ = new SymbolInfo("void", "VARIABLE");
        logFoundRule("type_specifier", "VOID", $$->getName());
    }
;

declaration_list
:   declaration_list COMMA ID {
        string id = $3->getName();
        
        $$ = new SymbolInfo($1->getName() + "," + id, "VARIABLE");
        logFoundRule("declaration_list", "declaration_list COMMA ID");

        insertId(id, varType);

        if(symbolTable.getCurrentScopeID() == "1")
            declareGlobalVariable(id, varType);
        else {
            // writeAsmCode("PUSH ");
        }

        logMatchedString($$->getName());

        delete $1;
        delete $3;
    }
|   declaration_list error ID {       
        // cout << "Error with " << $3->getName() << endl;  
        $$ = $1;
        delete $3;
}

|   declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
        string id = $3->getName();
        
        $$ = new SymbolInfo($1->getName() + "," + id + "[" + $5->getName() + "]", "VARIABLE");
        logFoundRule("declaration_list", "declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");

        insertId(id, varType + "*", stoi($5->getName()));
        if(symbolTable.getCurrentScopeID() == "1")
            declareGlobalArray(id, varType, $5->getName());

        logMatchedString($$->getName());

        delete $1;
        delete $3;
        delete $5;
    }
|   declaration_list COMMA ID LTHIRD error RTHIRD {
        string id = $3->getName();
        insertId(id, varType + "*");
        
        $$ = new SymbolInfo($1->getName() + "," + id + "[]", "VARIABLE");

        errorMessage("Expression inside third brackets not an integer");
        
        delete $1;
        delete $3;
}
|   ID {
        insertId($1->getName(), varType);

        if(symbolTable.getCurrentScopeID() == "1")
            declareGlobalVariable($1->getName(), varType);

        $$ = $1;
        logFoundRule("declaration_list", "ID", $$->getName());
    }
|   ID LTHIRD CONST_INT RTHIRD {
        string id = $1->getName();

        $$ = new SymbolInfo(id + "[" + $3->getName() + "]", "VARIABLE");
        logFoundRule("declaration_list", "ID LTHIRD CONST_INT RTHIRD");

        insertId(id, varType + "*", stoi($3->getName()));
        if(symbolTable.getCurrentScopeID() == "1")
            declareGlobalArray(id, varType, $3->getName());

        logMatchedString($$->getName());

        delete $1;
        delete $3;
    }
|   ID LTHIRD error RTHIRD {
        string id = $1->getName();
        insertId(id, varType + "*");
        
        $$ = new SymbolInfo(id + "[]", "VARIABLE");
        
        delete $1;
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
        $$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName() + "else\n" + $7->getName(), "VARIABLE");
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
        string id = $3->getName();
        $$ = new SymbolInfo("println(" + id + ");", "VARIABLE");
        logFoundRule("statement", "PRINTLN LPAREN ID RPAREN SEMICOLON");

        string str = "\n";
        IdInfo* idInfo = (IdInfo*)symbolTable.lookUp(id);
        str += "\t\tPUSH [BP + " + to_string(idInfo->getStackOffset()) + "]\t;passing " + id + " to PRINT_INTEGER\n";
        str += "\t\tCALL PRINT_INTEGER\n";
        writeInCodeSegment(str, 4);

        if(symbolTable.lookUp(id) == NULL) 
            errorMessage("Undeclared variable " + id);

        logMatchedString($$->getName());

        delete $3;
    }
|   PRINTLN LPAREN ID RPAREN error {
        string id = $3->getName();
        $$ = new SymbolInfo("printf(" + id + ")", "VARIABLE");

        if(symbolTable.lookUp(id) == NULL) 
            errorMessage("Undeclared variable " + id);

        logMatchedString($$->getName());

        delete $3;
}
|   RETURN expression SEMICOLON {
        hasFoundReturn = true;
        string type = $2->getType();
        string name = "return " + $2->getName() + ";";
        
        logFoundRule("statement", "RETURN expression SEMICOLON");

        if(funcReturnType != ""){
            if(funcReturnType == "CONST_FLOAT" && (type == "CONST_FLOAT" || type == "CONST_INT"))
                type = "CONST_FLOAT";
            else {
                SymbolInfo* tempSymbol = new SymbolInfo("dummy", funcReturnType);
                typeCast(tempSymbol, $2, "Return type does not match with the return value in function " + funcName);

                delete tempSymbol;
            }
        }
            
        logMatchedString(name);
        $$ = new SymbolInfo(name, type);
        delete $2;
    }
|   RETURN expression error {
        hasFoundReturn = true;
        string type = $2->getType();
        string name = "return " + $2->getName();

        if(funcReturnType != ""){
            if(funcReturnType == "CONST_FLOAT" && (type == "CONST_FLOAT" || type == "CONST_INT"))
                type = "CONST_FLOAT";
            else {
                SymbolInfo* tempSymbol = new SymbolInfo("dummy", funcReturnType);
                typeCast(tempSymbol, $2, "Return type does not match with the return value in function " + funcName);

                delete tempSymbol;
            }
        }
            
        logMatchedString(name);
        $$ = new SymbolInfo(name, type);
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
|   expression error {
        // cout << "Error at expression error " << $1->getName() << "\n";
        $$ = new SymbolInfo("", "ERROR");

        delete $1;
    }
;

variable
:   ID {
        string id = $1->getName();
        logFoundRule("variable", "ID");

        SymbolInfo* symbolInfo = symbolTable.lookUp(id);
        if(symbolInfo == NULL) {
            errorMessage("Undeclared variable " + id);
            $$ = new SymbolInfo(id, "UNDEC");
        } else {
            $$ = new SymbolInfo(symbolInfo->getName(), ((IdInfo*)symbolInfo)->getIdType());
        }
        
        logMatchedString(id);
        delete $1;
    }
|   ID LTHIRD expression RTHIRD {
        string id = $1->getName();
        string varType = "VARIABLE";
        string name = id + "[" + $3->getName() + "]";
        SymbolInfo* symbolInfo = symbolTable.lookUp(id);

        
        logFoundRule("variable", "ID LTHIRD expression RTHIRD");
        // check if the id is an array or not
        if(symbolInfo == NULL) {
            errorMessage("Undeclared variable " + id);
            varType = "UNDEC";
        } else if(symbolInfo->getType() == "ID") {
            IdInfo* idInfo = (IdInfo*)symbolInfo;
            string idType = idInfo->getIdType();

            if(idType.size() > 0 && idType[idType.size()-1] != '*') {
                errorMessage(id + " not an array");
                varType = idType;
            } else {
                // the type of the variable will be the original type of the array elements
                // So, truncate the '*'
                varType = idType.substr(0, idType.size() - 1);
            }            
        } else {
            errorMessage(id + " not an array");
            varType = symbolInfo->getType();
        }
        
        if($3->getType() != "CONST_INT")
            errorMessage("Expression inside third brackets not an integer");
        
        logMatchedString(name);

        $$ = new SymbolInfo(name, varType);
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
        string name = $1->getName() + "=" + $3->getName();
        string lType = $1->getType();
        string rType = $3->getType();
        string type = lType;
        
        logFoundRule("expression", "variable ASSIGNOP logic_expression");

        // TODO: might require changes
        IdInfo* idInfo = (IdInfo*)symbolTable.lookUp($1->getName());
        writeInCodeSegment("\t\tMOV [BP + " + to_string(idInfo->getStackOffset()) + "], " + $3->getName());

        if(isVoidFunc(rType)) {
            // Do nothing
            // Error message handled in isVoidFunction
        } else if(lType != "UNDEC"){
            typeCast($1, $3, "Type Mismatch");
        }
        // Undeclared variables are detected in 'variable' rule
        // and are handled there

        logMatchedString(name);

        $$ = new SymbolInfo(name, type);
        delete $1;
        delete $3;
    }
|   variable ASSIGNOP error {
        // cout << "Error at variable ASSIGNOP\n";
        $$ = $1;
        logMatchedString($1->getName());
}
;

logic_expression
:   rel_expression {
        $$ = $1;
        logFoundRule("logic_expression", "rel_expression", $$->getName());
    }
|   rel_expression LOGICOP rel_expression {
        $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "CONST_INT");
        logFoundRule("logic_expression", "rel_expression LOGICOP rel_expression");

        if(isVoidFunc($1->getType())) {
            // Do nothing
            // Error message handled in isVoidFunction
        } else if(isVoidFunc($3->getType())) {
            // Do nothing
            // Error message handled in isVoidFunction
        }
        // No need for a type check because, it is okay to have any arbitrary const on 
        // both sides of logical operator
        
        logMatchedString($$->getName());

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
        string lType = $1->getType();
        string rType = $3->getType();
        
        $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "CONST_INT");
        logFoundRule("rel_expression", "simple_expression RELOP simple_expression");

        if(isVoidFunc(lType)) {
            // Do nothing
            // Error message handled in isVoidFunction
        } else if(isVoidFunc(rType)) {
            // Do nothing
            // Error message handled in isVoidFunction
        } else {
            typeCastIgnoreSide($1, $3, "Type Mismatch");
        }

        logMatchedString($$->getName());

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
        string lType = $1->getType();
        string rType = $3->getType();
        string name = $1->getName() + $2->getName() + $3->getName();
        string type = rType;

        logFoundRule("simple_expression", "simple_expression ADDOP term");

        if(isVoidFunc(lType)) {
            // Do nothing
            // Error message handled in isVoidFunction
            // type is already equals rType
        }
        else if(isVoidFunc(rType)) {
            type = lType;
        } else {
            type = typeCastIgnoreSide($1, $3, "Type Mismatch");
        }

        logMatchedString(name);

        $$ = new SymbolInfo(name, type);
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
        string lType = $1->getType();
        string ueName = $3->getName();
        string rType = $3->getType();
        string name = $1->getName() + mulop + ueName;
        string type = rType;

        logFoundRule("term", "term MULOP unary_expression");

        if(isVoidFunc(lType)) {
            // Do nothing
            // Error message handled in isVoidFunction
            // Type is already equals rType
        }
        else if(isVoidFunc(rType)) {
            type = lType;
        } else if(mulop == "%") {
            if(lType != "CONST_INT" || rType != "CONST_INT")
                errorMessage("Non-Integer operand on modulus operator");
            else if(ueName == "0")
                errorMessage("Modulus by Zero");
            // result of modulus will always be integer
            type = "CONST_INT";
        } else if(mulop == "%" && ueName == "0") {
                errorMessage("Division by Zero");
        } else {
            type = typeCastIgnoreSide($1, $3, "Type Mismatch");
        }

        logMatchedString(name);

        $$ = new SymbolInfo(name, type);
        
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
        // It's a function call
        string id = $1->getName();
        string varName = id + "(" + $3->getName() + ")";
    
        logFoundRule("factor", "ID LPAREN argument_list RPAREN");
    
        SymbolInfo* symbolInfo = symbolTable.lookUp(id);
        
        if(symbolInfo == NULL) {
            // if it was not declared before
            errorMessage("Undeclared function " + id);
            $$ = new SymbolInfo(varName, "UNDEC");
        } else if(symbolInfo->getIsFunction()) {
            FunctionInfo* functionInfo = (FunctionInfo*)symbolInfo;
            // if it is a function then set the return type as the type of the expression
            string retType = functionInfo->getReturnType();
            if(retType == "CONST_VOID")
                retType = "FUNC_VOID";

            $$ = new SymbolInfo(varName, retType);
            // check the consistency of the prameters
            if(functionInfo->getNumberOfParameters() != argList.size())
                errorMessage("Total number of arguments mismatch in function " + id);
            else {
                int i = 0;
                list<SymbolInfo*>::iterator it = argList.begin();
                
                while(it != argList.end()) {
                    SymbolInfo* tempSymbol = new SymbolInfo("dummy", functionInfo->getParameterTypeAtIdx(i));
                    typeCast(tempSymbol, *it, to_string(1 + i) + "th argument mismatch in function " + id);
                    
                    delete tempSymbol;
                    delete (*it);
                    argList.erase(it++);
                    i++;
                }
            }

        } else {
            // then it must be an id. Set the id type as the type of the expression
            errorMessage(id + " is not a function");
            $$ = new SymbolInfo(varName, ((IdInfo*)symbolInfo)->getIdType());
        }
        
        // Clear the argList
        list<SymbolInfo*>::iterator it = argList.begin();
                
        while(it != argList.end()) {
            delete (*it);
            argList.erase(it++);
        }

        logMatchedString(varName);

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
|   CONST_CHAR {
        $$ = $1;
        logFoundRule("factor", "CONST_CHAR", $$->getName());
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
        argList.push_back(new SymbolInfo($3->getName(), $3->getType()));
        $$ = new SymbolInfo($1->getName() + "," + $3->getName(), "VARIABLE");
        logFoundRule("arguments", "arguments COMMA logic_expression", $$->getName());

        delete $1;
        delete $3;
    }
|   logic_expression {
        argList.push_back(new SymbolInfo($1->getName(), $1->getType()));
        $$ = $1;
        logFoundRule("arguments", "logic_expression", $$->getName());
    }
;

%%

/**
* Function that prints the code for println in code.asm
*/
void writeProcPrintln() {
    string str = "\t;println(n)\n";
    str += 
    "\tPRINT_INTEGER PROC NEAR\n\
        PUSH BP             ;Saving BP\n\
        MOV BP, SP          ;BP points to the top of the stack\n\
        MOV BX, [BP + 4]    ;The number to be printed\n\
        ;if(BX < -1) then the number is positive\n\
        CMP BX, 0\n\
        JGE POSITIVE\n\
        ;else, the number is negative\n\
        MOV AH, 2           \n\
        MOV DL, '-'         ;Print a '-' sign\n\
        INT 21H\n\
        NEG BX              ;make BX positive\n\
        POSITIVE:\n\
        MOV AX, BX\n\
        MOV CX, 0        ;Initialize character count\n\
        PUSH_WHILE:\n\
            XOR DX, DX  ;clear DX\n\
            MOV BX, 10  ;BX has the divisor //// AX has the dividend\n\
            DIV BX\n\
            ;quotient is in AX and remainder is in DX\n\
            PUSH DX     ;Division by 10 will have a remainder less than 8 bits\n\
            INC CX       ;CX++\n\
            ;if(AX == 0) then break the loop\n\
            CMP AX, 0\n\
            JE END_PUSH_WHILE\n\
            ;else continue\n\
            JMP PUSH_WHILE\n\
        END_PUSH_WHILE:\n\
        MOV AH, 2\n\
        POP_WHILE:\n\
            POP DX      ;Division by 10 will have a remaainder less than 8 bits\n\
            ADD DL, '0'\n\
            INT 21H     ;So DL will have the desired character\n\
            DEC CX       ;CX--\n\
            ;if(CX <= 0) then end loop\n\
            CMP CX, 0\n\
            JLE END_POP_WHILE\n\
            ;else continue\n\
            JMP POP_WHILE\n\
        END_POP_WHILE:\n\
        ;Print newline\n\
        MOV DL, 0DH\n\
        INT 21H\n\
        MOV DL, 0AH\n\
        INT 21H\n\
        POP BP          ; Restore BP\n\
        RET 2\n\
    PRINT_INTEGER ENDP";

    write("code.asm", str, true);
    increaseCodeSegmentEndLine(48);
}
/**
* Function that writes the required starting code to run the 8086 assembly code to the code.asm file
*/
void initializeAssembplyFile() {
    codeFile.open("code.asm");

    if(!codeFile.is_open()) {
        cout << "code.asm file could not be opened" << endl;
        return;
    }

    codeFile << ".MODEL SMALL\n";
    codeFile << ".STACK 400H\n";
    codeFile << ".DATA\n";
    asmLineCount += 3;
    asmDataSegmentEndLine = asmLineCount;

    codeFile << ".CODE\n";
    asmCodeSegmentEndLine = ++asmLineCount;

    codeFile.close();
    
}

/**
* Function that writes the required ending code to run the 8086 assembly code to the code.asm file
*/
void terminateAssemblyCode() {
    codeFile.open("code.asm", ios_base::app);

    if(!codeFile.is_open()) {
        cout << "code.asm file could not be opened" << endl;
        return;
    }

    codeFile << "END MAIN\n";
    asmLineCount++;

    codeFile.close();
}

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
    
    initializeAssembplyFile();
    writeProcPrintln();
    
    yyin = fin;
    yyparse();

    terminateAssemblyCode();

    errorFile.close();
    logFile.close();
    codeFile.close();
    fclose(fin);
    
    return 0;
}