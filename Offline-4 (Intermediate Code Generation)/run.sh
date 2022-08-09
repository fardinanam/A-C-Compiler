flex lex.l
echo "lex.yy.c created."
bison -d -t parser.y
echo "parser.tab.h and parser.tab.c created."
g++ -fpermissive lex.yy.c parser.tab.c -lfl -o parser.out
echo "compilation completed. parser.out is ready to execute."
echo "parser.out executed."
./parser.out input.c