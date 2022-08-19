int a[2],b,c;
int main()
{
    a[0] = 1;
    b = a[0]++;
    c = a[0];
    println(b);
    println(c);
    return 0;
}
