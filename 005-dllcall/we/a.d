import os;
import lib1;

void main(string[] args)
{
	import core.stdc.stdio;
	import core.thread;
	import std.stdio : writeln;

	os_value[] argv;
	argv ~= os_new_integer(11);
	argv ~= os_new_integer(22);
	os_value answer = my_add2(argv.length, &argv[0]);
	os_dump_object_heap();
	os_integer_t answer2 = os_get_integer(answer);
	writeln(answer2);

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
