#include <stdio.h>
#include "MemoryModule.h"

//#include <string>
//#include <fstream>
//#include <streambuf>

int main() 
{
	printf("start!\n");

	FILE * fp = fopen("release/dlltest.dll", "rb");
	fseek(fp, 0, SEEK_END); 
	size_t size = ftell(fp);
	fseek(fp, 0, SEEK_SET);
	char * fcontent = (char *)malloc(size);
	fread(fcontent, 1, size, fp);	
	
	
	HMEMORYMODULE hModule = MemoryLoadLibrary(fcontent);
	printf("0x%08x\n", hModule);

	typedef int (*proc_add2)(int a, int b);
	proc_add2 add2 = (proc_add2)MemoryGetProcAddress(hModule, "add2");
	printf("0x%08x\n", add2);
	int ans = add2(11, 22);
	printf("ans=%d\n", ans);
	
	typedef void (*proc_test)();
	proc_test test1 = (proc_test)MemoryGetProcAddress(hModule, "test1");
	printf("0x%08x\n", test1);
	test1();
	
	
	return 0;
}
