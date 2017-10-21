// app.d

//private shared immutable ubyte[] libcurl_dll = cast(immutable ubyte[]) import("libcurl.dll@v2.076.1.bin");
//private shared ubyte[] libcurl_dll = cast(ubyte[]) import("libcurl.dll@v2.076.1.bin");

void main(string[] args)
{
    prepare_libcurl();
    {
        import std.conv : to;
        import std.net.curl : byChunkAsync;
        import std.stdio : stdout, writeln;

        ubyte[] bytes;
        foreach (chunk; byChunkAsync("http://dlang.org", 20))
        {
            writeln(chunk);
            stdout.flush();
            bytes ~= chunk;
        }
        writeln("bytes.length=", bytes.length);
        writeln(cast(char[]) bytes);
    }
}

private string prepare_libcurl()
{
    static shared immutable ubyte[] libcurl_dll = cast(immutable ubyte[]) import(
            "libcurl.dll@v2.076.1.bin");
    //static shared ubyte[] libcurl_dll = cast(ubyte[]) import("libcurl.dll@v2.076.1.bin"); /* writable */
    import std.file : exists, read, thisExePath, write;
    import std.path : dirName, dirSeparator;
    import std.stdio : stdout, writeln;

    immutable string exe = thisExePath();
    writeln("exe=", exe);
    immutable string out_path = dirName(exe) ~ dirSeparator ~ "libcurl.dll";
    writeln("out_path=", out_path);
    if (!exists(out_path))
    {
        writeln("libcurl_dll.length=", libcurl_dll.length);
        write(out_path, libcurl_dll);
        version (none)
        {
            ubyte[] bytes = cast(ubyte[]) read(out_path);
            writeln("bytes.length=", bytes.length);
            assert(bytes == libcurl_dll);
        }
    }
    return out_path;
}
