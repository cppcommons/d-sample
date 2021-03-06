import vc6;

import core.sys.windows.dll : SimpleDllMain; // file:///C:\D\dmd2\src\druntime\import\core\sys\windows\dll.d
mixin SimpleDllMain;

shared static immutable ubyte[] svn_win32_dll_zip = cast(immutable ubyte[]) import(
		"svn-win32-1.8.17-dll.zip");

import core.sys.windows.windows;
import core.sys.windows.winbase;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

int run_command(string[] cmdline)
{
	import std.process;
	import std.stdio;

	auto pipes = pipeProcess(cmdline, Redirect.stdout | Redirect.stderrToStdout);
	foreach (c; pipes.stdout.byChunk(1))
		stdout.rawWrite(c);
	int rc = wait(pipes.pid);
	return rc;
}

static void pause()
{
	string[] cmdline = ["cmd.exe", "/c", "pause"];
	run_command(cmdline);
}

__gshared static string[string] g_module_map;

private static string[] build_args(int argc, wchar** argv)
{
	string[] result;
	for (int i = 0; i < argc; i++)
	{
		result ~= to_string(argv[i]);
	}
	return result;
}

extern (C) export void RunMain(int argc, wchar** argv, DWORD with_console)
{
	import std.stdio; // : writeln;

	string[] args = build_args(argc, argv);
	writeln(args);

	dmain(args);
	pause();
	return;
}

int dmain(string[] args)
{
	import core.thread;
	import std.stdio;
	import std.string;

	writeln(`args=`, args);

	foreach (arg; args)
	{
		writeln(`to_mb_string(arg)=`, to_mb_string(arg));
		writeln(`to_mb_string(arg, 932)=`, to_mb_string(arg, 932));
	}

	//writeln(intl3_svn_dll.length);

	string home = get_home_path();
	writeln(home);

	import core.sys.windows.shlobj;

	writeln(`CSIDL_PROFILE=`, get_common_path(CSIDL_PROFILE, true));
	writeln(`CSIDL_APPDATA=`, get_common_path(CSIDL_APPDATA, true));
	writeln(`CSIDL_LOCAL_APPDATA=`, get_common_path(CSIDL_LOCAL_APPDATA, true));
	writeln(`CSIDL_COMMON_APPDATA=`, get_common_path(CSIDL_COMMON_APPDATA, true));
	writeln(`CSIDL_DESKTOP=`, get_common_path(CSIDL_DESKTOP, true));
	/+
	CSIDL_PROFILE=C:\Users\javacommons
	CSIDL_APPDATA=C:\Users\javacommons\AppData\Roaming
	CSIDL_LOCAL_APPDATA=C:\Users\javacommons\AppData\Local
	CSIDL_COMMON_APPDATA=C:\ProgramData
	CSIDL_DESKTOP=C:\Users\javacommons\Desktop
	+/

	version (Windows)
	{

		//string store_path = prepare_sore_path(CSIDL_DESKTOP, "svn-win32-dll", svn_win32_dll_zip);
		string store_path = prepare_sore_path(CSIDL_APPDATA, "svn-win32-dll", svn_win32_dll_zip);
		writeln(store_path);

		//string[] cmdline = ["explorer.exe", store_path];
		//run_command(cmdline);

		import std.file : exists;

		if (!exists(store_path))
		{

			import std.algorithm : startsWith, endsWith;
			import std.array : join, split;
			import std.datetime.systime : DosFileTimeToSysTime, SysTime;
			import std.file : mkdirRecurse, read, rename, setTimes;
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
			import std.uuid : randomUUID, UUID;

			string prefix;
			do
			{
				prefix = store_path ~ `.` ~ randomUUID().toString();
			}
			while (exists(prefix));
			prefix = prefix.replace(`\`, `/`);
			foreach (name, am; zip.directory)
			{
				import std.path : baseName;
				import std.uni : toUpper;

				string path = prefix ~ "/" ~ name;
				//auto fname = baseName(path).toUpper;
				// print some data about each member
				writefln("%10s  %08x  %-24s  %s", am.expandedSize, am.crc32,
						name, DosFileTimeToSysTime(am.time()));
				assert(am.expandedData.length == 0);
				// decompress the archive member
				zip.expand(am);
				assert(am.expandedData.length == am.expandedSize);
				write_if_not_exist(path, am.expandedData, DosFileTimeToSysTime(am.time()));
				//import std.path : baseName;

				//string basename = baseName(path).toUpper;
				//g_module_map[fname] = path;
			}
			delete zip;
			writeln(prefix);
			writeln(store_path);
			//exit(0);
			rename(prefix, store_path);
		}
		string[] cmdline = ["explorer.exe", store_path];
		run_command(cmdline);
		import std.file : dirEntries, SpanMode;
		import std.path : baseName, dirName;

		auto files = dirEntries(store_path, `*.dll`, SpanMode.breadth);
		foreach (file; files)
		{
			auto key = baseName(file).toUpper;
			g_module_map[key] = file;
		}

		//writeln(g_module_map);

		import std.file : read; // file:///C:\D\dmd2\src\phobos\std\file.d
		import easywin_loader;

		extern (C) HCUSTOMMODULE OS_LoadLibrary(char* a_name, void* a_userdata)
		{
			string to_string(char* s)
			{
				import core.stdc.string : strlen;
				import std.conv : to;

				char[] result = s ? s[0 .. strlen(s)] : cast(char[]) null;
				return to!string(s);
			}

			//return LoadLibraryA(a_name);
			import core.sys.windows.windows;
			import core.sys.windows.winbase;
			import std.path : dirName;

			//import std.string : toStringz;
			import std.uni : toUpper;
			import std.utf : toUTF16z;

			string basename = to_string(a_name);
			string key = basename.toUpper;
			string* found = key in g_module_map;
			writeln(`[LOAD] `, basename);
			if (!found)
				return LoadLibraryA(a_name);
			string folder = dirName(*found);
			const(wchar)* folderW = toUTF16z(folder);
			SetDllDirectoryW(folderW);
			HCUSTOMMODULE hmod = LoadLibraryA(toStringz(basename));
			SetDllDirectoryW(null);
			return hmod;
		}

		extern (C) EASYWIN_PROC OS_GetProcAddress(HCUSTOMMODULE a_module,
				char* a_name, void* a_userdata)
		{
			string to_string(char* s)
			{
				import core.stdc.string : strlen;
				import std.conv : to;

				char[] result = s ? s[0 .. strlen(s)] : cast(char[]) null;
				return to!string(s);
			}

			import core.sys.windows.winbase : GetProcAddress;

			writeln(`  [PROC] `, to_string(a_name));
			return GetProcAddress(a_module, a_name);
		}

		extern (C) void OS_FreeLibrary(HCUSTOMMODULE a_module, void* a_userdata)
		{
		}
	}

	writeln(`a`);

	version (Windows)
	{
		/+
		import std.utf : toUTF16z;
		SetDllDirectoryW(null);
		string folder = store_path;
		writeln(`folder=`, folder);
		const(wchar)* folderW = toUTF16z(folder);
		SetDllDirectoryW(folderW);
		+/
		auto dll_bytes = cast(ubyte[]) read( //`C:\Users\javacommons\Desktop\.easy-install\svn-win32-dll-702f3170fedfdd6e20b8f8f5f4fc25f4\libsvn_client-1.dll`
				`vc6.dll`);
		//HMEMORYMODULE hmod = MemoryLoadLibrary(cast(void*) dll_bytes.ptr);
		HMEMORYMODULE hmod = MemoryLoadLibraryEx(cast(void*) dll_bytes.ptr,
				&OS_LoadLibrary, &OS_GetProcAddress, &OS_FreeLibrary, null);
		//SetDllDirectoryW(null);
		writefln("0x%08x", hmod);
		/+
		EASYWIN_PROC proc = MemoryGetProcAddress(hmod,
				cast(char*) "svn_client__arbitrary_nodes_diff".ptr);
		writefln("0x%08x", proc);
		EASYWIN_PROC proc2 = MemoryGetProcAddress(hmod, cast(char*) "svn_client_version".ptr);
		writefln("0x%08x", proc2);
		EASYWIN_PROC proc3 = MemoryGetProcAddress(hmod, cast(char*) "main".ptr);
		writefln("0x%08x", proc3);
		+/
	}

	writeln(`b`);

	import vc6;
	import core.sys.windows.windows;
	import core.sys.windows.winbase;

	/+
	proc_main f_main = cast(proc_main) proc3;
	writefln("f_main=0x%08x", f_main);
	static char*[] cargs;
	cargs ~= cast(char*) "dummy.exe".ptr;
	cargs ~= cast(char*) "https://github.com/cppcommons/d-sample/trunk".ptr;
	f_main(cargs.length, cargs.ptr);
	writeln("END");
	+/

	string url = args.length >= 2 ? args[1] : "https://github.com/cppcommons/d-sample/trunk";
	import std.string : toStringz;

	const char* urlz = toStringz(url);
	/+
easy_svn_context * easy_svn_create();
alias easy_svn_context * function()proc_easy_svn_create;
void  easy_svn_destroy(easy_svn_context *context);
alias void  function(easy_svn_context *context)proc_easy_svn_destroy;
easy_svn_dirent * easy_svn_ls(easy_svn_context *context, char *url, bool recursive);
alias easy_svn_dirent * function(easy_svn_context *context, char *url, bool recursive)proc_easy_svn_ls;
alias easy_svn_procs * function()proc_get_easy_svn_procs;
	+/
	proc_easy_svn_create easy_svn_create = cast(proc_easy_svn_create) MemoryGetProcAddress(hmod,
			cast(char*) "easy_svn_create".ptr);
	proc_easy_svn_destroy easy_svn_destroy = cast(proc_easy_svn_destroy) MemoryGetProcAddress(hmod,
			cast(char*) "easy_svn_destroy".ptr);
	proc_easy_svn_ls easy_svn_ls = cast(proc_easy_svn_ls) MemoryGetProcAddress(hmod,
			cast(char*) "easy_svn_ls".ptr);
	easy_svn_context* context = easy_svn_create();
	easy_svn_dirent* entries = easy_svn_ls(context, cast(char*) urlz, false);
	if (entries)
	{
		for (; (*entries).entryname !is null; entries++)
		{
			writefln(`%s %d %d`, to_string((*entries).entryname), (*entries)
					.entry.created_rev, (*entries).entry.time);
		}
	}
	easy_svn_destroy(context);
	struct my_easy_svn_procs
	{
		proc_easy_svn_create easy_svn_create;
		proc_easy_svn_destroy easy_svn_destroy;
		proc_easy_svn_ls easy_svn_ls;
	}

	my_easy_svn_procs procs;
	procs.easy_svn_create = easy_svn_create;
	procs.easy_svn_destroy = easy_svn_destroy;
	procs.easy_svn_ls = easy_svn_ls;
	writeln("a");
	pause();
	context = procs.easy_svn_create();
	writeln("b2");
	entries = procs.easy_svn_ls(context, cast(char*) urlz, false);
	writeln("c");
	pause();
	if (entries)
	{
		for (; (*entries).entryname !is null; entries++)
		{
			writefln(`%s %d %d`, to_string((*entries).entryname), (*entries)
					.entry.created_rev, (*entries).entry.time);
		}
	}
	writeln("d");
	pause();
	//procs.easy_svn_destroy(context);
	writeln("e");
	pause();
	return 0;
}

/+
int run_command(string[] cmdline)
{
	import std.process : spawnProcess, wait;

	auto pid = spawnProcess(cmdline);
	return wait(pid);
}
+/

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
	//writeln(`dir1=`, dir1);
	string dir2 = dir1 ~ format!`\.easy-install\%s-%s`(name, md5_string(bytes));
	//writeln(`dir2=`, dir2);
	//mkdirRecurse(dir2);
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

string to_string(char* s)
{
	import core.stdc.string : strlen;
	import std.conv : to;

	char[] result = s ? s[0 .. strlen(s)] : cast(char[]) null;
	return to!string(s);
}

string to_string(wchar* s)
{
	import core.stdc.wchar_ : wcslen;
	import std.conv : to;

	wchar[] result = s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
	return to!string(to!wstring(result));
}

wstring to_wstring(wchar* s)
{
	import core.stdc.wchar_ : wcslen;
	import std.conv : to;

	wchar[] result = s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
	return to!wstring(result);
}

string to_mb_string(in char[] s, uint codePage = 0)
{
	import std.windows.charset : toMBSz;
	import std.conv : to;

	const(char)* mbsz = toMBSz(s, codePage);
	return to_string(cast(char*) mbsz);
}

string to_mb_string(in wchar[] s, uint codePage = 0)
{
	import std.windows.charset : toMBSz;
	import std.conv : to;

	string utf8 = to!string(s);
	const(char)* mbsz = toMBSz(utf8, codePage);
	return to_string(cast(char*) mbsz);
}
