#include <windows.h>
#include <stdio.h>
//#include <io.h>
#include <string>
#include <vector>
#include <cstdlib>

#if __cplusplus >= 201103L
inline std::wstring cp_to_wide(const std::string &s, UINT codepage)
{
	int in_length = (int)s.length();
	int out_length = MultiByteToWideChar(codepage, 0, s.c_str(), in_length, 0, 0);
	std::wstring result(out_length, L'\0');
	if (out_length)
		MultiByteToWideChar(codepage, 0, s.c_str(), in_length, &result[0], out_length);
	return result;
}
inline std::string wide_to_cp(const std::wstring &s, UINT codepage)
{
	int in_length = (int)s.length();
	int out_length = WideCharToMultiByte(codepage, 0, s.c_str(), in_length, 0, 0, 0, 0);
	std::string result(out_length, '\0');
	if (out_length)
		WideCharToMultiByte(codepage, 0, s.c_str(), in_length, &result[0], out_length, 0, 0);
	return result;
}
#else /* __cplusplus < 201103L */
inline std::wstring cp_to_wide(const std::string &s, UINT codepage)
{
	int in_length = (int)s.length();
	int out_length = MultiByteToWideChar(codepage, 0, s.c_str(), in_length, 0, 0);
	std::vector<wchar_t> buffer(out_length);
	if (out_length)
		MultiByteToWideChar(codepage, 0, s.c_str(), in_length, &buffer[0], out_length);
	std::wstring result(buffer.begin(), buffer.end());
	return result;
}
inline std::string wide_to_cp(const std::wstring &s, UINT codepage)
{
	int in_length = (int)s.length();
	int out_length = WideCharToMultiByte(codepage, 0, s.c_str(), in_length, 0, 0, 0, 0);
	std::vector<char> buffer(out_length);
	if (out_length)
		WideCharToMultiByte(codepage, 0, s.c_str(), in_length, &buffer[0], out_length, 0, 0);
	std::string result(buffer.begin(), buffer.end());
	return result;
}
#endif

static std::wstring ansi_to_wide(const std::string &s)
{
	return cp_to_wide(s, CP_ACP);
}
static std::string wide_to_ansi(const std::wstring &s)
{
	return wide_to_cp(s, CP_ACP);
}

//#ifndef ATTACH_PARENT_PROCESS
//#define ATTACH_PARENT_PROCESS (DWORD) - 1
//#endif

bool AttachParentConsole()
{
	return (bool)AttachConsole(ATTACH_PARENT_PROCESS);
#if 0x0
	static bool attached = false;
	if (attached)
		return true;
	HMODULE hmod = LoadLibraryA("kernel32.dll");
	if (!hmod)
		return false;
	typedef BOOL(WINAPI * proc_AttachConsole)(DWORD dwProcessId);
	proc_AttachConsole addr_AttachConsole = (proc_AttachConsole)GetProcAddress(hmod, "AttachConsole");
	if (!addr_AttachConsole)
		return false;
	attached = (bool)addr_AttachConsole(ATTACH_PARENT_PROCESS);
	return attached;
#endif
}

static int ShowMessage(const char *format, va_list args)
{
	const int BUFF_LEN = 10240;
	static char v_buffer[BUFF_LEN + 1];
	v_buffer[BUFF_LEN] = 0;
	int len = _vsnprintf(v_buffer, BUFF_LEN, format, args);
	::MessageBoxA(NULL, v_buffer, "RUN", MB_OK);
	return len;
}

static void error(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	int len = ShowMessage(format, args);
	va_end(args);
	exit(1);
}

static void dbg(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	int len = ShowMessage(format, args);
	va_end(args);
}

struct ParseArgs_Info
{
	bool alloc_console;
	bool no_console;
	__int32 wait;
	explicit ParseArgs_Info()
	{
		this->alloc_console = false;
		this->no_console = false;
		this->wait = -1;
	}
};

void ParseArgs(ParseArgs_Info &info, std::vector<wchar_t *> &args)
{
	//info.alloc_console = false;
	//info.no_console = false;
	args.clear();
	int argc;
	LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
	bool opt_end = false;
	for (int i = 0; i < argc; i++)
	{
		wchar_t *arg = argv[i];
		std::wstring arg_str = arg;
		if (i == 0)
		{
			// skip "run.exe"
			continue;
		}
		if (!opt_end && (arg_str.size() == 0 || arg_str[0] != L'-'))
		{
			opt_end = true;
		}
		if (opt_end)
		{
			args.push_back(arg);
			continue;
		}
		if (arg_str == L"-ac" || arg_str == L"--allocate-console")
		{
			info.alloc_console = true;
			continue;
		}
		if (arg_str == L"-nc" || arg_str == L"--no-console")
		{
			info.no_console = true;
			continue;
		}
		if (arg_str == L"-w" || arg_str == L"--wait")
		{
			if (i == (argc - 1))
			{
				//error("%ls require argument in milliseconds.", arg_str.c_str());
				continue;
			}
			std::wstring msec = argv[i + 1];
			std::string msec_ansi = wide_to_ansi(msec);
			info.wait = std::atol(msec_ansi.c_str());
			i++;
			continue;
		}
		args.push_back(argv[i]);
	}
}

typedef DWORD (*proc_RunMain)(size_t argc, wchar_t **argv, DWORD with_console);

#ifdef CONSOLE_VERSION
int main(int /*argc*/, char ** /*argv*/)
{
	ParseArgs_Info info;
	std::vector<wchar_t *> args;
	ParseArgs(info, args);
	if (info.wait >= 0)
	{
		::Sleep(info.wait);
	}
	if (args.size() == 0)
	{
		return 0;
	}
	std::wstring dll_name = args[0];
	//dbg("dll_name=%ls", dll_name.c_str());
	std::wstring entry_name = L"RunMain";
	//size_t found = dll_name.find(L",");
	size_t found = dll_name.find(L"@:");
	if (found != std::string::npos)
	{
		//dbg("found=%lu", found);
		//entry_name = dll_name.substr(found + 1);
		entry_name = dll_name.substr(found + 2);
		//dbg("entry_name=%ls", entry_name.c_str());
		dll_name = dll_name.substr(0, found);
		//dbg("dll_name=%ls", dll_name.c_str());
	}
	std::string entry_name_ansi = wide_to_ansi(entry_name);
	//dbg("entry_name_ansi=%s", entry_name_ansi.c_str());
	HMODULE hmod = LoadLibraryW(dll_name.c_str());
	if (!hmod)
	{
		error("%ls is not valid DLL.", dll_name.c_str());
	}
	proc_RunMain addr_RunMain = (proc_RunMain)GetProcAddress(hmod, entry_name_ansi.c_str());
	if (!addr_RunMain)
	{
		error("Entry function %ls not found in %ls", entry_name.c_str(), dll_name.c_str());
		return 2;
	}
	int rc = addr_RunMain(args.size(), &args[0], /*with_console*/ 3);
	return rc;
}
#else
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	bool with_console = false;
	ParseArgs_Info info;
	std::vector<wchar_t *> args;
	ParseArgs(info, args);
	if (info.wait >= 0)
	{
		::Sleep(info.wait);
	}
	if (args.size() == 0)
	{
		return 0;
	}
	if (info.alloc_console)
	{
		//dbg("AllocConsole()");
		with_console = (bool)AllocConsole();
	}
	else if (!info.no_console)
	{
		with_console = AttachParentConsole();
		//dbg("AttachParentConsole(): %d", with_console);
	}
	std::wstring dll_name = args[0];
	//dbg("dll_name=%ls", dll_name.c_str());
	std::wstring entry_name = L"RunMain";
	//size_t found = dll_name.find(L",");
	size_t found = dll_name.find(L"@:");
	if (found != std::string::npos)
	{
		//dbg("found=%lu", found);
		//entry_name = dll_name.substr(found + 1);
		entry_name = dll_name.substr(found + 2);
		//dbg("entry_name=%ls", entry_name.c_str());
		dll_name = dll_name.substr(0, found);
		//dbg("dll_name=%ls", dll_name.c_str());
	}
	std::string entry_name_ansi = wide_to_ansi(entry_name);
	//dbg("entry_name_ansi=%s", entry_name_ansi.c_str());
	HMODULE hmod = LoadLibraryW(dll_name.c_str());
	if (!hmod)
	{
		error("%ls is not valid DLL.", dll_name.c_str());
	}
	proc_RunMain addr_RunMain = (proc_RunMain)GetProcAddress(hmod, entry_name_ansi.c_str());
	if (!addr_RunMain)
	{
		error("Entry function %ls not found in %ls", entry_name.c_str(), dll_name.c_str());
		return 2;
	}
	#if 0x0
	if (info.wait >= 0)
	{
		::Sleep(info.wait);
	}
	#endif
	DWORD rc = addr_RunMain((size_t)args.size(), &args[0], with_console);
	if (info.alloc_console && with_console)
	{
		freopen("CONIN$", "r", stdin);
		freopen("CONOUT$", "w", stdout);
		//freopen("CONOUT$", "w", stderr);
		fprintf(stdout, "[PAUSE] HIT ENTER KEY TO EXIT (EXIT CODE=%d): ", rc);
		fflush(stdout);
		getchar();
	}
	return rc;
}
#endif