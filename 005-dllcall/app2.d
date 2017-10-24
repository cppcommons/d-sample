//private const uint unit_size = 400 * 1024; /* 400KB */

version (unittest)
{
}
else
	int main(string[] args)
{
	import core.stdc.stdio : printf;
	import std.conv : to;
	import std.file : read;
	import std.format : format;
	import std.stdio : File;
	import std.process : execute, executeShell;

	printf("args.length=%d\n", args.length);
	if (args.length < 3 || args.length > 4)
	{
		printf("app2 <identifier> <dll-path> [<unit-size>]");
		return 1;
	}

	immutable string identifier = args[1];
	//File f = File("release/dlltest.dll");
	File f = File(args[2]);

	immutable ulong unit_size = (args.length == 4) ? to!ulong(args[3]) : f.size;

	int index = 0;
	foreach (chunk; f.byChunk(cast(uint) unit_size))
	{
		printf("chunk\n");
		write_unit(identifier, index, chunk, unit_size);
		index++;
	}

	auto fname = format!"easy_win_%s_0_codedata.c"(identifier);
	File dll_data_h = File(fname, "w");
	//dll_data_h.writef("extern \"C\" {\n");
	for (int i = 0; i < index; i++)
	{
		dll_data_h.writef("extern const char easy_win_%s_%d[];\n", identifier, i + 1);
	}
	//dll_data_h.writef("}\n");

	dll_data_h.writef("static const char *dll_data_array[] = {\n");
	for (int i = 0; i < index; i++)
	{
		dll_data_h.writef("    easy_win_%s_%d,\n", identifier, i + 1);
	}
	dll_data_h.writef("    0\n");
	dll_data_h.writef("};\n");

	dll_data_h.writef("static const unsigned long dll_data_unit = %u;\n", unit_size);
	dll_data_h.writef("static const int dll_data_count = %d;\n", index);

	dll_data_h.writef(`#include "MemoryModule.c"
extern void *easy_win_%s_get_proc(const char *proc_name)
{
	static HMEMORYMODULE hModule = NULL;
	if (!hModule)
	{
		char *dll_data = (char *)HeapAlloc(GetProcessHeap(), 0, dll_data_unit * dll_data_count);
		char *dll_ptr = dll_data;
		for (int i = 0; i < dll_data_count; i++)
		{
			const char *unit = dll_data_array[i];
			RtlMoveMemory(dll_ptr, unit, dll_data_unit);
			dll_ptr += dll_data_unit;
		}
		hModule = MemoryLoadLibrary(dll_data);
		HeapFree(GetProcessHeap(), 0, dll_data);
	}
	return MemoryGetProcAddress(hModule, proc_name);
}
`, identifier);

	auto fname2 = format!"easy_win_%s_funclist.cpp"(identifier);
	File file2 = File(fname2, "w");
		file2.writef(`#include <windows.h>
#include <stdio.h>

extern "C" void *easy_win_%s_get_proc(const char *proc_name);

class ExportedFunction
{
  public:
	unsigned char opcodes[16];
	explicit ExportedFunction(const char *name)
	{
		printf("ExportedFunction(const char *name): %%s\n", name);
		void *jmpdest = easy_win_%s_get_proc(name);
		opcodes[0] = 0xFF;
		opcodes[1] = 0x25;
		*reinterpret_cast<DWORD *>(opcodes + 2) = reinterpret_cast<DWORD>(opcodes + 6);
		*reinterpret_cast<DWORD *>(opcodes + 6) = reinterpret_cast<DWORD>(jmpdest);
	}
};

#define export_fun(X) extern "C" ExportedFunction X(#X)

`, identifier, identifier);
	auto dmd = execute(["pexports", args[2]]);
	//if (dmd.status != 0) writeln("Compilation failed:\n", dmd.output);
	{
		import std.algorithm : startsWith;
		import std.conv: to;
		import std.stdio: writeln, stdout;
		import std.string: splitLines;

		//writeln(dmd.output);
		writeln(dmd.output.startsWith("LIBRARY "));
		string[] lines = dmd.output.splitLines;
		writeln(lines);
		foreach(line; lines)
		{
			if (line.startsWith("LIBRARY ") || line == "EXPORTS") continue;
			writeln("LINE: ", line);
			stdout.writef("export_fun(%s);\n", line);
			file2.writef("export_fun(%s);\n", line);
		}
	}
	file2.close();

	return 0;
}

private void write_unit(string identifier, int index, ubyte[] bytes, ulong unit_size)
{
	import core.stdc.stdio : fprintf;
	import std.format : format;
	import std.stdio : File;

	bytes.reserve(cast(uint) unit_size);
	while (bytes.length < unit_size)
	{
		bytes ~= 0;
	}
	auto fname = format!"easy_win_%s_%d_codedata.c"(identifier, index + 1);
	auto f = File(fname, "w");
	f.writef("extern const char easy_win_%s_%d[] = {\n", identifier, index + 1);
	int first = true;
	int count = 0;
	foreach (ub; bytes)
	{
		if (count >= 20)
		{
			f.writef("\n");
			count = 0;
		}
		if (first)
			f.writef("  ");
		else
			f.writef(", ");
		first = false;
		f.writef("0x%02x", ub);
		count++;
	}
	f.writef("\n};\n");
	f.close();
}
