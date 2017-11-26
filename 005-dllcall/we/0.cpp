extern "C" {
#define EXPORT_FUNCTION extern "C" __declspec(dllexport)

#ifndef __HTOD__
#include <windows.h>
#include <stdio.h>
//#include <map>
//#include <mutex>
//#include <string>
//#include <vector>

extern "C" __declspec(dllexport) DWORD RunMain(size_t argc, wchar_t **argv, DWORD with_console)
{
	for (int i=0; i<argc; i++)
	{
		printf("argv[%d]=%ls\n", i, argv[i]);
	}
	printf("input: ");
	fflush(stdout);
	int c = getchar();
	printf("c=%c(%d)\n", c, c);
	return 0;
}
#endif //if !defined(__HTOD__)
} // extern "C"
