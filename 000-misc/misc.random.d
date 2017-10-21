module misc.random;

void misc_main()
{
    import std.stdio : stdout, writeln;
    random_test1();
    random_test2();
    random_test3();
    random_test4();
    writeln(random_bytes(20));
}

ubyte[] random_bytes(size_t length)
{
    import std.random : choice, unpredictableSeed, Random;
    import std.range : iota;

    auto range = iota(0, ubyte.max);
    ubyte[] result;
    result.length = length;
    auto rnd = Random(unpredictableSeed);
    for (int i = 0; i < result.length; i++)
    {
        result[i] = cast(ubyte)choice(range, rnd);
    }
    return result;
}

void random_test1() // https://qiita.com/yjiro0403/items/55c7c18c04e97f2bc84d
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

void random_test2() // https://qiita.com/yjiro0403/items/55c7c18c04e97f2bc84d
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

void random_test3() // https://qiita.com/yjiro0403/items/55c7c18c04e97f2bc84d
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

void random_test4() // https://qiita.com/yjiro0403/items/55c7c18c04e97f2bc84d
{
    import core.stdc.limits : LONG_MAX, LLONG_MAX, ULONG_MAX;
    import std.algorithm.iteration : each;
    import std.algorithm.sorting : sort;
    import std.random : choice, randomCover, randomSample, unpredictableSeed,
        Random;
    import std.range : iota;
    import std.stdio : stdout, writeln;

    int[] a = [0, 1, 2, 3, 4, 5, 6, 7, 8];
    auto rnd = Random(unpredictableSeed);
    int[] result;
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
    //
    writeln("random_test4(): randomSample()==>", randomSample(a, 5)); //[1, 4, 5, 7 , 8] (一例)
    result.length = 0;
    result.length = 15;
    //auto the_range = iota(0, 5);
    //auto the_range = iota(0, 50_000_000);
    long[] result2;
    result2.length = 15;
    //auto the_range = iota(0, LONG_MAX);
    //auto the_range = iota(0, ULONG_MAX);
    auto the_range = iota(0, uint.max);
    //auto the_range = iota(0, LLONG_MAX/2);
    //the_range[0] = 100;
    for (int i = 0; i < result2.length; i++)
    {
        result2[i] = choice(the_range, rnd);
    }
    writeln("random_test4(): ", result2);
}
