// int a,b,c[100];

int sum(int a, int b) {
    int s;
    s = a + b;
    return s;
}

int main() {
    // int a, b[10], c;
    int a, b, c;
   
    // a = 1;
    // a = c;
    // println(a);
    a = 10;
    b = 3;
    c = a + 2*b;
    println(c);

    b = a <= c;
    println(b);

    a = 0;
    b = 10;
    c = a || b;
    println(c);
    c = b && a;
    println(c);

    // {
    //     int a;
    //     a = 3;
    //     println(a);
    // }

    c = sum(a, b);
    println(c);

    return 0;
}