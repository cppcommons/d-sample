version (unittest)
{
}
else
	int main()
{
	import std.algorithm : startsWith, endsWith;
	import std.array : join, split;
	import std.datetime.systime : DosFileTimeToSysTime;
	import std.file : mkdirRecurse, read, setTimes;
	import std.stdio : stdout, writefln, writeln;
	import std.stdio : File;
	import std.digest.crc;
	import std.zip;

	writeln("start! start!");
	stdout.flush();

	//mkdirRecurse("aa/bb/cc/dd/");
	string prefix = mk_temp_name(".install");
	writeln(prefix);

	// read a zip file into memory
	auto zip = new ZipArchive(read("msys2-i686-20161025.zip"));
	writeln("Archive: ", "msys2-i686-20161025.zip");
	writefln("%-10s  %-8s  Name", "Length", "CRC-32");
	// iterate over all zip members
	foreach (name, am; zip.directory)
	{
		string path = prefix ~ "/" ~ name;
		if (path.endsWith("/"))
		{
			mkdirRecurse(path);
			setTimes(path, DosFileTimeToSysTime(am.time()), DosFileTimeToSysTime(am.time()));
			continue;
		}
		string[] array = path.split("/");
		auto fname = array[array.length - 1];
		array.length--;
		writeln(array, fname);
		auto dir_part = array.join("/") ~ "/";
		writeln("dir_part=", dir_part);
		// print some data about each member
		writefln("%10s  %08x  %s %s", am.expandedSize, am.crc32, name, am.time());
		assert(am.expandedData.length == 0);
		// decompress the archive member
		zip.expand(am);
		assert(am.expandedData.length == am.expandedSize);
		mkdirRecurse(dir_part);
		auto f = File(path, "wb");
		f.rawWrite(am.expandedData);
		f.close();
		setTimes(path, DosFileTimeToSysTime(am.time()), DosFileTimeToSysTime(am.time()));
	}

	return 0;
}

string mk_temp_name(string s)
{
	import std.uuid;
	import std.random : Xorshift192, unpredictableSeed;
	/+
	//simple call
	auto uuid = randomUUID();
	+/
	//provide a custom RNG. Must be seeded manually.
	Xorshift192 gen;
	gen.seed(unpredictableSeed);
	auto uuid = randomUUID(gen);
	return s ~ "-" ~ uuid.toString();
}
