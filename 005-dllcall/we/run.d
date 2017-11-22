private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

alias extern (C) int function(int argc, wchar** argv, DWORD with_console) proc_RunMain;


import core.sys.windows.windows;
import core.sys.windows.winbase;
import std.conv;
import std.stdio;
import std.utf;

int main(string[] args)
{
	wstring dll_name = to!wstring(args[1]);
	writeln(dll_name);
	HMODULE hmod = LoadLibraryW(dll_name.ptr);
	if (!hmod)
	{
		//error("%ls is not valid DLL.", dll_name.c_str());
		return 1;
	}
	writeln(hmod);
	proc_RunMain addr_RunMain = cast(proc_RunMain)GetProcAddress(hmod, "RunMain".ptr);
	if (!addr_RunMain)
	{
		//error("Entry function %ls not found in %ls", entry_name.c_str(), dll_name.c_str());
		return 2;
	}
	writeln(addr_RunMain);
	//args = args[1..$];
	wstring[] wargs;
	const(wchar)*[] wargs2;
	for (int i=1; i<args.length; i++)
	{
		wstring warg = to!wstring(args[i]);
		wargs ~= warg;
		wargs2 ~= toUTF16z(warg);
	}
	
	int rc = addr_RunMain(wargs2.length, cast(wchar **)wargs2.ptr, 3);
	return rc;
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
