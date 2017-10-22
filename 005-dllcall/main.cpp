#include <stdio.h>
#include "MemoryModule.h"

#include "dll_data.h"

static FARPROC get_proc(const char *proc_name)
{
	static HMEMORYMODULE hModule = NULL;
	if (!hModule)
	{
		char *dll_data = (char *)HeapAlloc(GetProcessHeap(), 0, dll_data_unit * dll_data_count);
		char *dll_ptr = dll_data;
		for (int i=0; i<dll_data_count; i++)
		{
			const char *unit = dll_data_array[i];
			RtlMoveMemory(dll_ptr, unit, dll_data_unit);
			dll_ptr += dll_data_unit;
		}
		hModule = MemoryLoadLibrary(dll_data);
		HeapFree(GetProcessHeap(), 0, dll_data);
	}
	return MemoryGetProcAddress(hModule, proc_name);
}

extern int my_add2(int a, int b)
{
	
	typedef int (*proc_add2)(int a, int b);
	proc_add2 add2 = (proc_add2)get_proc("add2");
	return add2(a, b);
}

int main() 
{
#if 0x0
	char *dll_data = (char *)HeapAlloc(GetProcessHeap(), 0, dll_data_unit * dll_data_count);
	char *dll_ptr = dll_data;
	for (int i=0; i<dll_data_count; i++)
	{
		const char *unit = dll_data_array[i];
		RtlMoveMemory(dll_ptr, unit, dll_data_unit);
		dll_ptr += dll_data_unit;
	}

	HMEMORYMODULE hModule = MemoryLoadLibrary(dll_data);

	//ZeroMemory(dll_data, dll_data_unit * dll_data_count);
	HeapFree(GetProcessHeap(), 0, dll_data);
#endif	
	//typedef int (*proc_add2)(int a, int b);
	//proc_add2 add2 = (proc_add2)MemoryGetProcAddress(hModule, "add2");
	//printf("0x%08x\n", add2);
	//int ans = add2(11, 22);
	//printf("ans=%d\n", ans);
	
	typedef int (*proc_test)();
	//proc_test test1 = (proc_test)MemoryGetProcAddress(hModule, "test1");
	proc_test test1 = (proc_test)get_proc("test1");
	//printf("0x%08x\n", test1);
	int rc = test1();
	printf("rc=%d\n", rc);

	printf("my_add2(): %d\n", my_add2(111, 222));
	return 0;
}
