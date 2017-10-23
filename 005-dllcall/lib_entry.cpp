extern "C" void *my_library_get_proc(const char *proc_name);

extern "C" int add2(int a, int b)
{
	typedef int (*proc_add2)(int a, int b);
	static proc_add2 _add2 = (proc_add2)my_library_get_proc("add2");
	return _add2(a, b);
}

extern "C" int test1()
{
	typedef int (*proc_test1)();
	static proc_test1 _test1 = (proc_test1)my_library_get_proc("test1");
	return _test1();
}

static int myfunc()
{
	return 3 + 4;
}

class Dummy
{
  public:
	int a;
	explicit Dummy()
	{
		a = myfunc();
	}
};

static Dummy dummy;

extern "C" int dvalue()
{
	return dummy.a;
}