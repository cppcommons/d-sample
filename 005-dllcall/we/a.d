import core.sys.windows.dll : SimpleDllMain;

mixin SimpleDllMain; // file:///C:\D\dmd2\src\druntime\import\core\sys\windows\dll.d

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

shared static immutable ubyte[] svn_win32_dll_zip = cast(immutable ubyte[]) import(
		"svn-win32-1.8.17-dll.zip");

extern (C) export void cmain()
{
	string[] args = ["dummy.exe"];
	xmain(args);
}

void xmain(string[] args)
{
	import core.thread;
	import std.stdio;
	import std.string;

	//writeln(intl3_svn_dll.length);

	string home = get_home_path();
	writeln(home);

	import core.sys.windows.shlobj;

	writeln(`CSIDL_PROFILE=`, get_common_path(CSIDL_PROFILE, true));
	writeln(`CSIDL_APPDATA=`, get_common_path(CSIDL_APPDATA, true));
	writeln(`CSIDL_LOCAL_APPDATA=`, get_common_path(CSIDL_LOCAL_APPDATA, true));
	writeln(`CSIDL_COMMON_APPDATA=`, get_common_path(CSIDL_COMMON_APPDATA, true));
	writeln(`CSIDL_DESKTOP=`, get_common_path(CSIDL_DESKTOP, true));

	version (Windows)
	{

		string store_path = prepare_sore_path(CSIDL_DESKTOP, "svn-win32-dll", svn_win32_dll_zip);
		writeln(store_path);

		string[] cmdline = ["explorer.exe", store_path];
		run_command(cmdline);

		writeln(sha1_uuid_for_string("OS-1"));

		import std.algorithm : startsWith, endsWith;
		import std.array : join, split;
		import std.datetime.systime : DosFileTimeToSysTime, SysTime;
		import std.file : mkdirRecurse, read, setTimes;
		import std.stdio : stdout, writefln, writeln;

		//import std.stdio : File;
		import std.digest.crc;

		// file:///C:\D\dmd2\src\phobos\std\zip.d
		import std.zip;

		auto zip_md5 = md5_string(svn_win32_dll_zip);
		writeln(`zip_md5=`, zip_md5);
		auto zip = new ZipArchive(cast(void[]) svn_win32_dll_zip);
		writeln("Archive: ", "svn_win32_dll_zip");
		writefln("%-10s  %-8s  %-24s  %s", "Length", "CRC-32", "Name", "Timestamp");
		// iterate over all zip members
		string prefix = store_path;
		prefix = prefix.replace(`\`, `/`);
		foreach (name, am; zip.directory)
		{
			import std.path : baseName;

			string path = prefix ~ "/" ~ name;
			auto fname = baseName(path);
			// print some data about each member
			writefln("%10s  %08x  %-24s  %s", am.expandedSize, am.crc32, name,
					DosFileTimeToSysTime(am.time()));
			assert(am.expandedData.length == 0);
			// decompress the archive member
			zip.expand(am);
			assert(am.expandedData.length == am.expandedSize);
			write_if_not_exist(path, am.expandedData, DosFileTimeToSysTime(am.time()));
		}
		delete zip;

		/+
	CSIDL_PROFILE=C:\Users\javacommons
	CSIDL_APPDATA=C:\Users\javacommons\AppData\Roaming
	CSIDL_LOCAL_APPDATA=C:\Users\javacommons\AppData\Local
	CSIDL_COMMON_APPDATA=C:\ProgramData
	CSIDL_DESKTOP=C:\Users\javacommons\Desktop
	+/
		import std.file : read; // file:///C:\D\dmd2\src\phobos\std\file.d
		import easywin_loader;

		extern (C) HCUSTOMMODULE OS_LoadLibrary(char* a_name, void* a_userdata)
		{
			char[] to_string(char* s)
			{
				import core.stdc.string : strlen;

				return s ? s[0 .. strlen(s)] : cast(char[]) null;
			}

			import core.sys.windows.windows : LoadLibraryA;

			writeln(`[LOAD] `, to_string(a_name));
			return LoadLibraryA(a_name);
		}

		extern (C) EASYWIN_PROC OS_GetProcAddress(HCUSTOMMODULE a_module,
				char* a_name, void* a_userdata)
		{
			char[] to_string(char* s)
			{
				import core.stdc.string : strlen;

				return s ? s[0 .. strlen(s)] : cast(char[]) null;
			}

			import core.sys.windows.winbase : GetProcAddress;

			writeln(`  [PROC] `, to_string(a_name));
			return GetProcAddress(a_module, a_name);
		}

		extern (C) void OS_FreeLibrary(HCUSTOMMODULE a_module, void* a_userdata)
		{
		}
	}

	version (Windows)
	{
		auto dll_bytes = cast(ubyte[]) read( //`C:\Users\javacommons\Desktop\.easy-install\svn-win32-dll-702f3170fedfdd6e20b8f8f5f4fc25f4\libsvn_client-1.dll`
				`vc6-dll.dll`);
		//HMEMORYMODULE hmod = MemoryLoadLibrary(cast(void*) dll_bytes.ptr);
		HMEMORYMODULE hmod = MemoryLoadLibraryEx(cast(void*) dll_bytes.ptr,
				&OS_LoadLibrary, &OS_GetProcAddress, &OS_FreeLibrary, null);
		writefln("0x%08x", hmod);
		EASYWIN_PROC proc = MemoryGetProcAddress(hmod,
				cast(char*) "svn_client__arbitrary_nodes_diff".ptr);
		writefln("0x%08x", proc);
		EASYWIN_PROC proc2 = MemoryGetProcAddress(hmod, cast(char*) "svn_client_version".ptr);
		writefln("0x%08x", proc2);
		EASYWIN_PROC proc3 = MemoryGetProcAddress(hmod, cast(char*) "main".ptr);
		writefln("0x%08x", proc3);
	}

	import vc6;
	import core.sys.windows.windows;
	import core.sys.windows.winbase;

	//HMODULE the_dll = LoadLibraryA(cast(char*) "vc6-dll.dll".ptr);
	//writefln("the_dll=0x%08x", the_dll);
	//proc_main f_main = cast(proc_main) GetProcAddress(the_dll, cast(char*) "main".ptr);
	proc_main f_main = cast(proc_main) proc3;
	writefln("f_main=0x%08x", f_main);
	static char*[] cargs;
	cargs ~= cast(char*) "dummy.exe".ptr;
	cargs ~= cast(char*) "https://github.com/cppcommons/d-sample/trunk".ptr;
	f_main(cargs.length, cargs.ptr);
	writeln("END");
	//exit(0);
}

int run_command(string[] cmdline)
{
	import std.process : spawnProcess, wait;

	auto pid = spawnProcess(cmdline);
	return wait(pid);
}

import std.datetime.systime : SysTime;

void write_if_not_exist(string path, ubyte[] bytes, SysTime time)
{
	import std.file : exists, mkdirRecurse,  /*read,*/ setTimes;
	import std.stdio : File;
	import std.path : dirName;

	if (exists(path))
	{
		import std.stdio : writeln;

		//writeln(`[EXISTS] `, path);
		return;
	}
	string dir_part = dirName(path);
	mkdirRecurse(dir_part);
	auto f = File(path, "wb");
	f.rawWrite(bytes);
	f.close();
	setTimes(path, time, time);
}

string prepare_sore_path(int id, string name, immutable(ubyte[]) bytes)
{
	import std.file : mkdirRecurse; // file:///C:\D\dmd2\src\phobos\std\file.d
	import std.format : format; // file:///C:\D\dmd2\src\phobos\std\format.d
	import std.stdio : writeln; // file:///C:\D\dmd2\src\phobos\std\stdio.d
	import std.string : replace; // file:///C:\D\dmd2\src\phobos\std\string.d

	string dir1 = get_common_path(id, true);
	writeln(`dir1=`, dir1);
	string dir2 = dir1 ~ format!`\.easy-install\%s-%s`(name, md5_string(bytes));
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
	import std.uni : toLower;

	auto md5 = new MD5Digest();
	ubyte[] hash = md5.digest(cast(ubyte[]) bytes);
	return toHexString(hash).toLower;
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
