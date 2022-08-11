// int a,b,c[100];
int g[3];

int sum(int a, int b) {
    int s;
    s = a + b;
    return s;
}

int main() {
    // int a, b[10], c;
    int i, j, k;

    i = 3;
    j = 8;
    k = 6;

    if (i == 3)
    {
        println(j);
    }

    if (j < 8)
    {
        println(i);
    }
    else
    {
        println(k);
    }

    if (k != 6)
    {
        println(k);
    }
    else if (j > 8)
    {
        println(j);
    }
    else if (i < 2)
    {
        println(i);
    }
    else
    {
        k = 0;
        println(k);
    }

    // d[1] = 20;
    // g[2] = 30;
    // // a = 1;
    // // a = c;
    // // println(a);
    // a = 10;
    // b = 3;
    // c = a + 2*b;
    // println(c);

    // b = a <= c;
    // println(b);

    // a = 0;
    // b = 10;
    // c = a || b;
    // println(c);
    // c = b && a;
    // println(c);

    // {
    //     int a;
    //     a = 3;
    //     println(a);
    // }

    // c = sum(a, b);
    // println(c);
    // c = -c;
    // println(c);
    // c = !c;
    // println(c);

    // c++;
    // println(c);
    // ++c;
    // println(c);

    // c = ++d[1];
    // println(c);
    // c = d[1];
    // println(c);

    // c = ++g[2];
    // println(c);
    // c = g[2];
    // println(c);

    return 0;
}