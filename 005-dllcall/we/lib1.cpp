#include "lib1.h"

extern os_value my_add2(long argc, os_value argv[])
{
	if (argc != 2)
	{
		return 0;
	}
	long a = (long)os_get_integer(argv[0]);
	long b = (long)os_get_integer(argv[1]);
	argv[0] = os_new_integer(0, a * 10);
	argv[1] = os_new_integer(0, b * 10);
	return os_new_integer(0, a + b);
}
