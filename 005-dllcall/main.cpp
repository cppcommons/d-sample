#include <stdio.h>

extern "C" void *get_proc(const char *proc_name);

extern "C" int add2(int a, int b);

extern "C" int test1();

#if 0x0
extern int add2(int a, int b)
{
	typedef int (*proc_add2)(int a, int b);
	static proc_add2 _add2 = (proc_add2)get_proc("add2");
	return _add2(a, b);
}

extern int test1()
{
	typedef int (*proc_test1)();
	static proc_test1 _test1 = (proc_test1)get_proc("test1");
	return _test1();
}
#endif

int main()
{
	//typedef int (*proc_test)();
	//proc_test test1 = (proc_test)get_proc("test1");
	int rc = test1();
	printf("rc=%d\n", rc);

	printf("add2(): %d\n", add2(111, 222));
	return 0;
}
