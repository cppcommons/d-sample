// https://support.microsoft.com/en-us/help/164787/info-windows-rundll-and-rundll32-interface
#include <windows.h>
#include <stdio.h>

//extern "C" __declspec(dllexport)
//void CALLBACK EntryPointW(HWND hwnd, HINSTANCE hinst, LPWSTR lpszCmdLine, int nCmdShow)
extern "C" __declspec(dllexport) void CALLBACK sayHello(HWND, HINSTANCE, wchar_t const *, int)
{
	::MessageBoxA(NULL, "aaa", "bbb", MB_OK);
	AllocConsole();
#if 0x0
	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);
#endif
	printf("sayHello(1)\n");

	DWORD const infoBoxOptions = MB_ICONINFORMATION | MB_SETFOREGROUND;
	MessageBoxW(0, L"Before call...", L"DLL message:", infoBoxOptions);
	//myCode::sayHello();
	MessageBoxW(0, L"After call...", L"DLL message:", infoBoxOptions);
	return;
}

extern "C" __declspec(dllexport) int RunMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);
	printf("RunMain(1)\n");
	return 0;
}