// http://www.sm.rim.or.jp/~shishido/httpt.html
// http://www.sm.rim.or.jp/~shishido/src/httpt.txt
/*
   WinInetによるインターネット上ファイルの読み込み

　　　        2001/ 7/ 7  宍戸　輝光

*/

#include <stdio.h>
#include <windows.h>
#include <wininet.h>

int main() {

	HINTERNET hInet;
	HINTERNET hFile;
	LPTSTR lpszBuf;
	DWORD dwSize;

	lpszBuf=(LPTSTR)GlobalAlloc(GPTR,1024);

	/* ハンドル作成 */
	hInet=InternetOpen("TEST",INTERNET_OPEN_TYPE_DIRECT,
	       NULL,NULL,0);

	/* URLオープン */
	hFile=InternetOpenUrl(hInet,
		//"http://www.sm.rim.or.jp/~shishido/src/httpt.txt",
		"https://raw.githubusercontent.com/cyginst/cyginst-v1/master/cyginst.bat",
		NULL,0,INTERNET_FLAG_RELOAD,0);

	/* ファイル読み込み */
	InternetReadFile(hFile,lpszBuf,1023,&dwSize);
	printf("%s\n", lpszBuf);

	/* 終了処理 */
	InternetCloseHandle(hFile);
	InternetCloseHandle(hInet);

	return 0;

}