module common.util;

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
