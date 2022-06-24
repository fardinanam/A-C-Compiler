%option noyywrap

%x CHAR_STATE
%x STRING_STATE
%x MLINE_COMMENT_STATE1
%x MLINE_COMMENT_STATE2

%{

#include<iostream>
#include<fstream>
#include<string>
#include "symbolTable.h"
#include"parser.tab.h"

using namespace std;

// extern YYSTYPE yylval;
extern ofstream logFile;
extern ofstream errorFile;

SymbolTable symbolTable(29);

int lineCount = 1;
int errorCount = 0;
int tempLineNo;

string charLiteral;
string lexeme;

ofstream tokenFile;

// SymbolTable symbolTable(7);

string toUpper(string str) {
    string tempStr = "";

    for(int i = 0; i < str.length(); i++) {
        char c = str[i];
        if(c >= 'a' && c <= 'z')
            tempStr.push_back(c - 'a' + 'A');
        else
            tempStr.push_back(c);
        
    }

    return tempStr;
}

void logFoundMessage(string token, string lexeme) {
    // logFile << "Line no. "<< lineCount << ": Token <" << token << "> Lexeme " << lexeme << " found.\n\n";
}

void logFoundMessage(string token, string lexeme, string charLiteral) {
    // logFile << "Line no. "<< lineCount << ": Token <" << token << "> Lexeme " 
    //     << lexeme << " found --> <" << token << ", " << charLiteral << ">\n\n";
}

void logFoundMessage(string token, string lexeme, int lineNo) {
    // logFile << "Line no. "<< lineNo << ": Token <" << token << "> Lexeme " << lexeme << " found.\n\n";
}

void logFoundMessage(string token, string lexeme, string charLiterals, int lineNo) {
    // logFile << "Line no. "<< lineNo << ": Token <" << token << "> Lexeme " 
    //     << lexeme << " found --> <" << token << ", " << charLiterals << ">\n\n";
}

void logErrorMessage(string errorMessage, string symbol) {
    errorCount++;
    // logFile << "Line no. "<< lineCount << ": ERROR: " << errorMessage << " " << symbol << "\n\n";
}

void logErrorMessage(string errorMessage, string symbol, int lineNo) {
    errorCount++;
    // logFile << "Line no. "<< lineNo << ": ERROR: " << errorMessage << " " << symbol << "\n\n";
}

void writeTokenFile(string token) {
    // tokenFile << "<" << token << "> ";
}

void writeTokenFile(string token, string charLiteral) {
    // tokenFile << "<" << token << ", " << charLiteral << "> ";
}

// void insertSymbol(string token, string lexeme) {
//     if(symbolTable.insert(lexeme, token)) 
//         logFile << symbolTable.getNonEmptyList() << '\n';
//     else
//         logFile << lexeme + " already exists in current ScopeTable\n\n";
// }

// void exitScope() {
//     symbolTable.exitScope();
//     logFile << symbolTable.getNonEmptyList() << '\n';
// }

// void printSummary() {
//     logFile << symbolTable.getNonEmptyList() << '\n';
//     logFile << "Total lines: " << lineCount << "\n";
//     logFile << "Total errors: " << errorCount << "\n";
// }

char extractChar(string str) {
    char c;

    if(str[0] == '\\') {
        // cout << "In if\n";
        switch(str[1]) {
            case 'n':
                c = '\n';
                break;
            case 't':
                c = '\t';
                break;
            case '\\':
                c = '\\' ;
                break;
            case '\'':
                c = '\'';
                break;
            case 'a':
                c = '\a';
                break;
            case 'f':
                c = '\f';
                break;
            case 'r':
                c = '\r';
                break;
            case 'b':
                c = '\b';
                break;
            case 'v':
                c = '\v';
                break;
            case '0':
                c = '\0';
                break;
            case '"':
                c = '\"';
                break;
            default:
                return -1;
        } 
    } else {
        c = str[0];
    }

    return c;
}

%}

DIGIT [0-9]
NEWLINE \n|\r\n
INT {DIGIT}+
FLOAT (({INT}("."{INT}?)?)|("."{INT}))(([eE][+-]?)?{INT})?
ID [a-zA-Z_][a-zA-Z0-9_]*

%%

if {return IF;}
else {return ELSE;}
for {return FOR;}
while {return WHILE;}
do {return DO;}
break {return BREAK;}
int {return INT;}
char {return CHAR;}
float {return FLOAT;}
double {return DOUBLE;}
void {return VOID;}
return {return RETURN;}
switch {return SWITCH;}
case {return CASE;}
default {return DEFAULT;}
continue {return CONTINUE;}
printf {return PRINTLN;}

{ID} {
    yylval.symbolInfo = new SymbolInfo(yytext ,"ID");
    return ID;
}

{INT} {
    yylval.symbolInfo = new SymbolInfo(yytext, "CONST_INT");
    return CONST_INT;
}

{FLOAT} {
    yylval.symbolInfo = new SymbolInfo(yytext, "CONST_FLOAT");
    return CONST_FLOAT;
}

{FLOAT}{ID}+ {
    logErrorMessage("Invalid Suffix on number or invalid prefix on ID", yytext);
}
(({INT}(.{INT}?)?)|(.{INT}?))([eE][+-]?{FLOAT}+) {
    logErrorMessage("Ill formed number", yytext);
}

{DIGIT}*"."({DIGIT}*([eE][+-]?)?{DIGIT}*"."{DIGIT}*)+ {
    logErrorMessage("Too many decimal point for the character sequence", yytext);
}

[+-] {
    yylval.symbolInfo = new SymbolInfo(yytext, "ADDOP");
    return ADDOP;
}

[*/%] {
    yylval.symbolInfo = new SymbolInfo(yytext, "MULOP");
    return MULOP;
}

"++"|"--" {
    yylval.symbolInfo = new SymbolInfo(yytext, "INCOP");
    return INCOP; 
}

"<"|"<="|">"|">="|"=="|"!=" {
    yylval.symbolInfo = new SymbolInfo(yytext, "RELOP");
    return RELOP;
}

= {return ASSIGNOP;}

"+="|"-="|"*="|"/=" {
    yylval.symbolInfo = new SymbolInfo(yytext, "ARITHASSIGNOP");
    return ARITHASSIGNOP;
}

&&|"||" {
    yylval.symbolInfo = new SymbolInfo(yytext, "LOGICOP");
    return LOGICOP;
}

! {return NOT;}

"(" {return LPAREN;}
")" {return RPAREN;}

"{" {return LCURL;}

"}" {
    logFile << symbolTable.getNonEmptyList() << "\n";
    symbolTable.exitScope();
    return RCURL;
}

"[" {return LTHIRD;}
"]" {return RTHIRD;}

, {return COMMA;}

; {return SEMICOLON;}

' {
    lexeme = yytext;
    charLiteral = "";
    BEGIN CHAR_STATE;
}

<CHAR_STATE>' {
    lexeme += yytext;

    if(charLiteral.length() == 0) {    
        logErrorMessage("Empty character constant", lexeme);
        lexeme.clear();
        charLiteral.clear();
        BEGIN INITIAL;
    } else if(charLiteral.length() == 1 && charLiteral[0] == '\\') {
        charLiteral += yytext;
    } else if((charLiteral[0] == '\\' && charLiteral.length() == 2) || charLiteral.length() == 1) {
        char c = extractChar(charLiteral);

        if(c == -1) {
            logErrorMessage("Unknown escape sequence: ", lexeme);
        } else {
            string token = "CONST_CHAR";
            charLiteral = "";
            charLiteral.push_back(c);
            
            writeTokenFile(token, charLiteral);
            logFoundMessage(token, lexeme, charLiteral);
            // insertSymbol(token, lexeme);
        }
        
        lexeme.clear();
        charLiteral.clear();

        BEGIN INITIAL;
    } else if(charLiteral.length() > 1) {
        logErrorMessage("Multi character constant char", lexeme);
        
        lexeme.clear();
        charLiteral.clear();

        BEGIN INITIAL;
    }
}

<CHAR_STATE>[^\r\n] {
    lexeme += yytext;
    charLiteral += yytext;
}

<CHAR_STATE>{NEWLINE} {
    logErrorMessage("Unfinished character", lexeme);
    lineCount++;
    lexeme.clear();
    charLiteral.clear();

    BEGIN INITIAL;
}

<CHAR_STATE><<EOF>> {
    logErrorMessage("Unfinished character", lexeme);
    lexeme.clear();
    charLiteral.clear();
    // printSummary();
    return 0;
}


\" {
    tempLineNo = lineCount;
    charLiteral = "";
    lexeme = yytext;
    BEGIN STRING_STATE;
}
<STRING_STATE>[^\r\n\"] {
    charLiteral += yytext;
    lexeme += yytext;
}
<STRING_STATE>\\[^ \t\r\n] {
    lexeme += yytext;
    char c = extractChar(yytext);

    if(c == -1) {
        logErrorMessage("Unknown escape sequence in string: ", lexeme);
        charLiteral.clear();
        lexeme.clear();
        BEGIN INITIAL;
    } else if(c == '\b') {
        // backspace
        if(charLiteral.length() > 0)
            charLiteral.pop_back();
    } else {
        charLiteral.push_back(c);
    }
}
<STRING_STATE>\\\n {
    lineCount++;
    lexeme += yytext;
}

<STRING_STATE>\" {
    string token = "STRING";
    lexeme += yytext;
    
    charLiteral = "\"" + charLiteral + "\"";
    writeTokenFile(token, charLiteral);
    logFoundMessage(token, lexeme, charLiteral, tempLineNo);
    
    charLiteral.clear();
    lexeme.clear();
    BEGIN INITIAL;
}

<STRING_STATE>{NEWLINE} {
    lexeme += yytext;
    logErrorMessage("Unterminated string", lexeme, tempLineNo);
    lineCount++;
    lexeme.clear();
    charLiteral.clear();
    BEGIN INITIAL;
}

<STRING_STATE><<EOF>> {
    logErrorMessage("Unterminated string", lexeme, tempLineNo);
    // printSummary();
    lexeme.clear();
    charLiteral.clear();
    return 0;
}

"//"[^\r\n]* logFoundMessage("COMMENT", yytext);

"//"[^\r\n]*\\{NEWLINE} {
    tempLineNo = lineCount;
    lineCount++;
    BEGIN MLINE_COMMENT_STATE1;
    lexeme = yytext;
}

<MLINE_COMMENT_STATE1>[^\r\n]*\\{NEWLINE} {
    lineCount++;
    lexeme += yytext;
}

<MLINE_COMMENT_STATE1>[^\r\n]* {
    lexeme += yytext;
    logFoundMessage("COMMENT", lexeme, tempLineNo);
    lexeme.clear();
    BEGIN INITIAL;
}
<MLINE_COMMENT_STATE1><<EOF>> {
    logErrorMessage("Unterminated comment", lexeme, tempLineNo);
    // printSummary();
    return 0;
}

"/*" {
    tempLineNo = lineCount;
    lexeme = yytext;
    BEGIN MLINE_COMMENT_STATE2;
}

<MLINE_COMMENT_STATE2>"*/"[ \t]* {
    lexeme += "*/";
    logFoundMessage("COMMENT", lexeme, tempLineNo);
    lexeme.clear();
    BEGIN INITIAL;
}

<MLINE_COMMENT_STATE2>[^\r\n] {
    lexeme += yytext;
}

<MLINE_COMMENT_STATE2>{NEWLINE} {
    lineCount++;
    lexeme += yytext;
}

<MLINE_COMMENT_STATE2><<EOF>> {
    logErrorMessage("Unterminated comment", lexeme, tempLineNo);
    // printSummary();
    return 0;
}

<<EOF>> {
    // printSummary();
    return 0;
}

[^ \t\n] {logErrorMessage("Unrecongnized character", yytext);}
[ \t\f\r\v]+ {}
{NEWLINE} lineCount++;

%%