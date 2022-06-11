flex lex.l
g++ lex.yy.c -o lex.yy.out
lex.yy.out input.txt