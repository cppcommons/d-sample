import os;
import lib1;

import core.sys.windows.windows;
import core.sys.windows.wininet;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

// http://forum.dlang.org/post/c6ojg9$c8p$1@digitaldaemon.com
char[] toString(char* s)
{
	import core.stdc.string : strlen;

	return s ? s[0 .. strlen(s)] : cast(char[]) null;
}

// http://forum.dlang.org/post/c6ojg9$c8p$1@digitaldaemon.com
wchar[] toString(wchar* s)
{
	import core.stdc.wchar_ : wcslen;

	return s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
}

void main(string[] args)
{
	import core.thread;
	import std.stdio;
	import std.string;

	string app = "Sample Application/1.0";
	string url = "https://raw.githubusercontent.com/cyginst/ms2inst-v1/master/ms2inst.bat";

	char* appZ = cast(char*) toStringz(app);
	char* urlZ = cast(char*) toStringz(url);

	HINTERNET hInet;
	HINTERNET hFile;
	char[1024] lpszBuf;
	//char[16] lpszBuf;
	DWORD dwSize;

	/* ハンドル作成 */
	hInet = InternetOpenA(appZ, INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);

	/* URLオープン */
	hFile = InternetOpenUrlA(hInet, urlZ, NULL, 0, INTERNET_FLAG_RELOAD, 0);

	char[] result;
	while (InternetReadFile(hFile, cast(char*) lpszBuf.ptr, lpszBuf.length, &dwSize) && dwSize > 0)
	{
		result ~= lpszBuf[0 .. dwSize];
		//result ~= "||";
	}
	writeln(result);

	/* 終了処理 */
	InternetCloseHandle(hFile);
	InternetCloseHandle(hInet);

	//exit(0);

	os_value[] argv;
	argv ~= os_new_integer(11);
	argv ~= os_new_integer(22);
	os_value answer = my_add2(argv.length, &argv[0]);
	os_dump_heap();
	long answer2 = os_get_integer(answer);
	writeln(answer2);
	long arg0 = os_get_integer(argv[0]);
	writeln(`arg0=`, arg0);
	long arg1 = os_get_integer(argv[1]);
	writeln(`arg1=`, arg1);
	string s = "abc漢字";
	os_value mystr = os_new_string(cast(char*) s.ptr, s.length);
	os_dump_heap();
	os_mark(mystr);
	os_sweep();
	os_dump_heap();
	char* ptr = os_get_string(mystr);
	writefln("[%s]", toString(ptr));
	os_clear();

	exit(0);
}
