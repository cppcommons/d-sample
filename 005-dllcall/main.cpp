#include <windows.h>
#include <stdio.h>

// https://github.com/aktokaji/win32loader aaa
extern "C" int add2(int a, int b);
extern "C" int test1();
extern "C" int test2();

#include <iostream>
#include <string>
#include <vector>

int main()
{
	std::string s = "abc";
	std::vector<int> v;
	v.reserve(1024);

	CRITICAL_SECTION f_csect;
	InitializeCriticalSection(&f_csect);
	EnterCriticalSection(&f_csect);
	LeaveCriticalSection(&f_csect);
	DeleteCriticalSection(&f_csect);

	std::cout << s << std::endl;
	int rc2 = test2();
	printf("rc2=%d\n", rc2);
	rc2 = test2();
	printf("rc2=%d\n", rc2);
	#if 0x0
	int rc = test1();
	printf("rc=%d\n", rc);
	#endif
	printf("add2(): %d\n", add2(111, 222));
	return 0;
}
