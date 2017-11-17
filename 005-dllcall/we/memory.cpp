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
	std::cout << "[LOAD] " << filename << std::endl;
	std::string filename2 = filename;
	//filename2 = filename2.toupper();
	std::transform(filename2.begin(), filename2.end(), filename2.begin(), ::toupper);
	if (g_module_map.count(filename2) > 0)
	{
		std::cout << "[ALREADY LOADED] " << filename2 << std::endl;
		return g_module_map[filename2];
	}
	std::string content = readSvnDll(filename);
	if (content.size() > 0)
	{
		std::cout << "  [SIZE] " << content.size() << std::endl;
		HCUSTOMMODULE v_module = OS_MemoryLoadLibrary(content.c_str());
		g_module_set.insert(v_module);
		g_module_map[filename2] = v_module;
		return v_module;
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
		if (IS_INTRESOURCE(name))
			std::cout << "  [FOUND(int)] " << (int)name << std::endl;
		else
			std::cout << "  [FOUND] " << name << std::endl;
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
	return 0;
}