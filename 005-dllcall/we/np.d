import core.sys.windows.windows;
import core.sys.windows.winbase;

import core.sys.windows.dll : SimpleDllMain; // file:///C:\D\dmd2\src\druntime\import\core\sys\windows\dll.d
mixin SimpleDllMain;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

static void pause(string message = null)
{
	//import std.process : executeShell;
	import std.stdio; // : stdin, stdout, write, writeln;

	if (message is null) message = `PAUSE`;

	writef(`[%s] HIT ENTER KEY: `, message);
	stdout.flush();
	stdin.readln();
}

private static string[] build_args(int argc, wchar** argv)
{
	string[] result;
	for (int i = 0; i < argc; i++)
	{
		result ~= to_string(argv[i]);
	}
	return result;
}

extern (C) export void runServer(int argc, wchar** argv, DWORD with_console)
{
	import std.stdio; // : writeln;

	writeln(build_args(argc, argv));

	import std.stdio; // : writeln;
	//writeln(args);
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
	writeln("EXIT...");
	return;
}

extern (C) export void runClient(int argc, wchar** argv, DWORD with_console) //extern (Windows) export void {
{

	import core.stdc.stdio; // : freopen, stderr, stdin, stdout;
	import core.stdc.string : strlen;
	import std.stdio : writeln;
	import core.thread;

	writeln(build_args(argc, argv));

	pause(`Waiting Server to Start`);

	//Thread.sleep(dur!("seconds")(2));
	//writeln("[CLIENT READY]");
	//Thread.sleep(dur!("seconds")(2));
	HANDLE hPipe = CreateFile("\\\\.\\pipe\\mypipe", GENERIC_READ | GENERIC_WRITE,
			0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	writeln("0");
	//Thread.sleep(dur!("seconds")(2));
	if (hPipe == INVALID_HANDLE_VALUE)
	{
		writeln("1");
		//Thread.sleep(dur!("seconds")(2));
		return;
	}
	writeln("2");
	//Thread.sleep(dur!("seconds")(2));
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
	writeln("EXIT...");
	return;
}

//extern "C" __declspec(dllexport) int RunMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
//	typedef int (*proc_RunMain)(__int32 argc, wchar_t **argv, DWORD with_console);
extern (C) export int RunMain(int argc, wchar** argv, DWORD with_console)
{
	import std.stdio : writeln;

	writeln(`argc=`, argc);
	for (int i = 0; i < argc; i++)
	{
		writeln(to_string(argv[i]));
	}
	writeln(`with_console=`, with_console);
	writeln(`with_console & 2=`, with_console & 2);
	writeln("RunMain(DLang)");
	return 0;
}

string to_string(char* s)
{
	import core.stdc.string : strlen;
	import std.conv : to;

	char[] result = s ? s[0 .. strlen(s)] : cast(char[]) null;
	return to!string(s);
}

string to_string(wchar* s)
{
	import core.stdc.wchar_ : wcslen;
	import std.conv : to;

	wchar[] result = s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
	return to!string(to!wstring(result));
}

wstring to_wstring(wchar* s)
{
	import core.stdc.wchar_ : wcslen;
	import std.conv : to;

	wchar[] result = s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
	return to!wstring(result);
}

string to_mb_string(in char[] s, uint codePage = 0)
{
	import std.windows.charset : toMBSz;
	import std.conv : to;

	const(char)* mbsz = toMBSz(s, codePage);
	return to_string(cast(char*) mbsz);
}

string to_mb_string(in wchar[] s, uint codePage = 0)
{
	import std.windows.charset : toMBSz;
	import std.conv : to;

	string utf8 = to!string(s);
	const(char)* mbsz = toMBSz(utf8, codePage);
	return to_string(cast(char*) mbsz);
}
