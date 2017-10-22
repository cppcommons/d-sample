#include <stdio.h>

////extern "C" void *get_proc(const char *proc_name);
extern "C" int add2(int a, int b);
extern "C" int test1();


int main()
{
	int rc = test1();
	printf("rc=%d\n", rc);
	printf("add2(): %d\n", add2(111, 222));
	return 0;
}
