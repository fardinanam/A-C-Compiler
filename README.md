# A C Compiler

## Introduction

This is a C compiler that performs some error checking with the help of Flex (lexer) and Bison (YACC parser) and then it converts the C code to 8086 assembly language code. It is not a complete c compiler but covers most of the basic features of the language. For more details, see <a href="#syntax-analyser">here</a>.

## Lexical Analyser

### Lexer returns the following tokens to the parser:

- Keywords

        Matched lexeme  :       Returned Token

        if              :       IF
        else            :       ELSE
        for             :       FOR
        while           :       WHILE
        do              :       DO
        break           :       BREAK
        int             :       INT
        char            :       CHAR
        float           :       FLOAT
        double          :       DOUBLE
        void            :       VOID
        return          :       RETURN
        switch          :       SWITCH
        case            :       CASE
        default         :       DEFAULT
        continue        :       CONTINUE

- Constants

        Returned Tokens

        CONST_INT
        CONST_FLOAT
        CONST_CHAR

- Operators and punctuators

        Matched Lexeme          :       Returned Token

        +, -                    :       ADDOP           *
        *, /, %                 :       MULOP           *
        ++, --                  :       INCOP           *
        <, <=, >, >=, ==, !=    :       RELOP           *
        =                       :       ASSIGNOP
        &&, ||                  :       LOGICOP         *
        !                       :       NOT
        (                       :       LPAREN
        )                       :       RPAREN
        {                       :       LCURL
        }                       :       RCURL
        [                       :       LTHIRD
        ]                       :       RTHIRD
        ,                       :       COMMA
        ;                       :       SEMICOLON

- Identifiers

        ID                                              *

- Strings

        STRING


- **Whitespaces and comments are identified by the lexer but these are not passed to the parser.**
- **Lexer also counts the line numbers when it finds a newline.**

*Tokens with * are passed as SymbolInfo objects to the parser. The SymbolInfo contains <matched lexeme, returned token> of the lexeme* 

### Lexical Errors:

Detect lexical errors in the source program and reports it along with corresponding line no. Detects the following type of errors:
- Too many decimal point error for character sequence like `1.2.345`
- Ill formed number such as `1E10.7`
- Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence like `12abcd`
- Multi character constant error for character sequence like `‘ab’`
- Unfinished character such as `‘a` , `‘\n` or `‘\’`
- Empty character constant error `''`
- Unfinished string like `"this is an unfinished string `
- Unfinished comment like `/* This is an unfinished comment `
- Unrecognized character (Any character that does not match any defined regular expressions)
- **Also counts the total number of errors.**

## Syntax Analyser

### Our chosen subset of the C language has the following characteristics:
- There can be multiple functions. No two functions will have the same name. A function needs
to be defined or declared before it is called. Also, a function and a global variable cannot have the same symbol.
- There will be no pre-processing directives like `#include` or `#define`.
- Variables can be declared at suitable places inside a function. Variables can also be declared in
the global scope.
- Precedence and associativity rules are as per standard. Although we will ignore consecutive logical operators or consecutive
relational operators like, `a && b && c`, `a < b < c`.
- No `break` statement and `switch-case` statement will be used.

### Error recovery:
Some common syntax errors are handled and recovered so that the parser does not stop parsing.

## Semantic Analyser
### Following semantics are checked in the compiler:
<div>
<details>
<summary>
        Type Checking 
</summary>
<ol>
<li>
        Generates error message if operands of an assignment operator are not consistent with each other. The second operand of the assignment operator will be an expression that may contain numbers, variables, function calls, etc.
</li>
<li> 
        Generates an error message if the index of an array is not an integer.
</li>
<li> 
        Both the operands of the modulus operator should be integers.
</li>
        During a function call all the arguments should be consistent with the function definition.
<li>
        A void function cannot be called as a part of an expression.
</li>
</ol>
</details>
<details>
<summary>
        Type Conversion 
</summary>
        Conversion from float to integer in any expression generates an error. Also, the result of RELOP and LOGICOP operations are integers.
</details>
<details>
<summary>
        Uniqueness Checking
</summary>
        Checks whether a variable used in an expression is declared or not. Also, checks whether there are multiple declarations of variables with the same ID in the same scope.
</details>
<details>
<summary>
        Array Index
</summary>
        Checks whether there is an index used with array and vice versa.
</details>
<details>
<summary>
        Function Parameters
</summary>
        Check whether a function is called with appropriate number of parameters with appropriate types. Function definitions should also be consistent with declaration if there is any. Besides that, a function call cannot be made with non-function type identifier.
</details>

### Non terminal data types used:
Used to check the consistancy of different terms and expressions with variable types.
- Trivial data types: 

        CONST_INT  
        CONST_FLOAT
        CONST_CHAR
        CONST_INT*
        CONST_FLOAT*
        CONST_CHAR* 

- Other data types:
        
        UNDEC (If an ID is found which has never been declared)
        ERROR (If an expression contains error/s)
        FUNC_VOID (If the return type of a function is void. This is only used in function calls to check if a void function is used in an expression or not)
        VARIABLE (Any other type of non terminals.)
        

