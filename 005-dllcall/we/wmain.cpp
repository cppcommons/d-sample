#include <windows.h>
#include <stdio.h>

#ifndef ATTACH_PARENT_PROCESS
#define ATTACH_PARENT_PROCESS (DWORD) - 1
#endif

typedef BOOL(WINAPI *proc_AttachConsole)(DWORD dwProcessId);

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	HMODULE hmod = LoadLibraryA("kernel32.dll");
	proc_AttachConsole fn_AttachConsole = (proc_AttachConsole)GetProcAddress(hmod, "AttachConsole");
	if (!(fn_AttachConsole && fn_AttachConsole(ATTACH_PARENT_PROCESS)))
		AllocConsole();
	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);
	printf("lpCmdLine=%s\n", lpCmdLine);
	char a[1024];
	memset(a, 0, 1024);
	gets(a);
	printf("a=%s", a);
	//MessageBox(NULL, "Hello Windows!", "MyFirst", MB_OK);
	return 0;
}