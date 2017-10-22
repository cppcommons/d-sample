#ifndef DLLTEST_H
#define DLLTEST_H

////#include "dlltest_global.h"
#include <QtCore/qglobal.h>

#if defined(DLLTEST_LIBRARY)
#  define DLLTESTSHARED_EXPORT Q_DECL_EXPORT
#else
#  define DLLTESTSHARED_EXPORT Q_DECL_IMPORT
#endif

class DLLTESTSHARED_EXPORT Dlltest
{

public:
    Dlltest();
};

extern "C" {
    DLLTESTSHARED_EXPORT int add2(int a, int b);
    DLLTESTSHARED_EXPORT void test1();
}

#endif // DLLTEST_H
