import core.sys.windows.windows;
import core.sys.windows.winbase;

import core.sys.windows.dll : SimpleDllMain; // file:///C:\D\dmd2\src\druntime\import\core\sys\windows\dll.d
mixin SimpleDllMain;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

static void init_rundll_pg(ref string[] args)
{
	string to_string(wchar* s)
	{
		import core.stdc.wchar_ : wcslen;
		import std.conv : to;

		wchar[] result = s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
		return to!string(to!wstring(result));
	}

	import core.stdc.stdio; // : freopen, stderr, stdin, stdout;
	import core.sys.windows.windows;
	import core.sys.windows.winbase;

	AllocConsole();
	//if (!AttachConsole(ATTACH_PARENT_PROCESS))
	//	AllocConsole();
	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);
	args.length = 0;
	LPWSTR* szArglist;
	int nArgs;
	szArglist = CommandLineToArgvW(GetCommandLineW(), &nArgs);
	printf("nArgs=%d\n", nArgs);
	for (int i = 1; i < nArgs; i++)
	{
		args ~= to_string(szArglist[i]);
	}
}

static void pause()
{
	import std.process : executeShell;
	import std.stdio : stdin, stdout, write, writeln;

	write(`[PAUSE] HIT ENTER KEY: `);
	stdout.flush();
	stdin.readln();
}

extern (Windows) export void run(HWND hwnd, HINSTANCE hinst, char*  /+lpszCmdLine+/ , int nCmdShow)
{
	string to_string(char* s)
	{
		import core.stdc.string : strlen;
		import std.conv : to;

		char[] result = s ? s[0 .. strlen(s)] : cast(char[]) null;
		return to!string(result);
	}

	import std.stdio; // : writeln;

	string[] args;
	init_rundll_pg(args);
	writeln(args);
	HANDLE hPipe = CreateNamedPipe("\\\\.\\pipe\\mypipe", //lpName
			PIPE_ACCESS_DUPLEX, // dwOpenMode
			PIPE_TYPE_BYTE | PIPE_WAIT, // dwPipeMode
			3, // nMaxInstances
			0, // nOutBufferSize
			0, // nInBufferSize
			100, // nDefaultTimeOut
			NULL); // lpSecurityAttributes
	if (hPipe == INVALID_HANDLE_VALUE)
	{
		return;
	}
	if (!ConnectNamedPipe(hPipe, NULL))
	{
		CloseHandle(hPipe);
		return;
	}
	while (1)
	{
		char szBuff[256];
		DWORD dwBytesRead;
		if (!ReadFile(hPipe, szBuff.ptr, szBuff.length, &dwBytesRead, null))
		{
			break;
		}
		szBuff[dwBytesRead] = '\0';
		writefln("PipeServer: %s", to_string(szBuff.ptr));
	}
	FlushFileBuffers(hPipe);
	DisconnectNamedPipe(hPipe);
	CloseHandle(hPipe);
	pause();
	return;
}

extern (Windows) export void runClient(HWND hwnd, HINSTANCE hinst, char*  /+lpszCmdLine+/ ,
		int nCmdShow)
{
	import core.stdc.stdio; // : freopen, stderr, stdin, stdout;
	import core.stdc.string : strlen;
	import std.stdio : writeln;
	import core.thread;

	string[] args;
	init_rundll_pg(args);
	writeln(args);
	Thread.sleep(dur!("seconds")(5));
	writeln("[READY]");
	HANDLE hPipe = CreateFile("\\\\.\\pipe\\mypipe", GENERIC_READ | GENERIC_WRITE,
			0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hPipe == INVALID_HANDLE_VALUE)
	{
		return;
	}
	while (1)
	{
		char szBuff[32];
		DWORD dwBytesWritten;
		fgets(szBuff.ptr, szBuff.length, stdin);
		if (!WriteFile(hPipe, szBuff.ptr, strlen(szBuff.ptr), &dwBytesWritten, null))
		{
			break;
		}
	}
	CloseHandle(hPipe);
	pause();
	return;
}

//extern "C" __declspec(dllexport) int RunMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
extern (C) export void RunMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
		HWND hwnd, HINSTANCE hinst, char*  /+lpCmdLine+/ , int nCmdShow)
{
	import std.stdio : writeln;
	writeln("RunMain(DLang)");
}
