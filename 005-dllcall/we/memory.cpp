#define DEBUG_OUTPUT
#include "MemoryModule-micro.cpp"
#include <stdio.h>
#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>
#include <set>
#include <map>
#include <algorithm>
//#include <string>

//std::vector<HCUSTOMMODULE> g_module_list;
std::set<HCUSTOMMODULE> g_module_set;
std::map<std::string, HCUSTOMMODULE> g_module_map;

inline std::string readFile(const char *filename)
{
	std::ifstream f(filename, std::ios::in | std::ios::binary);
	if (!f.is_open())
		return "";
	std::stringstream buffer;
	buffer << f.rdbuf();
	return buffer.str();
}

inline std::string readSvnDll(const char *basename)
{
	std::string folder = "E:\\opt\\svn\\vc6\\svn-win32-1.8.17-ap24\\svn-win32-1.8.17\\bin";
	std::string path = folder + "\\" + std::string(basename);
	std::string content = readFile(path.c_str());
	return content;
}

static HMEMORYMODULE OS_MemoryLoadLibrary(const void *data);

static HCUSTOMMODULE OS_LoadLibrary(LPCSTR filename, void *userdata)
{
	//std::cout << "[LOAD] " << filename << std::endl;
	std::string filename2 = filename;
	std::transform(filename2.begin(), filename2.end(), filename2.begin(), ::tolower);
	if (g_module_map.count(filename2) > 0)
	{
		std::cout << "[ALREADY LOADED] " << filename2 << std::endl;
		return g_module_map[filename2];
	}
	std::string content = readSvnDll(filename);
	if (content.size() > 0)
	{
		if (
			filename2.rfind("libapr", 0) == 0 ||
			filename2.rfind("libsvn_client-1", 0) == 0 ||
			filename2.rfind("libsvn_delta-1", 0) == 0 ||
			filename2.rfind("libsvn_diff-1", 0) == 0 ||
			filename2.rfind("libsvn_fs-1", 0) == 0 ||
			//filename2.rfind("libsvn_ra-1", 0) == 0 ||
			filename2.rfind("libsvn_repos-1", 0) == 0 ||
			//filename2.rfind("libsvn_subr-1", 0) == 0 ||
			filename2.rfind("libsvn_wc-1", 0) == 0 ||
			filename2.rfind("sasl", 0) == 0 ||
			filename2.rfind("intl3", 0) == 0 ||
			filename2.rfind("libeay32", 0) == 0 ||
			filename2.rfind("libdb48", 0) == 0)
		{
			std::cout << "[MEMORY]" << filename2 << " [SIZE] " << content.size() << std::endl;
			HCUSTOMMODULE v_module = OS_MemoryLoadLibrary(content.c_str());
			g_module_set.insert(v_module);
			g_module_map[filename2] = v_module;
			return v_module;
		}
	}
	HMODULE result = LoadLibraryA(filename);
	if (result == NULL)
	{
		return NULL;
	}

	return (HCUSTOMMODULE)result;
}

static FARPROC OS_GetProcAddress(HCUSTOMMODULE module, LPCSTR name, void *userdata)
{
//std::cout << name << std::endl;
#if 0x1
	if (g_module_set.count(module) > 0)
	{
#if 0x0
		if (IS_INTRESOURCE(name))
			std::cout << "  [FOUND(int)] " << (int)name << std::endl;
		else
			std::cout << "  [FOUND] " << name << std::endl;
#endif
		return MemoryGetProcAddress((HMEMORYMODULE)module, name);
	}
#endif
	return (FARPROC)GetProcAddress((HMODULE)module, name);
}

static void OS_FreeLibrary(HCUSTOMMODULE module, void *userdata)
{
	//FreeLibrary((HMODULE)module);
}

static HMEMORYMODULE OS_MemoryLoadLibrary(const void *data)
{
	return MemoryLoadLibraryEx(data, OS_LoadLibrary, OS_GetProcAddress, OS_FreeLibrary, NULL);
}

int main()
{
	printf("memory.cpp\n");
	const char *filename = "vc6-run.dll";
	std::string content = readFile(filename);
	std::cout << "content.length=" << content.size() << std::endl;
	HMEMORYMODULE hmod = OS_MemoryLoadLibrary(content.c_str());
	printf("hmod=0x%p\n", hmod);
	printf("hmod(2)=0x%08x\n", hmod);
	if (hmod)
	{
		typedef int (*proc_main)(int argc, const char **argv);
		proc_main f_main = (proc_main)MemoryGetProcAddress(hmod, "main");
		printf("f_main=0x%p\n", f_main);
		std::vector<const char *> v_args;
		v_args.push_back("dummy.exe");
		v_args.push_back("https://github.com/cppcommons/d-sample/trunk");
		f_main(v_args.size(), &v_args[0]);
	}
	return 0;
}