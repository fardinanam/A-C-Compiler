int f(int a)
{
    return 2 * a;
    a = 9;
}

int g(int a, int b)
{
    int x;
    x = f(a) + a + b;
    return x;
}

int main()
{
    int a[10], b;
    a[5] = 1;
    b = 2;
    a[1] = g(a[5], b);
    b = a[1];
    println(b);
    return 0;
}
