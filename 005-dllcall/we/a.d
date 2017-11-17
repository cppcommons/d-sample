private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

static shared immutable ubyte[] intl3_svn_dll = cast(immutable ubyte[]) import("intl3_svn.dll");

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

	string[] cmdline = ["explorer.exe", store_path];
	run_command(cmdline);

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
	string dir2 = dir1 ~ "\\.os-1";
	//dir2 = dir2.replace(`\`, `/`);
	writeln(`dir2=`, dir2);
	mkdirRecurse(dir2);
	return dir2;
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
