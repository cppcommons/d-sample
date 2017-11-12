#include "os.h"
#include "lib1.h"

extern os_value my_add2(long argc, os_value argv[])
{
	if (argv == nullptr)
	{
		return os_new_integer(2);
	}
	os_integer_t a = os_get_integer(argv[0]);
	os_integer_t b = os_get_integer(argv[1]);
	os_set_integer(argv[0], a * 10);
	os_set_integer(argv[1], b * 10);
	return os_new_integer(a + b);
}
