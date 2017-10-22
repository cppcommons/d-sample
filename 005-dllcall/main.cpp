//#include <stdio.h>
#include "MemoryModule.h"

#include "dll_data.h"

int main() 
{
	//printf("start!\n");

	char *dll_data = (char *)malloc(dll_data_unit * dll_data_count);
	char *dll_ptr = dll_data;
	for (int i=0; i<dll_data_count; i++)
	{
		const char *unit = dll_data_array[i];
		memcpy(dll_ptr, unit, dll_data_unit);
		dll_ptr += dll_data_unit;
	}

#if 0x0
	FILE * fp = fopen("release/dlltest.dll", "rb");
	fseek(fp, 0, SEEK_END); 
	size_t size = ftell(fp);
	fseek(fp, 0, SEEK_SET);
	char * fcontent = (char *)malloc(size);
	fread(fcontent, 1, size, fp);	
#endif	
	
	//HMEMORYMODULE hModule = MemoryLoadLibrary(fcontent);
	HMEMORYMODULE hModule = MemoryLoadLibrary(dll_data);
	//printf("0x%08x\n", hModule);

	memset(dll_data, 0, dll_data_unit * dll_data_count);
	free(dll_data);

	typedef int (*proc_add2)(int a, int b);
	proc_add2 add2 = (proc_add2)MemoryGetProcAddress(hModule, "add2");
	//printf("0x%08x\n", add2);
	int ans = add2(11, 22);
	//printf("ans=%d\n", ans);
	
	typedef void (*proc_test)();
	proc_test test1 = (proc_test)MemoryGetProcAddress(hModule, "test1");
	//printf("0x%08x\n", test1);
	test1();
	
	
	return 0;
}
