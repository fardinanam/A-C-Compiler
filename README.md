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