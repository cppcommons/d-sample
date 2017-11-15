import b;

import core.memory;
import core.sync.mutex;
import std.algorithm.sorting;
import std.array;
import std.bigint;
import std.format;
import std.stdio;
import std.string;

extern (C) int d_mul2(int a, int b)
{
	writefln(`d_mul(%d, %d)`, a, b);
	return a * b;
}

extern (C) os_object my_mul2(int argc, os_object *argv)
{
	writeln(`my_mul2(0)`);
	if (argc != 2)
		return null;
	long a0 = os_get_integer(argv[0]);
	long a1 = os_get_integer(argv[1]);
	return os_new_integer(a0 * a1);
}

extern (C) void my_str1(os_string s)
{

}

private void dummy()
{
	os_function f1 = &my_mul2;
}