#include "lib1.h"

//extern "C" os_function my_mul2;
//extern "C" os_handle my_mul2(long argc, os_handle argv[]);

#include <stdio.h>

extern os_object *my_add2(long argc, os_object *argv[])
{
	if (argc != 2)
	{
		return 0;
	}
	//os_handle a10 = my_mul2(heap, argc, argv);
	//argv[0] = a10;
	os_integer *i0 = (os_integer *)os_new_integer(123);
	printf("i0->eye_catcher=%s\n", i0->eye_catcher);
	long a = (long)os_get_integer(argv[0]);
	long b = (long)os_get_integer(argv[1]);
	a = d_mul2(a, 10);
	printf("my_add2(1)\n");
	printf("my_add2(2)\n");
	//argv[0] = os_new_integer(heap, a * 10);
	argv[1] = os_new_integer(b * 10);
	return os_new_integer(a + b);
}

#include <windows.h>
#include <wininet.h>
#include <string>

int mainX()
{

	HINTERNET hInet;
	HINTERNET hFile;
	char *lpszBuf;
	DWORD dwSize;

	lpszBuf = (char *)GlobalAlloc(GPTR, 1024);

	/* ハンドル作成 */
	hInet = InternetOpenA("TEST", INTERNET_OPEN_TYPE_DIRECT,
						  NULL, NULL, 0);

	/* URLオープン */
	hFile = InternetOpenUrlA(hInet,
							 //"http://www.sm.rim.or.jp/~shishido/src/httpt.txt",
							 "https://raw.githubusercontent.com/cyginst/cyginst-v1/master/cyginst.bat",
							 NULL, 0, INTERNET_FLAG_RELOAD, 0);

#if 0x0
	/* ファイル読み込み */
	BOOL ok = InternetReadFile(hFile, lpszBuf, 1023, &dwSize);
	if (ok)
	{
		printf("%s\n", lpszBuf);
		printf("%lu\n", dwSize);
	}
#else
	std::string result;
	while (InternetReadFile(hFile, lpszBuf, 1023, &dwSize) && dwSize > 0)
	{
		//printf("%s", lpszBuf);
		result.append(lpszBuf, dwSize);
	}
	//printf("\n");
	printf("%s\n", result.c_str());
#endif

	/* 終了処理 */
	InternetCloseHandle(hFile);
	InternetCloseHandle(hInet);

	return 0;
}