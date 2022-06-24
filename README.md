# A C Compiler

## Chosen Subset of The C Language

Our chosen subset of the C language has the following characteristics:
- There can be `multiple functions`. `No two functions will have the same name`. A function `needs
to be defined or declared before it is called`. Also, a `function and a global variable cannot have
the same symbol`.
- There will be `no pre-processing directives` like `#include` or `#define`.
- Variables can be declared at suitable places inside a function. Variables can also be declared in
the global scope.
- Precedence and associativity
rules are as per standard. Although we `will ignore consecutive logical operators or consecutive
relational operators like, a && b && c, a < b < c`.
- `No break statement and switch-case statement` will be used.

## Syntax Analysis

TODO 1:
```cpp
declaration_list
:   declaration_list COMMA ID ASSIGNOP CONST_FLOAT {
        $$ = new SymbolInfo($1->getName() + "," + $3->getName() + "=" + $5->getName(), "VARIABLE");
        logFoundRule("declaration_list", "declaration_list COMMA ID ASSIGNOP CONST_FLOAT", $$->getName());
        
        delete $1;
        delete $3;
        delete $5;
    }
|   ID ASSIGNOP CONST_FLOAT {
        $$ = new SymbolInfo($1->getName() + "=" + $3->getName(), "VARIABLE");
        logFoundRule("declaration_list", "ID ASSIGNOP CONST_FLOAT", $$->getName());
        
        delete $1;
        delete $3;
    }   
|   ID error CONST_FLOAT {}
```

`TODO 2:`

        use ARITHASSIGNOP

`TODO 3:`

    Only pass const token for any of int, float or char