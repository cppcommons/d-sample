import core.sys.windows.windows;
import core.sys.windows.winbase;
import std.windows.registry;

import std.stdio;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

unittest
{
	scope(success) writeln("test @", __FILE__, ":", __LINE__, " succeeded.");
	writeln("hello2!");
    Key HKCU = Registry.currentUser;
    assert(HKCU);
	writeln(HKCU);
}
