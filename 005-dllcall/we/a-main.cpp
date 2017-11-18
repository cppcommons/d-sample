#include <stdio.h>
#include <windows.h>

int main()
{
	HMODULE hmod = LoadLibraryA("a-dll.dll");
	printf("hmod(1)=0x%p\n", hmod);
	typedef void (*proc_main)();
	proc_main fn_main = (proc_main)GetProcAddress(hmod, "cmain");
	printf("fn_main(1)=0x%p\n", fn_main);
	if (fn_main)
		fn_main();
	return 0;
}