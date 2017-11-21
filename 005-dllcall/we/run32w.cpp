#include <windows.h>
#include <stdio.h>
#include <io.h>
#include <string>

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

bool isRedirect(FILE *fp)
{
	return !_isatty(_fileno(fp));
}

bool isRedirect(DWORD nStdHandle)
{
	HANDLE h = GetStdHandle(nStdHandle);
	DWORD type = GetFileType(h);
	switch (type)
	{
	case FILE_TYPE_CHAR:
		// it's from a character device, almost certainly the console
		return false;
	case FILE_TYPE_DISK:
		// redirected from a file
		return true;
	case FILE_TYPE_PIPE:
		// piped from another program, a la "echo hello | myprog"
		return true;
	case FILE_TYPE_UNKNOWN:
		// this shouldn't be happening...
		return true;
	}
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	FILE *log = fopen("___log.txt", "w");
	bool use_console = true;
	int argc;
	LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
	for (int i = 0; i < argc; i++)
	{
		printf("szArglist[%d]=%ls\n", i, argv[i]);
	}
	if (argc >= 2)
	{
		std::wstring arg1 = argv[1];
		if (arg1 == L"-nc")
		{
			printf("[nc]\n");
			use_console = false;
		}
	}
	if (use_console && AttachParentConsole())
	{
		#if 0x0
		freopen("CONIN$", "r", stdin);
		freopen("CONOUT$", "w", stdout);
		freopen("CONOUT$", "w", stderr);
		#endif
	}
	printf("lpCmdLine=%s\n", lpCmdLine);
	char a[1024];
	memset(a, 0, 1024);
	fprintf(stderr, "input: ");
	fflush(stderr);
	gets(a);
	printf("a=%s\n", a);
	fprintf(stdout, "A2=%s\n", a);
	fprintf(stderr, "A3=%s\n", a);
	//MessageBox(NULL, "Hello Windows!", "MyFirst", MB_OK);
	//HMODULE hmod = LoadLibraryA("rdll-dm32.dll");
	//HMODULE hmod = LoadLibraryA("rdll.dll");
	HMODULE hmod = LoadLibraryA("np.dll");
	if (!hmod)
		return 1;
	fprintf(log, "hmod=0x%p\n", hmod);
	typedef int (*proc_RunMain)(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow);
	proc_RunMain addr_RunMain = (proc_RunMain)GetProcAddress(hmod, "RunMain");
	if (!addr_RunMain)
		return 2;
	fprintf(log, "addr_RunMain=0x%p\n", addr_RunMain);
	addr_RunMain(hInstance, hPrevInstance, lpCmdLine, nCmdShow);
	fclose(log);
	exit(0);
}