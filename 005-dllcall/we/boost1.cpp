#include "os.h"

#include "lib1.h"

#include <windows.h>
#define _MT
#include <process.h>
#include <vector>

#ifdef __GNUC__
#define THREAD_LOCAL __thread
#else
#define THREAD_LOCAL __declspec(thread)
#endif

static DWORD WINAPI Thread(LPVOID *data)
{
	os_new_integer(1234);
	Sleep(1000);
	ExitThread(0);
	return 0;
}

int main()
{
	os_value ary_ = os_new_array(3);
	os_value *ary = os_get_array(ary_);
	for (int i = 0; i < 4; i++)
	{
		os_value v = ary[i];
		os_dbg("v=0x%016x", v);
	}
	//os_new_std_string("test string テスト文字列");
	os_value s = os_new_string("test string テスト文字列");
	os_dbg("s=[%s]", os_get_string(s));
	os_new_string("string(1)", -1);
	os_new_string("STRING(2)", 3);
	//os_function_t v_func = cos_add2;
	//os_function_t v_func2 = C_Class1::cos_add2;
	os_function_t v_func2 = my_add2;

	//long long cnt1 = os_arg_count(v_func);
	long long cnt2 = os_arg_count(v_func2);
	//os_dbg("cnt1=%lld", cnt1);
	os_dbg("cnt2=%lld", cnt2);

	HANDLE hThread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)Thread, (LPVOID) "カウント数表示：", 0, NULL);

	std::vector<os_value> v_args;
	v_args.push_back(os_new_integer(111));
	v_args.push_back(os_new_integer(222));
	os_dump_heap();
	//os_oid_t v_answer = cos_add2(v_args.size(), &v_args[0]);
	os_value v_answer = v_func2(v_args.size(), &v_args[0]);
	long long v_answer32 = os_get_integer(v_answer);
	os_link(v_answer);
	os_dbg("answer=%d", v_answer32);
	os_dbg("v_args[0]=%lld", os_get_integer(v_args[0]));
	os_dbg("v_args[1]=%lld", os_get_integer(v_args[1]));

	os_value ary2_ = os_new_array(2);
	os_link(ary2_);
	os_value *ary2 = os_get_array(ary2_);
	ary2[0] = os_new_integer(11);
	ary2[1] = os_new_integer(22);
	os_dump_heap();
	os_value v_answer2 = v_func2(2, ary2);
	os_dbg("v_answer2=%lld", os_get_integer(v_answer2));
	os_dbg("ary2[0]=%lld", os_get_integer(ary2[0]));
	os_dbg("ary2[1]=%lld", os_get_integer(ary2[1]));

	os_dump_heap();
	os_dbg("before gc");
	os_sweep();
	os_dbg("after gc");
	os_dump_heap();

	WaitForSingleObject(hThread, INFINITE);

	os_dbg("before gc");
	os_sweep();
	os_dbg("after gc");
	os_dump_heap();
	os_dbg("after dump");

	//os_unlink(v_answer);
	os_dbg("before reset");
	//os_sweep();
	os_reset();
	os_dbg("after reset");
	os_dump_heap();
	os_dbg("after dump");

	return 0;
}
//#include "atlfile.h"
#include "wininet.h" 
#pragma comment(lib,"wininet.lib")
bool DownloadWithPostTest(LPCTSTR pszURL, LPCTSTR pszPostData, LPCTSTR pszLocalFile, DWORD dwBuffSize = 1024)
{
	TCHAR pszAccept[] = _T("Accept: */*");
	TCHAR pszContentType[] = _T("Content-Type: application/x-www-form-urlencoded");
	BOOL ret;
	DWORD dwReadSize;
	DWORD dwWrittenSize;
	BYTE *pcbBuff;
	HRESULT hr;
	HINTERNET hInternet;
	HINTERNET hConnect;
	HINTERNET hRequest;
	TCHAR lpszHostName[256];
	TCHAR lpszScheme[256];
	TCHAR lpszUserName[256];
	TCHAR lpszPassword[256];
	TCHAR lpszUrlPath[1024];
	TCHAR lpszExtraInfo[1024];
	int nFind;
	CAtlFile cFile;
	CAtlString strPath;
	URL_COMPONENTS sComponents;

	//////////////////////////////
	//	URLからサーバー名やポート番号などを取得
	//
	ZeroMemory(&sComponents, sizeof(URL_COMPONENTS));
	sComponents.dwStructSize = sizeof(URL_COMPONENTS);
	sComponents.lpszHostName = lpszHostName;
	sComponents.dwHostNameLength = sizeof(lpszHostName) / sizeof(TCHAR);
	sComponents.lpszScheme = lpszScheme;
	sComponents.dwSchemeLength = sizeof(lpszScheme) / sizeof(TCHAR);
	sComponents.lpszUserName = lpszUserName;
	sComponents.dwUserNameLength = sizeof(lpszUserName) / sizeof(TCHAR);
	sComponents.lpszPassword = lpszPassword;
	sComponents.dwPasswordLength = sizeof(lpszPassword) / sizeof(TCHAR);
	sComponents.lpszUrlPath = lpszUrlPath;
	sComponents.dwUrlPathLength = sizeof(lpszUrlPath) / sizeof(TCHAR);
	sComponents.lpszExtraInfo = lpszExtraInfo;
	sComponents.dwExtraInfoLength = sizeof(lpszExtraInfo) / sizeof(TCHAR);

	ret = ::InternetCrackUrl(pszURL, lstrlen(pszURL), ICU_ESCAPE, &sComponents);
	if (ret == FALSE)
		return false;

	//////////////////////////////
	//	InternetCrackUrlはURLなどに含まれる"%20"などをデコード
	//	してしまうので、関数呼出時のURLのパスを使って接続する
	//	変則的なサーバーは「/index.html?aaa=bbb」というURLに対
	//	してPOSTを要求することもあるので、それにも対応。
	//

	strPath = pszURL;
	nFind = strPath.Find(lpszHostName);
	if (nFind >= 0)
	{
		nFind = strPath.Find(_T("/"), nFind);
		if (nFind >= 0)
			strPath = strPath.Right(strPath.GetLength() - nFind);
	}
	if (nFind < 0)
	{
		strPath = lpszUrlPath;
		strPath += lpszExtraInfo;
	}

	//バッファ確保
	pcbBuff = new BYTE[dwBuffSize];
	if (pcbBuff == NULL)
		return false;

	//////////////////////////////
	//	接続開始
	//

	hInternet = ::InternetOpen(NULL, INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0);

	hConnect = NULL;
	if (hInternet)
		hConnect = ::InternetConnect(hInternet, lpszHostName, sComponents.nPort, lpszUserName, lpszPassword, INTERNET_SERVICE_HTTP, 0, 0);

	hRequest = NULL;
	if (hConnect)
	{
		if (sComponents.nScheme == INTERNET_SCHEME_HTTPS)
			hRequest = ::HttpOpenRequest(hConnect, _T("POST"), strPath, NULL, NULL, (LPCTSTR *)&pszAccept, INTERNET_FLAG_RELOAD | INTERNET_FLAG_SECURE | INTERNET_FLAG_NO_UI | INTERNET_FLAG_KEEP_CONNECTION, 0);
		else
			hRequest = ::HttpOpenRequest(hConnect, _T("POST"), strPath, NULL, NULL, (LPCTSTR *)&pszAccept, INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_UI | INTERNET_FLAG_KEEP_CONNECTION, 0);
	}

	ret = FALSE;
	if (hRequest)
		ret = ::HttpSendRequest(hRequest, pszContentType, lstrlen(pszContentType), (LPVOID)pszPostData, lstrlen(pszPostData));

	//if(ret)
	//{
	//	DWORD	dwContentLength;

	//	dwContentLength = dwBuffSize;
	//	ret = ::HttpQueryInfo(hRequest,HTTP_QUERY_CONTENT_LENGTH,pcbBuff,&dwContentLength,NULL);
	//	if(ret)
	//	{
	//		ATLTRACE(_T("ダウンロードサイズは合計 %d Bytes\n"),dwContentLength);
	//	}
	//	else
	//	{
	//		ATLTRACE(_T("ダウンロードサイズは不明\n"),dwContentLength);
	//	}
	//	ret = TRUE;
	//}

	if (ret)
		ret = SUCCEEDED(cFile.Create(pszLocalFile, GENERIC_WRITE, 0, CREATE_ALWAYS)) ? TRUE : FALSE;
	if (ret)
	{
		while (1)
		{
			::Sleep(0);
			dwReadSize = 0;
			ret = ::InternetReadFile(hRequest, pcbBuff, dwBuffSize, &dwReadSize);
			if (ret == FALSE)
				break;

			if (dwReadSize == 0)
				break;

			hr = cFile.Write(pcbBuff, dwReadSize, &dwWrittenSize);
			if (SUCCEEDED(hr))
				continue;

			ret = FALSE;
			break;
		}
	}

	hr = cFile.Flush();
	cFile.Close();
	if (hRequest)
		::InternetCloseHandle(hRequest);
	if (hConnect)
		::InternetCloseHandle(hConnect);
	if (hInternet)
		::InternetCloseHandle(hInternet);
	delete pcbBuff;

	return (SUCCEEDED(hr) && ret) ? true : false;
}
