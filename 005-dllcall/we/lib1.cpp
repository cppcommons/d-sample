#include "lib1.h"

//extern "C" os_function my_mul2;
extern "C" os_value my_mul2(os_heap heap, long argc, os_value argv[]);

#include <stdio.h>

extern os_value my_add2(os_heap heap, long argc, os_value argv[])
{
	printf("my_add2(0): 0x%p\n", my_mul2);
	if (argc != 2)
	{
		return 0;
	}
	//os_value a10 = my_mul2(heap, argc, argv);
	//argv[0] = a10;
	long a = (long)os_get_integer(argv[0]);
	long b = (long)os_get_integer(argv[1]);
	a = d_mul2(a, 10);
	printf("my_add2(1)\n");
	printf("my_add2(2)\n");
	//argv[0] = os_new_integer(heap, a * 10);
	argv[1] = os_new_integer(heap, b * 10);
	return os_new_integer(heap, a + b);
}
