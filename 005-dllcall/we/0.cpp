extern "C" {
#define EXPORT_FUNCTION extern "C" __declspec(dllexport)

#ifndef __HTOD__
#include <windows.h>
#include <stdio.h>
//#include <map>
//#include <mutex>
//#include <string>
//#include <vector>
extern "C" __declspec(dllexport) void CALLBACK run(HWND hwnd, HINSTANCE hinst, const char *lpszCmdLine, int nCmdShow)
{
	AllocConsole();
	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);
	printf("lpszCmdLine=%s\n", lpszCmdLine);
	LPWSTR *szArglist;
	int nArgs;
	LPWSTR lp = GetCommandLineW();
	printf("lp=%ls\n", lp);
	szArglist = CommandLineToArgvW(GetCommandLineW(), &nArgs);
	for (int i = 0; i < nArgs; i++)
	{
		printf("szArglist[%d]=%ls\n", i, szArglist[i]);
	}
	MessageBoxW(0, L"run()", L"Message", MB_OK);
	return;
}
extern "C" __declspec(dllexport) int main(int argc, const char **argv)
{
	return 0;
}
#endif //if !defined(__HTOD__)
} // extern "C"
