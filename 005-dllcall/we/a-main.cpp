#include <stdio.h>
#include <windows.h>

int wmain(int argc, wchar_t **argv)
{
	for (int i=0; i<argc; i++)
	{
		printf("%d %ls\n", i, argv[i]);
	}
	HMODULE hmod = LoadLibraryA("a-dll.dll");
	printf("hmod(1)=0x%p\n", hmod);
	typedef int (*proc_wmain)(int argc, wchar_t **argv);
	proc_wmain fn_main = (proc_wmain)GetProcAddress(hmod, "wmain");
	printf("fn_main(1)=0x%p\n", fn_main);
	if (fn_main)
		fn_main(argc, argv);
	return 0;
}