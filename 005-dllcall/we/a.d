private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

shared static immutable ubyte[] svn_win32_dll_zip = cast(immutable ubyte[]) import(
		"svn-win32-1.8.17-dll.zip");
shared static immutable ubyte[] intl3_svn_dll = cast(immutable ubyte[]) import("intl3_svn.dll");
shared static immutable ubyte[][string] g_map;
shared static this()
{
	g_map["intl3_svn.dll"] = cast(immutable ubyte[]) import("intl3_svn.dll");
	g_map["libapr-1.dll"] = cast(immutable ubyte[]) import("libapr-1.dll");
	g_map["libapriconv-1.dll"] = cast(immutable ubyte[]) import("libapriconv-1.dll");
	g_map["libaprutil-1.dll"] = cast(immutable ubyte[]) import("libaprutil-1.dll");
	g_map["libdb48.dll"] = cast(immutable ubyte[]) import("libdb48.dll");
	g_map["libeay32.dll"] = cast(immutable ubyte[]) import("libeay32.dll");
	g_map["libsasl.dll"] = cast(immutable ubyte[]) import("libsasl.dll");
	g_map["libsvn_client-1.dll"] = cast(immutable ubyte[]) import("libsvn_client-1.dll");
	g_map["libsvn_delta-1.dll"] = cast(immutable ubyte[]) import("libsvn_delta-1.dll");
	g_map["libsvn_diff-1.dll"] = cast(immutable ubyte[]) import("libsvn_diff-1.dll");
	g_map["libsvn_fs-1.dll"] = cast(immutable ubyte[]) import("libsvn_fs-1.dll");
	g_map["libsvn_ra-1.dll"] = cast(immutable ubyte[]) import("libsvn_ra-1.dll");
	g_map["libsvn_repos-1.dll"] = cast(immutable ubyte[]) import("libsvn_repos-1.dll");
	g_map["libsvn_subr-1.dll"] = cast(immutable ubyte[]) import("libsvn_subr-1.dll");
	g_map["libsvn_wc-1.dll"] = cast(immutable ubyte[]) import("libsvn_wc-1.dll");
	g_map["saslANONYMOUS.dll"] = cast(immutable ubyte[]) import("saslANONYMOUS.dll");
	g_map["saslCRAMMD5.dll"] = cast(immutable ubyte[]) import("saslCRAMMD5.dll");
	g_map["saslDIGESTMD5.dll"] = cast(immutable ubyte[]) import("saslDIGESTMD5.dll");
	g_map["saslLOGIN.dll"] = cast(immutable ubyte[]) import("saslLOGIN.dll");
	g_map["saslNTLM.dll"] = cast(immutable ubyte[]) import("saslNTLM.dll");
	g_map["saslOTP.dll"] = cast(immutable ubyte[]) import("saslOTP.dll");
	g_map["saslPLAIN.dll"] = cast(immutable ubyte[]) import("saslPLAIN.dll");
	g_map["saslSASLDB.dll"] = cast(immutable ubyte[]) import("saslSASLDB.dll");
	g_map["saslSRP.dll"] = cast(immutable ubyte[]) import("saslSRP.dll");
	g_map["ssleay32.dll"] = cast(immutable ubyte[]) import("ssleay32.dll");
}

/+


+/

void main(string[] args)
{
	import core.thread;
	import std.stdio;
	import std.string;

	writeln(intl3_svn_dll.length);

	string home = get_home_path();
	writeln(home);

	import core.sys.windows.shlobj;

	writeln(`CSIDL_PROFILE=`, get_common_path(CSIDL_PROFILE, true));
	writeln(`CSIDL_APPDATA=`, get_common_path(CSIDL_APPDATA, true));
	writeln(`CSIDL_LOCAL_APPDATA=`, get_common_path(CSIDL_LOCAL_APPDATA, true));
	writeln(`CSIDL_COMMON_APPDATA=`, get_common_path(CSIDL_COMMON_APPDATA, true));
	writeln(`CSIDL_DESKTOP=`, get_common_path(CSIDL_DESKTOP, true));

	string store_path = prepare_sore_path(CSIDL_DESKTOP);
	writeln(store_path);

	/+
	string abs_path = store_path ~ `\` ~ `intl3_svn.dll`;
	File f = File(abs_path, "wb");
	f.rawWrite(intl3_svn_dll);
	f.close();
	writefln(`  ===> Writing to: %s`, abs_path);
	+/

	/+
	string[] keys = g_map.keys;
	foreach (key; keys)
	{
		//g_map["intl3_svn.dll"] = cast(immutable ubyte[]) import("intl3_svn.dll");
		immutable ubyte[] bytes = g_map[key];
		string abs_path = store_path ~ `\` ~ key;
		writefln(`  ===> Writing to: %s (%u bytes)`, abs_path, bytes.length);
		File f = File(abs_path, "wb");
		f.rawWrite(bytes);
		f.close();
	}
	+/

	string[] cmdline = ["explorer.exe", store_path];
	run_command(cmdline);

	writeln(sha1_uuid_for_string("OS-1"));

	import std.algorithm : startsWith, endsWith;
	import std.array : join, split;
	import std.datetime.systime : DosFileTimeToSysTime;
	import std.file : mkdirRecurse, read, setTimes;
	import std.stdio : stdout, writefln, writeln;
	import std.stdio : File;
	import std.digest.crc;

	// file:///C:\D\dmd2\src\phobos\std\zip.d
	import std.zip;

	auto zip_uuid = md5_string(svn_win32_dll_zip);
	writeln(`zip_uuid=`, zip_uuid);
	auto zip = new ZipArchive(cast(void[]) svn_win32_dll_zip);
	writeln("Archive: ", "svn_win32_dll_zip");
	writefln("%-10s  %-8s  Name", "Length", "CRC-32");
	// iterate over all zip members
	string prefix = store_path;
	prefix = prefix.replace(`\`, `/`);
	foreach (name, am; zip.directory)
	{
		string path = prefix ~ "/" ~ name;
		//string path = name;
		/+
		if (path.endsWith("/"))
		{
			mkdirRecurse(path);
			setTimes(path, DosFileTimeToSysTime(am.time()), DosFileTimeToSysTime(am.time()));
			continue;
		}+/
		string[] array = path.split("/");
		auto fname = array[array.length - 1];
		array.length--;
		writeln(array, fname);
		string dir_part = "";
		if (array.length > 0)
		{
			dir_part = array.join("/"); // ~ "/";
		}
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

	/+
	CSIDL_PROFILE=C:\Users\javacommons
	CSIDL_APPDATA=C:\Users\javacommons\AppData\Roaming
	CSIDL_LOCAL_APPDATA=C:\Users\javacommons\AppData\Local
	CSIDL_COMMON_APPDATA=C:\ProgramData
	CSIDL_DESKTOP=C:\Users\javacommons\Desktop
	+/

	exit(0);
}

int run_command(string[] cmdline)
{
	import std.process : spawnProcess, wait;

	auto pid = spawnProcess(cmdline);
	return wait(pid);
}

string prepare_sore_path(int id)
{
	/+
	import std.file : chdir, copy, dirEntries, exists, getcwd, mkdirRecurse,
		read, rename, remove, rmdirRecurse, setTimes, write, FileException,
		PreserveAttributes, SpanMode;
	+/
	// file:///C:\D\dmd2\src\phobos\std\file.d
	import std.file : mkdirRecurse;

	// file:///C:\D\dmd2\src\phobos\std\stdio.d
	import std.stdio : writeln;

	// file:///C:\D\dmd2\src\phobos\std\string.d
	import std.string : replace;

	string dir1 = get_common_path(id, true);
	writeln(`dir1=`, dir1);
	string dir2 = dir1 ~ `\.easy-install\` ~ sha1_uuid_for_string("OS-1");
	writeln(`dir2=`, dir2);
	mkdirRecurse(dir2);
	return dir2;
}

private string sha1_uuid_for_string(string s)
{
	// file:///C:\D\dmd2\src\phobos\std\uuid.d
	import std.uuid : sha1UUID, UUID;

	string uuid = sha1UUID(s).toString;
	return uuid;
}

private string sha1_uuid_for_bytes(ubyte[] bytes)
{
	// file:///C:\D\dmd2\src\phobos\std\uuid.d
	import std.uuid : sha1UUID, UUID;

	string uuid = sha1UUID(bytes).toString;
	return uuid;
}

private string sha1_uuid_for_bytes(immutable ubyte[] bytes)
{
	// file:///C:\D\dmd2\src\phobos\std\uuid.d
	import std.uuid : sha1UUID, UUID;

	string uuid = sha1UUID(cast(ubyte[]) bytes).toString;
	return uuid;
}

private string md5_string(immutable ubyte[] bytes)
{
	// file:///C:\D\dmd2\src\phobos\std\digest\md.d
	import std.digest.md;

	auto md5 = new MD5Digest();
	ubyte[] hash = md5.digest(cast(ubyte[]) bytes);
	return toHexString(hash);
}

private string get_home_path(bool create = false)
{
	version (Windows)
	{
		// file:///C:\D\dmd2\src\druntime\import\core\sys\windows\shlobj.d
		import core.sys.windows.shlobj : CSIDL_PROFILE;

		return get_common_path(CSIDL_PROFILE, create);
	}
	else
	{ // Not tested!
		import std.path : expandTilde;

		return expandTilde("~/");
	}
}

private string get_common_path(int id, bool create = false)
{
	version (Windows)
	{
		// file:///C:\D\dmd2\src\druntime\import\core\sys\windows\shlobj.d
		import core.sys.windows.shlobj : CSIDL_FLAG_CREATE, SHGetFolderPathW;

		// file:///C:\D\dmd2\src\druntime\import\core\sys\windows\windows.d
		import core.sys.windows.windows : MAX_PATH;

		// file:///C:\D\dmd2\src\phobos\std\conv.d
		import std.conv : to;

		wchar[] to_string(wchar* s)
		{
			import core.stdc.wchar_ : wcslen;

			return s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
		}

		if (create)
			id |= CSIDL_FLAG_CREATE;
		wchar[MAX_PATH] buffer;
		if (SHGetFolderPathW(null, id, null, 0, buffer.ptr) >= 0)
			return to!string(to_string(buffer.ptr));
		return null;
	}
	else
	{ // Not tested!
		import std.path : expandTilde;

		return expandTilde("~/");
	}
}

/+
// file:///C:/D/dmd2/src/druntime/import/core/sys/windows/shlobj.d
import core.sys.windows.shlobj;
enum {
    CSIDL_DESKTOP            =  0,
    CSIDL_INTERNET,
    CSIDL_PROGRAMS,
    CSIDL_CONTROLS,
    CSIDL_PRINTERS,
    CSIDL_PERSONAL,
    CSIDL_FAVORITES,
    CSIDL_STARTUP,
    CSIDL_RECENT,
    CSIDL_SENDTO,
    CSIDL_BITBUCKET,
    CSIDL_STARTMENU,      // = 11
    CSIDL_MYMUSIC            = 13,
    CSIDL_MYVIDEO,        // = 14
    CSIDL_DESKTOPDIRECTORY   = 16,
    CSIDL_DRIVES,
    CSIDL_NETWORK,
    CSIDL_NETHOOD,
    CSIDL_FONTS,
    CSIDL_TEMPLATES,
    CSIDL_COMMON_STARTMENU,
    CSIDL_COMMON_PROGRAMS,
    CSIDL_COMMON_STARTUP,
    CSIDL_COMMON_DESKTOPDIRECTORY,
    CSIDL_APPDATA,
    CSIDL_PRINTHOOD,
    CSIDL_LOCAL_APPDATA,
    CSIDL_ALTSTARTUP,
    CSIDL_COMMON_ALTSTARTUP,
    CSIDL_COMMON_FAVORITES,
    CSIDL_INTERNET_CACHE,
    CSIDL_COOKIES,
    CSIDL_HISTORY,
    CSIDL_COMMON_APPDATA,
    CSIDL_WINDOWS,
    CSIDL_SYSTEM,
    CSIDL_PROGRAM_FILES,
    CSIDL_MYPICTURES,
    CSIDL_PROFILE,
    CSIDL_SYSTEMX86,
    CSIDL_PROGRAM_FILESX86,
    CSIDL_PROGRAM_FILES_COMMON,
    CSIDL_PROGRAM_FILES_COMMONX86,
    CSIDL_COMMON_TEMPLATES,
    CSIDL_COMMON_DOCUMENTS,
    CSIDL_COMMON_ADMINTOOLS,
    CSIDL_ADMINTOOLS,
    CSIDL_CONNECTIONS,  // = 49
    CSIDL_COMMON_MUSIC     = 53,
    CSIDL_COMMON_PICTURES,
    CSIDL_COMMON_VIDEO,
    CSIDL_RESOURCES,
    CSIDL_RESOURCES_LOCALIZED,
    CSIDL_COMMON_OEM_LINKS,
    CSIDL_CDBURN_AREA,  // = 59
    CSIDL_COMPUTERSNEARME  = 61,
    CSIDL_FLAG_DONT_VERIFY = 0x4000,
    CSIDL_FLAG_CREATE      = 0x8000,
    CSIDL_FLAG_MASK        = 0xFF00
}
+/
