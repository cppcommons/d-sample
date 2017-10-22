#include <stdio.h>
#include "MemoryModule.h"

//#include <string>
//#include <fstream>
//#include <streambuf>

int main() 
{
	printf("start!\n");

	FILE * fp = fopen("release/dlltest.dll", "rb");
	//size_t size = fsize(fp);
	fseek(fp, 0, SEEK_END); 
	size_t size = ftell(fp);
	fseek(fp, 0, SEEK_SET);
	char * fcontent = (char *)malloc(size);
	fread(fcontent, 1, size, fp);	
	
	typedef int (*proc_add2)(int a, int b);
	
	HMEMORYMODULE hModule = MemoryLoadLibrary(fcontent);
	printf("0x%08x\n", hModule);

	proc_add2 add2 = (proc_add2)MemoryGetProcAddress(hModule, "add2");
	printf("0x%08x\n", add2);
	
	int ans = add2(11, 22);
	printf("ans=%d\n", ans);
	//std::ifstream t("release/dlltest.dll");
	//std::string str((std::istreambuf_iterator<char>(t)),
	//				 std::istreambuf_iterator<char>());		

	//printf("%u", str.size());
	//HMEMORYMODULE hModule = MemoryLoadLibrary(const void *);
	
	return 0;
}
