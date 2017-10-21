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

void main()
{
    define_test(); // DEFINE テスト

    { // カレントディレクトリの取得
        import std.file : getcwd;
        import std.stdio : stdout, writeln;

        string cwd = getcwd();
        writeln(cwd);
        stdout.flush();
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
