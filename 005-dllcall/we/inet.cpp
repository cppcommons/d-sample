// http://www.sm.rim.or.jp/~shishido/httpt.html
// http://www.sm.rim.or.jp/~shishido/src/httpt.txt
/*
   WinInetによるインターネット上ファイルの読み込み

　　　        2001/ 7/ 7  宍戸　輝光

*/
#define UNICODE

#include <stdio.h>
#include <windows.h>
#include <wininet.h>
#include <string>

int main()
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
	while(InternetReadFile(hFile, lpszBuf, 1023, &dwSize) && dwSize > 0)
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