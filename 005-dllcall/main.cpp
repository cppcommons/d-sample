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

#include <iostream>
#include <vector>
#include <boost/range/algorithm.hpp>

using namespace std;

int main()
{
    vector<int> v;
    v.push_back ( 1 );
    v.push_back ( 2 );
    v.push_back ( 3 );
    v.push_back ( 4 );
    vector<int>::iterator it = boost::find(v, 3);
    trace(*it);

    std::string s = "abc";
    std::cout << s << std::endl;
    trace(funcsig << " s=" << s);

    std::vector<int> v2;
	v2.reserve(1024);

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
