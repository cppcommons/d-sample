#include <windows.h>
#include <stdio.h>
//#include <io.h>
#include <string>
#include <vector>

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

struct ParseArgs_Info
{
	bool use_console;
};

void ParseArgs(ParseArgs_Info &info, std::vector<wchar_t *> &args)
{
	info.use_console = false;
	args.clear();
	int argc;
	LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
	for (int i = 0; i < argc; i++)
	{
		wchar_t *arg = argv[i];
		if (i == 0)
		{
			// skip "run.exe"
			continue;
		}
		if (i == 1)
		{
			std::wstring arg_str = arg;
			if (arg_str == L"-c" || arg_str == L"--console")
			{
				info.use_console = true;
				continue;
			}
		}
		args.push_back(argv[i]);
	}
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	FILE *log = fopen("___log.txt", "w");
	ParseArgs_Info info;
	std::vector<wchar_t *> args;
	ParseArgs(info, args);
	if (info.use_console && AttachParentConsole())
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