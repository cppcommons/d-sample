#include "os.h"
#include "lib1.h"

extern os_value my_add2(long argc, os_value argv[])
{
	if (argv == nullptr)
	{
		return os_new_integer(2);
	}
	long a = (long)os_get_integer(argv[0]);
	long b = (long)os_get_integer(argv[1]);
	os_set_integer(argv[0], a * 10);
	os_set_integer(argv[1], b * 10);
	#if 0x0
	bool rc_a = os_set_integer(argv[0], a * 10);
	bool rc_b = os_set_integer(argv[1], b * 10);
	os_dbg("rc_a=%d rc_b=%d", rc_a, rc_b);
	#endif
	return os_new_integer(a + b);
}
