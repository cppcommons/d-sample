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

void main(string[] args)
{
    // 引数の表示 (utf-8でわたってくる)
    for (int i; i < args.length; i++)
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

    random_test1();
    random_test2();
    random_test3();
    random_test4();
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
{
    version (windows)
    {
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
    else
    { // Not tested!
        import std.path : expandTilde;

        return expandTilde("~/");
    }
}

private void random_test1() // https://qiita.com/yjiro0403/items/55c7c18c04e97f2bc84d
{
    import std.random : uniform, unpredictableSeed, Random;
    import std.stdio : stdout, writeln;

    //upredictableSeedによって実行するごとに異なる乱数列を生成できる
    auto rnd = Random(unpredictableSeed);
    //0から99の整数値をうち一つを出力
    writeln(uniform(0, 100, rnd));
    int i;
    int n;
    for (i = 0; i < 10_000; i++)
    {
        n = uniform(0, 100, rnd);
        if (n < 0 || n > 99)
        {
            writeln("error-1");
            break;
        }
    }
    //0から100の整数値をうち一つを出力
    writeln(uniform!"[]"(0, 100, rnd));
    for (i = 0; i < 10_000; i++)
    {
        n = uniform!"[]"(0, 100, rnd);
        if (n < 0 || n > 100)
        {
            writeln("error-2: ", n);
            break;
        }
    }
    //0から100のうち実数を一つ出力
    writeln(uniform(0.0L, 100.0L, rnd));
    real r;
    for (i = 0; i < 10_000; i++)
    {
        r = uniform(0.0L, 100.0L, rnd);
        if (r < 0.0L || r >= 100.0L)
        {
            writeln("error-3: ", r);
            break;
        }
    }
}

private void random_test2() // https://qiita.com/yjiro0403/items/55c7c18c04e97f2bc84d
{
    import std.random : randomShuffle, uniform, unpredictableSeed, Random;
    import std.stdio : stdout, writeln;

    int[] i = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    //upredictableSeedによって実行するごとに異なる乱数列を生成できる
    auto rnd = Random(unpredictableSeed);
    randomShuffle(i, rnd);
    writeln(i); //[9, 0, 8, 6, 4, 2, 5, 3, 1, 7] (一例)
    //二次元配列でも可能です
    int[][] j = [[0, 1], [2, 3], [4, 5], [6, 7], [8, 9]];
    randomShuffle(j, rnd);
    writeln(j); //[[4, 5], [6, 7], [2, 3], [0, 1], [8, 9]] (一例)
}

private void random_test3() // https://qiita.com/yjiro0403/items/55c7c18c04e97f2bc84d
{
    import std.algorithm.sorting : sort;
    import std.random : dice;
    import std.stdio : stdout, writeln;

    int[int] aa;

    foreach (int i; 0 .. 10_000)
    {
        auto n = dice(5, 3, 2);
        //writeln("random_test3(): ", n);
        int* p = (n in aa);
        if (p is null)
            aa[n] = 1;
        else
            (*p)++;
    }
    foreach (key; aa.keys.sort)
    {
        writeln("random_test3(): ", key, "=", aa[key], "times");
    }
    // Clear the associative array
    foreach (key; aa.keys)
    {
        aa.remove(key);
    }
    foreach (int i; 0 .. 10_000)
    {
        auto n = dice([5, 3, 2]);
        //writeln("random_test3(): ", n);
        int* p = (n in aa);
        if (p is null)
            aa[n] = 1;
        else
            (*p)++;
    }
    foreach (key; aa.keys.sort)
    {
        writeln("random_test3(): ", key, "=", aa[key], "times");
    }
}

private void random_test4() // https://qiita.com/yjiro0403/items/55c7c18c04e97f2bc84d
{
    import std.algorithm.sorting : sort;
    import std.random : randomCover, unpredictableSeed, Random;
    import std.stdio : stdout, writeln;

    int[] a = [0, 1, 2, 3, 4, 5, 6, 7, 8];
    auto rnd = Random(unpredictableSeed);
    int [] result;
    foreach (e; randomCover(a, rnd))
    {
        //writeln(e); //[3, 2, 7, 8, 1, 4, 0, 5, 6]の順で出力(一例)
        result ~= e;
    }
    writeln("random_test4(): ", result);
    result.length = 0;
    foreach (e; randomCover(a, rnd))
    {
        //writeln(e);
        result ~= e;
    }
    writeln("random_test4(): ", result);
}
