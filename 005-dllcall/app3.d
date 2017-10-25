version (unittest)
{
}
else
	int main()
{
	import std.algorithm : startsWith, endsWith;
	import std.stdio : stdout, writefln, writeln;
	import std.digest.crc, std.file, std.zip;

	writeln("start! start!");
	stdout.flush();

	mkdirRecurse("aa/bb/cc/dd/");

	// read a zip file into memory
	auto zip = new ZipArchive(read("msys2-i686-20161025.zip"));
	writeln("Archive: ", "msys2-i686-20161025.zip");
	writefln("%-10s  %-8s  Name", "Length", "CRC-32");
	// iterate over all zip members
	foreach (name, am; zip.directory)
	{
		if (!name.endsWith("/")) continue;
		// print some data about each member
		writefln("%10s  %08x  %s", am.expandedSize, am.crc32, name);
		assert(am.expandedData.length == 0);
		// decompress the archive member
		zip.expand(am);
		assert(am.expandedData.length == am.expandedSize);
	}

	return 0;
}
