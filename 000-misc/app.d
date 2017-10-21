// app.d

char[] toString(char* s)
{
    import core.stdc.string : strlen;

    return s ? s[0 .. strlen(s)] : cast(char[]) null;
}

// http://forum.dlang.org/post/c6ojg9$c8p$1@digitaldaemon.com
wchar[] toString(wchar* s)
{
    import core.stdc.wchar_ : wcslen;

    return s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
}

void main(string [] args)
{
    for (int i; i<args.length; i++)
    {
        import std.stdio : stdout, writeln;
        writeln(i, "=", args[i]);
    }

    define_test(); // DEFINE テスト

    { // カレントディレクトリの取得
        import std.file : getcwd;
        import std.stdio : stdout, writeln;

        string cwd = getcwd();
        writeln(cwd);
        stdout.flush();
    }

    { // ホームディレクトリの取得
        import std.file : getcwd;
        import std.stdio : stdout, writeln;

        string home = getHomePath();
        writeln("home=", home);
        stdout.flush();
    }

    { // SJISへの変換
        import std.conv : to;
        import std.stdio : stdout, writeln;
        import std.string : toStringz;
        import std.windows.charset : fromMBSz, toMBSz;

        string kanji = "[漢字]";
        writeln("kanji=", kanji);
        string sjis = to!(string)(toMBSz(kanji, 932));
        writeln("utf8 to sjis : ", sjis);
        writeln("sjis to utf8 : ", fromMBSz(toStringz(sjis), 932));

        wstring wkanji = to!wstring(kanji);
        writeln("wkanji=", wkanji);
    }
}

private void define_test()
{
    version (COMPILER_DM32)
    {
        import std.stdio : stdout, writeln;

        writeln("DM32");

    }
    else version (COMPILER_MS32)
    {
        import std.stdio : stdout, writeln;

        writeln("MS32");

    }
    else
    {
        import std.stdio : stdout, writeln;

        writeln("UNKNOWN COMPILER");
    }

}

private string getHomePath()
{ // from http://forum.dlang.org/post/otuvjlaoivpubftxdhxt@forum.dlang.org
    import core.sys.windows.shlobj : CSIDL_PROFILE, SHGetFolderPathW;
    import core.sys.windows.windows : MAX_PATH;
    import std.conv : to;

    wchar[] toString(wchar* s)
    {
        import core.stdc.wchar_ : wcslen;

        return s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
    }

    wchar[MAX_PATH] buffer;
    if (SHGetFolderPathW(null, CSIDL_PROFILE, null, 0, buffer.ptr) >= 0)
        return to!string(toString(buffer.ptr));
    return null;
}
