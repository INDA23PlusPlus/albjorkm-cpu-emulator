int getchar();
int printf(char *);

int readNumber() {
    int acc = 0;
    int c = getchar();
    while (c >= '0' && c <= '9') {
        acc = acc * 10;
        acc += c - '0';
        c = getchar();
    }
    return acc;
}

void main()
{
    int number = readNumber();
    printf("Calculating fib(%d)\n", number);
    int n1=0;
    int n2=1;
    int n3=1;
    int i;
    for(i = 0; i < number; i++) {
        n3 = n1 + n2;
        n1 = n2;
        n2 = n3;
    }
    printf("Fib is: %d\n", n3);
}
