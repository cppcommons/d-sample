#include <stdio.h>

////extern "C" void *get_proc(const char *proc_name);
extern "C" int add2(int a, int b);
extern "C" int test1();
extern "C" int test2();


int main()
{
	int rc2 = test2();
	printf("rc2=%d\n", rc2);
	int rc = test1();
	printf("rc=%d\n", rc);
	printf("add2(): %d\n", add2(111, 222));
	return 0;
}
