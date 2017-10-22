version (unittest)
{
}
else
	int main()
{
	import core.stdc.stdio : printf;
	import std.file : read;
	import std.stdio : File;

	const uint unit_size = 400 * 1024; /* 400KB */
	File f = File("release/dlltest.dll");
	foreach (chunk; f.byChunk(unit_size))
	{
		printf("chunk\n");
	}

	auto bytes = cast(ubyte[]) read("release/dlltest.dll");

	//auto bytes = cast(ubyte[]) read("libcurl.dll");
	//auto bytes = cast(ubyte[]) read("sqlite-win-32bit-3200100.dll");
	printf("extern const char dll_data[] = {\n");
	int first = true;
	int count = 0;
	foreach (ub; bytes)
	{
		if (count >= 20)
		{
			printf("\n");
			count = 0;
		}
		if (first)
			printf("  ");
		else
			printf(", ");
		first = false;
		printf("0x%02x", ub);
		count++;
	}
	printf("\n};\n");

	return 0;
}
