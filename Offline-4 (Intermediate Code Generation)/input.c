int a,b,c[100];

void foo(int a, int b) {
    int c;
    c = 10;
    println(a);
    println(b);
    println(c);
}

int main() {
    int a, b[10], c;

    a = 1;
    println(a);

    c = 2;
    println(c);

    foo(11, 12);

    return 0;
}