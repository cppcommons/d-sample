#include <windows.h>
#include <stdio.h>

#include "common.h"

// https://github.com/aktokaji/win32loader aaa

#ifndef TEST_BY_QT
extern "C" int add2(int a, int b);
extern "C" int test1();
extern "C" int test2();
#endif

#include <iostream>
#include <string>
#include <vector>

class CoMutex
{
    CRITICAL_SECTION csect;
public:
    explicit CoMutex()
    {
        InitializeCriticalSection(&csect);
    }
    virtual ~CoMutex()
    {
        DeleteCriticalSection(&csect);
    }
    void lock()
    {
        EnterCriticalSection(&csect);
    }
    void unlock()
    {
        LeaveCriticalSection(&csect);
    }
};

void sub()
{

}

CoMutex mutex;

int main()
{
	std::string s = "abc";
    std::cout << s << std::endl;
    trace(funcsig << " s=" << s);
    //#define trace(x) do { std::stringstream s; s << x << '\n'; OutputDebugStringA(s.str().c_str()); } while (0)
    //do { std::stringstream s; s << "s=" << s.c_str() << '\n'; OutputDebugStringA(s.str().c_str()); } while (0);

    std::vector<int> v;
	v.reserve(1024);

    mutex.lock();
    mutex.unlock();
#ifndef TEST_BY_QT
	int rc2 = test2();
	printf("rc2=%d\n", rc2);
	rc2 = test2();
	printf("rc2=%d\n", rc2);
	#if 0x0
	int rc = test1();
	printf("rc=%d\n", rc);
	#endif
	printf("add2(): %d\n", add2(111, 222));
#endif
	return 0;
}
