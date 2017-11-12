import os;
import lib1;

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
	import core.stdc.stdio;
	import core.thread;
	import std.stdio : writeln;

	os_value[] argv;
	argv ~= os_new_integer(11);
	argv ~= os_new_integer(22);
	os_value answer = my_add2(argv.length, &argv[0]);
	os_dump_object_heap();
	os_integer_t answer2 = os_get_integer(answer);
	writeln(answer2);
	long arg0 = os_get_integer(argv[0]);
	writeln(`arg0=`, arg0);
	long arg1 = os_get_integer(argv[1]);
	writeln(`arg1=`, arg1);
	string s = "abc漢字";
	os_value mystr = os_new_string(cast(char*) s.ptr, s.length);
	os_dump_object_heap();
	os_link(mystr);
	os_cleanup();
	os_dump_object_heap();
	//char *ptr = os_get_string(mystr);
	//writeln(toString(ptr));

	INTERNET_PORT defport = 443; //実際は引数にしている

	wstring protocol = ("https"); //実際はurlから分割関数を書いてる
	wstring address = ("www.none.com");
	wstring content = ("index.html");

	exit(0);

	writeln(args);

	int i, j;
	int times = 1000;
	writeln("hello!");
	//setbuf(stdout, null);
	fprintf(stdout, "stdout\n");
	printf("0%%       50%%       100%%\n");
	printf("+---------+---------+\n");
	for (i = 0; i < times; i++)
	{
		/* 適当な処理 */
		Thread.sleep(dur!("msecs")(5));
		if (i % (times / 20) == times / 20 - 1)
		{
			/* プログレスバーの表示 */
			for (j = 0; j < (i + 1) / (times / 20) + 1; j++)
				printf("#");
			/* キャリッジリターンを利用して先頭にカーソルを移動 */
			printf("\r");
		}
	}
	fprintf(stdout, "\n");
}
