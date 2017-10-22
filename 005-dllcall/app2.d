private const uint unit_size = 400 * 1024; /* 400KB */

version (unittest)
{
}
else
	int main()
{
	import core.stdc.stdio : printf;
	import std.file : read;
	import std.stdio : File;

	File f = File("release/dlltest.dll");
	int index = 0;
	foreach (chunk; f.byChunk(unit_size))
	{
		printf("chunk\n");
		write_unit(index, chunk);
		index++;
	}

	File dll_data_h = File("dll_data.c", "w");
	//dll_data_h.writef("extern \"C\" {\n");
	for (int i=0; i<index; i++)
	{
		dll_data_h.writef("extern const char dll_data_%d[];\n", i+1);
	}
	//dll_data_h.writef("}\n");

	dll_data_h.writef("static const char *dll_data_array[] = {\n");
	for (int i=0; i<index; i++)
	{
		dll_data_h.writef("    dll_data_%d,\n", i+1);
	}
	dll_data_h.writef("    0\n");
	dll_data_h.writef("};\n");

	dll_data_h.writef("const unsigned long dll_data_unit = %u;\n", unit_size);
	dll_data_h.writef("const int dll_data_count = %d;\n", index);

	//auto bytes = cast(ubyte[]) read("release/dlltest.dll");

	//auto bytes = cast(ubyte[]) read("libcurl.dll");
	//auto bytes = cast(ubyte[]) read("sqlite-win-32bit-3200100.dll");
	dll_data_h.writef(`#include "MemoryModule.c"
extern void *get_proc(const char *proc_name)
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
`);

	return 0;
}

private void write_unit(int index, ubyte[] bytes)
{
	import core.stdc.stdio : fprintf;
	import std.format : format;
	import std.stdio : File;

	bytes.reserve(unit_size);
	while (bytes.length < unit_size)
	{
		bytes ~= 0;
	}
	auto fname = format!"dll_data_%d.c"(index + 1);
	auto f = File(fname, "w");
	f.writef("extern const char dll_data_%d[] = {\n", index + 1);
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
