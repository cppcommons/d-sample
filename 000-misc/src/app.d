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
    {
        import std.file : getcwd;
        import std.stdio : stdout, writeln;

        string cwd = getcwd();
        writeln(cwd);
        stdout.flush();
    }

}
