#include <windows.h>
#include <stdio.h>
//#include <io.h>
#include <string>
#include <vector>

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

#ifndef ATTACH_PARENT_PROCESS
#define ATTACH_PARENT_PROCESS (DWORD) - 1
#endif

bool AttachParentConsole()
{
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
}

struct ParseArgs_Info
{
	bool use_console;
};

void ParseArgs(ParseArgs_Info &info, std::vector<wchar_t *> &args)
{
	info.use_console = false;
	args.clear();
	int argc;
	LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
	for (int i = 0; i < argc; i++)
	{
		wchar_t *arg = argv[i];
		if (i == 0)
		{
			// skip "run.exe"
			continue;
		}
		if (i == 1)
		{
			std::wstring arg_str = arg;
			if (arg_str == L"-c" || arg_str == L"--console")
			{
				info.use_console = true;
				continue;
			}
		}
		args.push_back(argv[i]);
	}
}

static int RunErrorMessage(const char *format, va_list args)
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
	int len = RunErrorMessage(format, args);
	va_end(args);
	exit(1);
}

static void dbg(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	int len = RunErrorMessage(format, args);
	va_end(args);
}

#ifdef CONSOLE_VERSION
int wmain(int /*argc*/, wchar_t ** /*argv*/)
{
	//bool with_console = false;
	ParseArgs_Info info;
	std::vector<wchar_t *> args;
	ParseArgs(info, args);
#if 0x0
	if (info.use_console)
	{
		with_console = AttachParentConsole();
	}
#endif
	if (args.size() == 0)
	{
		return 0;
	}
	std::wstring dll_name = args[0];
	//dbg("dll_name=%ls", dll_name.c_str());
	std::wstring entry_name = L"RunMain";
	size_t found = dll_name.find(L",");
	if (found != std::string::npos)
	{
		//dbg("found=%lu", found);
		entry_name = dll_name.substr(found + 1);
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
	typedef int (*proc_RunMain)(__int32 argc, wchar_t **argv, DWORD with_console);
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
	if (info.use_console)
	{
		with_console = AttachParentConsole();
	}
	if (args.size() == 0)
	{
		return 0;
	}
	std::wstring dll_name = args[0];
	//dbg("dll_name=%ls", dll_name.c_str());
	std::wstring entry_name = L"RunMain";
	size_t found = dll_name.find(L",");
	if (found != std::string::npos)
	{
		//dbg("found=%lu", found);
		entry_name = dll_name.substr(found + 1);
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
	typedef int (*proc_RunMain)(__int32 argc, wchar_t **argv, DWORD with_console);
	proc_RunMain addr_RunMain = (proc_RunMain)GetProcAddress(hmod, entry_name_ansi.c_str());
	if (!addr_RunMain)
	{
		error("Entry function %ls not found in %ls", entry_name.c_str(), dll_name.c_str());
		return 2;
	}
	int rc = addr_RunMain(args.size(), &args[0], with_console);
	return rc;
}
#endif