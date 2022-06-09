%option noyywrap

%x CHAR_STATE
%x STRING_STATE
%x MLINE_COMMENT_STATE1
%x MLINE_COMMENT_STATE2

%{

#include<iostream>
#include<fstream>
#include<string>

using namespace std;

int lineCount = 1;
int errorCount = 0;
int tempLineNo;
string str;
string temp;

ofstream logFile;
ofstream tokenFile;

#include "symbolTable.h"
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
    // while(*str) {
    //     char c = *tempStr;

    //     if(c >= 'a' && c <= 'z')
    //         *tempStr = c - 'a' + 'A';
        
    //     tempStr++;
    // }

    return tempStr;
}

void logFoundMessage(string token, string lexeme) {
    logFile << "Line no. "<< lineCount << ": Token <" << token << "> Lexeme " << lexeme << " found.\n\n";
}

void logFoundMessage(string token, string lexeme, int lineNo) {
    logFile << "Line no. "<< lineNo << ": Token <" << token << "> Lexeme " << lexeme << " found.\n\n";
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
                logErrorMessage("Unknown escape sequence: ", str);
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

%%

if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue {
    string token = toUpper(yytext);
    logFoundMessage(token, yytext);
    writeTokenFile(token);
}
{DIGIT}+{LETTER}+ {
    logErrorMessage("Invalid Suffix on number or invalid prefix on ID", yytext);
}
{DIGIT}*"."({DIGIT}*"."{DIGIT}*)+ {
    logErrorMessage("Too many decimal point for the character sequence", yytext);
}
{DIGIT}+"."?[Ee]({DIGIT}*"."{DIGIT}*)* {
    logErrorMessage("Ill formed number", yytext);
}
[a-zA-Z_][a-zA-Z0-9_]* {
    string token = "ID";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
    insertSymbol(token, yytext);
}
{DIGIT}+ {
    string token = "CONST_INT";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
    insertSymbol(token, yytext);
}
{DIGIT}*("."{DIGIT}+)?([eE][+-]?{DIGIT}+)? {
    string token = "CONST_FLOAT";
    logFoundMessage(token, yytext);
    writeTokenFile(token, yytext);
    insertSymbol(token, yytext);
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
    str = "";
    BEGIN CHAR_STATE;
}

<CHAR_STATE>' {
    if(str.length() == 0) {
        str = "'" + str + "'";
        logErrorMessage("Empty character constant", str);
        str.clear();
        BEGIN INITIAL;
    } else if(str.length() == 1 && str[0] == '\\') {
        str += yytext;
    } else if((str[0] == '\\' && str.length() == 2) || str.length() == 1) {
        string token = "CONST_CHAR";
        temp.push_back(extractChar(str));
        str = "'" + str + "'";

        writeTokenFile(token, temp);
        logFoundMessage(token, str);
        insertSymbol(token, str);

        temp.clear();
        str.clear();

        BEGIN INITIAL;
    } else if(str.length() > 1) {
        str = "'" + str + "'";
        logErrorMessage("Multi character constant char", str);
        str.clear();
        BEGIN INITIAL;
    }
}

<CHAR_STATE>[^\r\n] {
    str += yytext;
}

<CHAR_STATE>{NEWLINE} {
    lineCount++;
    str = "'" + str;
    logErrorMessage("Unfinished character", str);
    str.clear();
    BEGIN INITIAL;
}

<CHAR_STATE><<EOF>> {
    str = "'" + str;
    logErrorMessage("Unfinished character", str);
    str.clear();
    printSummary();
    return 0;
}


\" {
    tempLineNo = lineCount;
    str = "";
    temp = yytext;
    BEGIN STRING_STATE;
}
<STRING_STATE>[^\r\n\"] {
    str += yytext;
    temp += yytext;
}
<STRING_STATE>\\[nt\\'afrbv0"] {
    temp += yytext;
    str.push_back(extractChar(yytext));
}
<STRING_STATE>\\\n {
    lineCount++;
    temp += yytext;
}

<STRING_STATE>\" {
    string token = "STRING";
    temp += yytext;
    logFoundMessage(token, temp, tempLineNo);
    str = "\"" + str + "\"";
    writeTokenFile(token, str);
    str.clear();
    temp.clear();
    str.clear();
    BEGIN INITIAL;
}

<STRING_STATE>{NEWLINE} {
    temp += yytext;
    logErrorMessage("Unterminated string", temp, tempLineNo);
    lineCount++;
    temp.clear();
    str.clear();
    BEGIN INITIAL;
}

<STRING_STATE><<EOF>> {
    logErrorMessage("Unterminated string", temp, tempLineNo);
    printSummary();
    temp.clear();
    str.clear();
    return 0;
}

"//"[^\r\n]* logFoundMessage("COMMENT", yytext);

"//"[^\r\n]*\\[ \t]*{NEWLINE} {
    tempLineNo = lineCount;
    lineCount++;
    BEGIN MLINE_COMMENT_STATE1;
    temp = yytext;
}

<MLINE_COMMENT_STATE1>[^\r\n]*\\[ \t]*{NEWLINE} {
    lineCount++;
    temp += yytext;
}

<MLINE_COMMENT_STATE1>[^\r\n]* {
    temp += yytext;
    logFoundMessage("COMMENT", temp, tempLineNo);
    temp.clear();
    BEGIN INITIAL;
}

"/*" {
    tempLineNo = lineCount;
    str = yytext;
    BEGIN MLINE_COMMENT_STATE2;
}

<MLINE_COMMENT_STATE2>"*/"[ \t]* {
    str += "*/";
    logFoundMessage("COMMENT", str, tempLineNo);
    str.clear();
    BEGIN INITIAL;
}

<MLINE_COMMENT_STATE2>[^\r\n] {
    str += yytext;
}

<MLINE_COMMENT_STATE2>{NEWLINE} {
    lineCount++;
    str += yytext;
}

<MLINE_COMMENT_STATE2><<EOF>> {
    logErrorMessage("Unterminated comment", str, tempLineNo);
    printSummary();
    return 0;
}

<<EOF>> {
    printSummary();
    return 0;
}

[^ \t\n] {logErrorMessage("Unrecongnized character", yytext);}
[ \t\f\r\v]+ {}
\n lineCount++;
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