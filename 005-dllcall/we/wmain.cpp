#include <windows.h>
#include <stdio.h>

#ifndef ATTACH_PARENT_PROCESS
#define ATTACH_PARENT_PROCESS (DWORD) - 1
#endif

bool AttachParentConsole()
{
	HMODULE hmod = LoadLibraryA("kernel32.dll");
	if (!hmod)
		return false;
	typedef BOOL(WINAPI * proc_AttachConsole)(DWORD dwProcessId);
	proc_AttachConsole addr_AttachConsole = (proc_AttachConsole)GetProcAddress(hmod, "AttachConsole");
	if (!addr_AttachConsole)
		return false;
	return (bool)addr_AttachConsole(ATTACH_PARENT_PROCESS);
}


int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	if (!AttachParentConsole())
		AllocConsole();
	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONERR$", "w", stderr);
	printf("lpCmdLine=%s\n", lpCmdLine);
	char a[1024];
	memset(a, 0, 1024);
	gets(a);
	printf("a=%s\n", a);
	fprintf(stderr, "A=%s\n", a);
	//MessageBox(NULL, "Hello Windows!", "MyFirst", MB_OK);
	//HMODULE hmod = LoadLibraryA("rdll.dll");
	HMODULE hmod = LoadLibraryA("np.dll");
	if (!hmod)
		return 1;
	printf("hmod=0x%p\n", hmod);
	typedef int (*proc_RunMain)(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow);
	proc_RunMain addr_RunMain = (proc_RunMain)GetProcAddress(hmod, "RunMain");
	if (!addr_RunMain)
		return 2;
	printf("addr_RunMain=0x%p\n", addr_RunMain);
	return addr_RunMain(hInstance, hPrevInstance, lpCmdLine, nCmdShow);
}