import core.sys.windows.dll : SimpleDllMain; // file:///C:\D\dmd2\src\druntime\import\core\sys\windows\dll.d

mixin SimpleDllMain;

string to_string(char* s)
{
	import core.stdc.string : strlen;
	import std.conv : to;

	char[] result = s ? s[0 .. strlen(s)] : cast(char[]) null;
	return to!string(s);
}

wstring to_wstring(wchar* s)
{
	import core.stdc.wchar_ : wcslen;
	import std.conv : to;

	wchar[] result = s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
	return to!wstring(result);
}

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

import core.sys.windows.windows;
import core.sys.windows.winbase;

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

static void init_console()
{
	import core.stdc.stdio : freopen, stderr, stdin, stdout;

	AllocConsole();
	//if (!AttachConsole(ATTACH_PARENT_PROCESS))
	//	AllocConsole();
	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);
}

static void pause()
{
	import std.process : executeShell;
	import std.stdio : stdout, write, writeln;

	write(`Hit Any Key: `);
	stdout.flush();
	executeShell("cmd.exe /c pause");
	writeln();
}

extern (Windows) export void run(HWND hwnd, HINSTANCE hinst, char* lpszCmdLine, int nCmdShow)
{
	import std.stdio : writeln;

	//init_console();
	string[] args;
	init_rundll_pg(args);
	writeln(args.length);
	writeln(args);
	foreach (arg; args)
	{
		writeln(arg);
	}
	//writeln("lpszCmdLine=", to_wstring(lpszCmdLine));
	writeln("xxxlpszCmdLine=", to_string(lpszCmdLine));
	//MessageBoxA(null, cast(char*) "a", cast(char*) "b", MB_OK);
	pause();
	return;
}
