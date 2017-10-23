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

static void register_proc(const char *proc_name, unsigned char *opcode)
{
	void *proc = my_library_get_proc("add2");
	//printf("%s=0x%08x\n", proc_name, proc);
	write_abs_jump(opcode, proc);
}

//extern "C" unsigned char add2[10] = { 0 };
#define export_fun(X) extern "C" unsigned char X[10] = {0}
#define register_fun(X) register_proc(#X, X)

//export_fun(add2);
//export_fun(test1);
//export_fun(test2);

static class Dummy2
{
  public:
	explicit Dummy2()
	{
		//register_fun(add2);
		//register_fun(test1);
		//register_fun(test2);
	}
} dummy2;

class ExportedFunction {
public:
	unsigned char opcode[10];
	explicit ExportedFunction(const char *name)
	{
		printf("ExportedFunction(const char *name): %s\n", name);
		register_proc(name, opcode);
	}
};

//extern "C" ExportedFunction add2("add2");
#define export_fun2(X) extern "C" ExportedFunction X(#X)
export_fun2(add2);
export_fun2(test1);
export_fun2(test2);

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