#include <windows.h>
#include <stdio.h>

extern "C" void *my_library_get_proc(const char *proc_name);

static void write_abs_jump(unsigned char *opcodes, const void *jmpdest)
{
	// Taken from: https://www.gamedev.net/forums/topic/566233-x86-asm-help-understanding-jmp-opcodes/
    opcodes[0] = 0xFF; 
    opcodes[1] = 0x25;
    *reinterpret_cast<DWORD *>(opcodes + 2) = reinterpret_cast<DWORD>(opcodes + 6);
	*reinterpret_cast<DWORD *>(opcodes + 6) = reinterpret_cast<DWORD>(jmpdest);
}

//extern "C" unsigned char add2[10] = { 0 };
#define export_fun(X) extern "C" unsigned char X[10] = { 0 }
export_fun(add2);
//typedef unsigned char opcode_t[10];
//extern "C" opcode_t add2;

class Dummy2
{
  public:
	explicit Dummy2()
	{
		/*
		DWORD dw = (DWORD)my_library_get_proc("add2");
		printf("dw=0x%08x\n", dw);
		*((DWORD *)&add2[1]) = dw;
		printf("Dummy2::Dummy2()\n");
		*/
	}
};

Dummy2 dummy2;

extern "C" int
add2_old(int a, int b)
{
	typedef int (*proc_add2)(int a, int b);
	static proc_add2 _add2 = (proc_add2)my_library_get_proc("add2");
	return _add2(a, b);
}

extern "C" int test1()
{
	typedef int (*proc_test1)();
	static proc_test1 _test1 = (proc_test1)my_library_get_proc("test1");
	//return _test1();
	void *dw = my_library_get_proc("add2");
	printf("dw=0x%08x\n", dw);
	write_abs_jump(add2, dw);
	return 111;
}

extern "C" int test2()
{
	typedef int (*proc_test2)();
	static proc_test2 _test2 = (proc_test2)my_library_get_proc("test2");
	return _test2();
}

static int myfunc()
{
	return 3 + 4;
}

class Dummy
{
  public:
	int a;
	explicit Dummy()
	{
		a = myfunc();
	}
};

static Dummy dummy;

extern "C" int dvalue()
{
	return dummy.a;
}