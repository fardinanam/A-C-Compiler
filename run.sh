flex -o lex.yy.c lex.l
g++ lex.yy.c -lfl -o lex.yy.out
./lex.yy.out input.txt