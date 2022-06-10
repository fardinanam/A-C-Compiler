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

using namespace std;

int lineCount = 1;
int errorCount = 0;
int tempLineNo;

string charLiteral;
string lexeme;

ofstream logFile;
ofstream tokenFile;


SymbolTable symbolTable(7);

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
    logFile << "Line no. "<< lineCount << ": Token <" << token << "> Lexeme " << lexeme << " found.\n\n";
}

void logFoundMessage(string token, string lexeme, string charLiteral) {
    logFile << "Line no. "<< lineCount << ": Token <" << token << "> Lexeme " 
        << lexeme << " found --> <" << token << ", " << charLiteral << ">\n\n";
}

void logFoundMessage(string token, string lexeme, int lineNo) {
    logFile << "Line no. "<< lineNo << ": Token <" << token << "> Lexeme " << lexeme << " found.\n\n";
}

void logFoundMessage(string token, string lexeme, string charLiterals, int lineNo) {
    logFile << "Line no. "<< lineNo << ": Token <" << token << "> Lexeme " 
        << lexeme << " found --> <" << token << ", " << charLiterals << ">\n\n";
}

void logErrorMessage(string errorMessage, string symbol) {
    errorCount++;
    logFile << "Line no. "<< lineCount << ": ERROR: " << errorMessage << " " << symbol << "\n\n";
}

void logErrorMessage(string errorMessage, string symbol, int lineNo) {
    errorCount++;
    logFile << "Line no. "<< lineNo << ": ERROR: " << errorMessage << " " << symbol << "\n\n";
}

void writeTokenFile(string token) {
    tokenFile << "<" << token << "> ";
}

void writeTokenFile(string token, string lexeme) {
    tokenFile << "<" << token << ", " << lexeme << "> ";
}

void insertSymbol(string token, string lexeme) {
    if(symbolTable.insert(lexeme, token)) 
        logFile << symbolTable.getNonEmptyList() << '\n';
    else
        logFile << lexeme + " already exists in current ScopeTable\n\n";
}

void exitScope() {
    symbolTable.exitScope();
    logFile << symbolTable.getNonEmptyList() << '\n';
}

void printSummary() {
    logFile << "Total lines: " << lineCount << "\n";
    logFile << "Total errors: " << errorCount << "\n";
}

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
LETTER [a-zA-Z]
NEWLINE \n|\r\n
INT {DIGIT}+
FLOAT ({INT}|("."{INT})?|{INT}"."{INT})([eE][+-]?{INT})?
ID [a-zA-Z_][a-zA-Z0-9_]*

%%

if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue {
    string token = toUpper(yytext);
    logFoundMessage(token, yytext);
    writeTokenFile(token);
}
{ID} {
    string token = "ID";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
    insertSymbol(token, yytext);
}
{INT} {
    string token = "CONST_INT";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
    insertSymbol(token, yytext);
}
{FLOAT} {
    string token = "CONST_FLOAT";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
    insertSymbol(token, yytext);
}
{FLOAT}{ID}+ {
    logErrorMessage("Invalid Suffix on number or invalid prefix on ID", yytext);
}
{DIGIT}*"."({DIGIT}*([eE][+-]?)?{DIGIT}*"."{DIGIT}*)+ {
    logErrorMessage("Too many decimal point for the character sequence", yytext);
}
({INT}?"."[Ee][+-]?{DIGIT}*)|({INT}[eE]{INT}?"."{INT}) {
    logErrorMessage("Ill formed number", yytext);
}
{INT}"." {
    logErrorMessage("Unfinished number", yytext);
}

[+-] {
    string token = "ADDOP";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
[*/%] {
    string token = "MULOP";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
"++"|"--" {
    string token = "INCOP";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);    
}
"<"|"<="|">"|">="|"=="|"!=" {
    string token = "RELOP";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
= {
    string token = "ASSIGNOP";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
&&|"||" {
    string token = "LOGICOP";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
! {
    string token = "NOT";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
"(" {
    string token = "LPAREN";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
")" {
    string token = "RPAREN";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
"{" {
    string token = "LCURL";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
    symbolTable.enterScope();
}
"}" {
    string token = "RCURL";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
    exitScope();
}
"[" {
    string token = "LTHIRD";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
"]" {
    string token = "RTHIRD";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
, {
    string token = "COMMA";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}
; {
    string token = "SEMICOLON";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
}

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
            insertSymbol(token, lexeme);
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
    printSummary();
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
<STRING_STATE>\\[nt\\'afrbv0"] {
    lexeme += yytext;
    charLiteral.push_back(extractChar(yytext));
}
<STRING_STATE>\\\n[ \t\r] {
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
    charLiteral.clear();
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
    printSummary();
    lexeme.clear();
    charLiteral.clear();
    return 0;
}

"//"[^\r\n]* logFoundMessage("COMMENT", yytext);

"//"[^\r\n]*\\[ \t]*{NEWLINE} {
    tempLineNo = lineCount;
    lineCount++;
    BEGIN MLINE_COMMENT_STATE1;
    lexeme = yytext;
}

<MLINE_COMMENT_STATE1>[^\r\n]*\\[ \t]*{NEWLINE} {
    lineCount++;
    lexeme += yytext;
}

<MLINE_COMMENT_STATE1>[^\r\n]* {
    lexeme += yytext;
    logFoundMessage("COMMENT", lexeme, tempLineNo);
    lexeme.clear();
    BEGIN INITIAL;
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
    printSummary();
    return 0;
}

<<EOF>> {
    printSummary();
    return 0;
}

[^ \t\n] {logErrorMessage("Unrecongnized character", yytext);}
[ \t\f\r\v]+ {}
{NEWLINE} lineCount++;

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
	tokenFile.open("1805087_token.txt");

    yyin = fin;
    yylex();
    fclose(fin);

    return 0;
}