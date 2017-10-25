class MyClass
{
    virtual int add2(int a, int b) { return a + b; }
    virtual int mul2(int a, int b) { return a * b; }
};

MyClass * MyClassNew() { return new MyClass; }

#ifndef _TLSDECL_H_
#define _TLSDECL_H_

#include <windows.h>

#ifdef __GNUC__
#define TLS_VARIABLE_DECL __thread
#else /* Visual C++ & Digital Mars C/C++ */
#define TLS_VARIABLE_DECL __declspec(thread)
#endif

#ifdef __GNUC__
#define TLS_CALLBACK_DECL(SECTION, VAR, FUN) PIMAGE_TLS_CALLBACK VAR __attribute__((section(SECTION))) = FUN;
#else
#ifdef _WIN64
#define TLS_CALLBACK_DECL(SECTION, VAR, FUN)                           \
    __pragma(const_seg(SECTION)) extern const PIMAGE_TLS_CALLBACK VAR; \
    const PIMAGE_TLS_CALLBACK VAR = FUN;                               \
    __pragma(const_seg())
#else
#define TLS_CALLBACK_DECL(SECTION, VAR, FUN)                   \
    __pragma(data_seg(SECTION)) PIMAGE_TLS_CALLBACK VAR = FUN; \
    __pragma(data_seg())
#endif
#endif

#ifdef __GNUC__
#define ALIGNED_ARRAY_DECL(TYPE, VAR, SIZE, ALIGN) TYPE VAR[SIZE] __attribute__((__aligned__(ALIGN)))
#else /* Visual C++ only. Not for Digital Mars C/C++. */
#define ALIGNED_ARRAY_DECL(TYPE, VAR, SIZE, ALIGN) __declspec(align(ALIGN)) TYPE VAR[SIZE]
#endif

//#ifdef __GNUC__
//#define UNUSED_PARAMETER(P) {(P) = (P);}
//#else
//#define UNUSED_PARAMETER(P) (P)
//#endif

#define UNUSED_PARAMETER(P) (void)P;

#endif /* _TLSDECL_H_ */

//ALIGNED_ARRAY_DECL(int, VAR, 50, 16);

TLS_VARIABLE_DECL int my_thread_local_var = 1234;

extern "C" int dmc_tls_test()
{
    my_thread_local_var++;
    return my_thread_local_var;
}