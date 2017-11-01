void main(string[] args)
{
    import core.stdc.stdio;
    import core.thread;
    import std.stdio : writeln;

    writeln(args);

    int i, j;
    int times = 1000;
    writeln("hello!");
    //setbuf(stdout, null);
    fprintf(stdout, "stdout\n");
    printf("0%%       50%%       100%%\n");
    printf("+---------+---------+\n");
    for (i = 0; i < times; i++)
    {
        /* 適当な処理 */
        Thread.sleep(dur!("msecs")(5));
        if (i % (times / 20) == times / 20 - 1)
        {
            /* プログレスバーの表示 */
            for (j = 0; j < (i + 1) / (times / 20) + 1; j++)
                printf("#");
            /* キャリッジリターンを利用して先頭にカーソルを移動 */
            printf("\r");
        }
    }
    fprintf(stdout, "\n");
}
