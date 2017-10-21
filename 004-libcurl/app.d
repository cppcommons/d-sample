// app.d

private shared immutable ubyte[] libcurl_dll = cast(immutable ubyte[]) import(
        "libcurl.dll@v2.076.1.bin");
//private shared ubyte[] libcurl_dll = cast(ubyte[]) import("libcurl.dll@v2.076.1.bin");

void main(string[] args)
{

    {
        import std.file : thisExePath, read, write;
        import std.path : dirName, dirSeparator;
        import std.stdio : stdout, writeln;

        writeln(thisExePath());
        string exe = thisExePath();
        writeln("dirName(exe)=", dirName(exe));
        writeln(dirName(exe) ~ dirSeparator ~ "temp.libcurl.dll");

        writeln("libcurl_dll.length=", libcurl_dll.length);
        write(dirName(exe) ~ dirSeparator ~ "temp.libcurl.dll", libcurl_dll);

        ubyte[] bytes = cast(ubyte[])read(dirName(exe) ~ dirSeparator ~ "temp.libcurl.dll");
        writeln("bytes.length=", bytes.length);
        assert(bytes == libcurl_dll);

    }

}
