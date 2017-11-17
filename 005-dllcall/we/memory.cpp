#define DEBUG_OUTPUT
#include "MemoryModule-micro.cpp"
#include <stdio.h>
#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>

#if 0x0
static HMEMORYMODULE MemoryLoadLibrary(const void *);
/**
 * Load DLL from memory location using custom dependency resolvers.
 *
 * Dependencies will be resolved using passed callback methods.
 */
static HMEMORYMODULE MemoryLoadLibraryEx(const void *,
										 CustomLoadLibraryFunc,
										 CustomGetProcAddressFunc,
										 CustomFreeLibraryFunc,
										 void *);
/**
 * Get address of exported method.
 */
static FARPROC MemoryGetProcAddress(HMEMORYMODULE, LPCSTR);
#endif

std::string readFile(const char *filename)
{
	std::ifstream f(filename, std::ios::in | std::ios::binary);
	if (!f.is_open())
		return "";
	//f.seekg(0, std::ios::end);
	//size_t size = f.tellg();
	//f.seekg(0);
	//std::cout << "size=" << size << std::endl;
	std::stringstream buffer;
	buffer << f.rdbuf();
	return buffer.str;
}

int main()
{
	printf("memory.cpp\n");
	const char *filename = "vc6-run.dll";
	std::string content = readFile(filename);
	std::cout << "content.length=" << content.size() << std::endl;
	HMEMORYMODULE hmod = MemoryLoadLibrary(content.c_str());
	printf("hmod=0x%p\n", hmod);
	printf("hmod(2)=0x%08x\n", hmod);
	return 0;
}