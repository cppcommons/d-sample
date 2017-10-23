extern "C" void *sqlite_get_proc(const char *proc_name);

struct sqlite3_stmt {};

#if 0x0
// SQLITE_API int sqlite3_bind_parameter_index(sqlite3_stmt*, const char *zName);
extern "C" int sqlite3_bind_parameter_index(sqlite3_stmt* stmt, const char *zName)
{
	typedef int (*proc_sqlite3_bind_parameter_index)(sqlite3_stmt*, const char *zName);
	static proc_sqlite3_bind_parameter_index fun =
	 (proc_sqlite3_bind_parameter_index)sqlite_get_proc("sqlite3_bind_parameter_index");
	return fun(stmt, zName);
}

extern "C" int add2(int a, int b)
{
	typedef int (*proc_add2)(int a, int b);
	static proc_add2 _add2 = (proc_add2)sqlite_get_proc("add2");
	return _add2(a, b);
}

extern "C" int test1()
{
	typedef int (*proc_test1)();
	static proc_test1 _test1 = (proc_test1)sqlite_get_proc("test1");
	return _test1();
}

extern "C" int test2()
{
	typedef int (*proc_test2)();
	static proc_test2 _test2 = (proc_test2)sqlite_get_proc("test2");
	return _test2();
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
#endif