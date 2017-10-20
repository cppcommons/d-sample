// from http://forum.dlang.org/post/otuvjlaoivpubftxdhxt@forum.dlang.org
// #define CSIDL_PROFILE 0x0028
import core.sys.windows.windows; // C:\D\dmd2\src\druntime\src\core\sys\windows
import core.sys.windows.shlobj : CSIDL_PROFILE;

import core.sys.windows.winhttp; // C:\D\dmd2\src\druntime\src\core\sys\windows

void main()
{
    import std.stdio;
    {
        import core.stdc.wchar_ : wcslen;
        import std.conv : to;
        import std.string : toStringz;
        import std.utf : toUTF16z;

        string app = "Sample Application/1.0";
        //string url = "https://raw.githubusercontent.com/cyginst/ms2inst-v1/master/binaries/msys2-i686-20161025.7z";
        string url = "https://raw.githubusercontent.com/cyginst/ms2inst-v1/master/ms2inst.bat";

        URL_COMPONENTS urlComponents;

        assert(urlComponents.dwStructSize == 0);
        urlComponents.dwStructSize = urlComponents.sizeof;

        const wchar* urlZ = to!(wstring)(url).toUTF16z;
        {
            import core.stdc.stdio;

            printf("%ls\n", urlZ);
        }
        writeln(wcslen(urlZ));

        wchar[] hostNameZ;
        hostNameZ.length = wcslen(urlZ) + 1;
        urlComponents.lpszHostName = cast(wchar*)&hostNameZ[0];
        urlComponents.dwHostNameLength = hostNameZ.length;
        writeln(hostNameZ.length);

        wchar[] urlPathZ;
        urlPathZ.length = wcslen(urlZ) + 1;
        urlComponents.lpszUrlPath = cast(wchar*)&urlPathZ[0];
        urlComponents.dwUrlPathLength = urlPathZ.length;
        writeln(urlPathZ.length);

        if (!WinHttpCrackUrl(urlZ, wcslen(urlZ), 0, &urlComponents))
        {
            writeln("1");
            return;
        }
        writeln("2");
        writeln(hostNameZ[0 .. wcslen(cast(wchar*) hostNameZ)]);
        writeln(urlPathZ[0 .. wcslen(cast(wchar*) urlPathZ)]);
        writeln(urlComponents.nPort);

        const wchar* appZ = to!(wstring)(app).toUTF16z;
        auto hSession = WinHttpOpen(appZ, WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
        if (hSession == NULL)
        {
            writeln("3");
            return;
        }
        writeln("4");

        auto hConnect = WinHttpConnect(hSession, cast(wchar*) hostNameZ, urlComponents.nPort, 0);
        if (hConnect == NULL)
        {
            WinHttpCloseHandle(hSession);
            writeln("5");
            return;
        }
        writeln("6");

        DWORD dwOpenRequestFlag = (INTERNET_SCHEME_HTTPS == urlComponents.nScheme) ? WINHTTP_FLAG_SECURE
            : 0;
        writefln("dwOpenRequestFlag=0x%08x", dwOpenRequestFlag);
        auto hRequest = WinHttpOpenRequest(hConnect, "GET", cast(wchar*) urlPathZ,
                NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, dwOpenRequestFlag);
        if (hRequest == NULL)
        {
            WinHttpCloseHandle(hConnect);
            WinHttpCloseHandle(hSession);
            writeln("7");
            return;
        }
        writeln("8");

        if (!WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, 0,
                WINHTTP_NO_REQUEST_DATA, 0, WINHTTP_IGNORE_REQUEST_TOTAL_LENGTH, 0))
        {
            WinHttpCloseHandle(hRequest);
            WinHttpCloseHandle(hConnect);
            WinHttpCloseHandle(hSession);
            writeln("9");
            return;
        }
        writeln("10");

        WinHttpReceiveResponse(hRequest, NULL);
        writeln("11");

        DWORD dwSizeWithZero = 0; //unit = sizeof(wchar_t)
        WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_RAW_HEADERS_CRLF,
                WINHTTP_HEADER_NAME_BY_INDEX, NULL, &dwSizeWithZero, WINHTTP_NO_HEADER_INDEX);
        wchar[] headerZ;
        headerZ.length = dwSizeWithZero;
        WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_RAW_HEADERS_CRLF, WINHTTP_HEADER_NAME_BY_INDEX,
                cast(wchar*) headerZ, &dwSizeWithZero, WINHTTP_NO_HEADER_INDEX);
        writeln(headerZ[0 .. wcslen(cast(wchar*) headerZ)]);
        writeln("12");

        char[] lpData;
        DWORD dwTotalSize = 0;
        DWORD dwSize = 0;

        for (;;)
        {
            WinHttpQueryDataAvailable(hRequest, &dwSize);
            if (!dwSize)
                break;
            writefln("dwSize=%u", dwSize);
            lpData.length = dwTotalSize + dwSize;
            WinHttpReadData(hRequest, cast(char*)&lpData[dwTotalSize], dwSize, NULL);
            dwTotalSize += dwSize;
        }
        writeln(lpData);

        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        writeln("end");

    }
}
