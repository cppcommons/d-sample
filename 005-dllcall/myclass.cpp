class MyClass
{
    virtual int add2(int a, int b) { return a + b; }
    virtual int mul2(int a, int b) { return a * b; }
};

//extern "C"
MyClass * MyClassNew() { return new MyClass; }