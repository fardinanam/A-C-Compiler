flex lex.l
echo "lex.yy.c created."
bison -d -t parser.y
echo "parser.tab.h and parser.tab.c created."
g++ -fpermissive lex.yy.c parser.tab.c -lfl -o parser.out
echo "compilation completed. parser.out is ready to execute."
echo "parser.out executed."
./parser.out input.txt



# yacc -d -y -v parser.y
# echo 'Generated the parser C file as well the header file'
# g++ -w -c -o y.o y.tab.c
# echo 'Generated the parser object file'
# flex lex.l
# echo 'Generated the scanner C file'
# g++ -w -c -o l.o lex.yy.c
# echo 'Generated the scanner object file'
# g++ -o a.out y.o l.o -lfl
# echo 'All ready, running'
# ./a.out input.txt