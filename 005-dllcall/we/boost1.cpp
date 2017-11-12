#include "os.h"

#include <windows.h>
#define _MT
#include <process.h>
#include <vector>

#ifdef __GNUC__
#define THREAD_LOCAL __thread
#else
#define THREAD_LOCAL __declspec(thread)
#endif

static os_value cos_add2(long argc, os_value argv[])
{
	if (argv == nullptr)
	{
		return os_new_integer(2);
	}
	//if (argc < 0)
	//	return os_new_integer(2);
	os_integer_t a = os_get_integer(argv[0]);
	os_integer_t b = os_get_integer(argv[1]);
	return os_new_integer(a + b);
}

struct C_Class1
{
	explicit C_Class1()
	{
		os_dbg("Constructor");
	}
	virtual ~C_Class1()
	{
		os_dbg("Destructor");
	}
	static os_value cos_add2(long argc, os_value argv[])
	{
		if (argv == nullptr)
		{
			return os_new_integer(2);
		}
		//if (argc < 0)
		//	return os_new_integer(2);
		int a = (int)os_get_integer(argv[0]);
		int b = (int)os_get_integer(argv[1]);
		os_set_integer(argv[0], a * 10);
		os_set_integer(argv[1], b * 10);
		return os_new_integer(a + b);
	}
};

static DWORD WINAPI Thread(LPVOID *data)
{
	os_new_integer(1234);
	Sleep(1000);
	ExitThread(0);
	return 0;
}

int main()
{
	os_new_std_string("test string テスト文字列");
	os_new_string("string(1)", -1);
	os_new_string("STRING(2)", 3);
	os_function_t v_func = cos_add2;
	os_function_t v_func2 = C_Class1::cos_add2;

	os_integer_t cnt1 = os_arg_count(v_func);
	os_integer_t cnt2 = os_arg_count(v_func2);
	os_dbg("cnt1=%lld", cnt1);
	os_dbg("cnt2=%lld", cnt2);

#if 0x0
	os_thread_id tid1 = os_get_thread_id();
	os_dbg("tid1=%s", tid1.c_str());
#endif
	HANDLE hThread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)Thread, (LPVOID) "カウント数表示：", 0, NULL);

	std::vector<os_value> v_args;
	v_args.push_back(os_new_integer(111));
	v_args.push_back(os_new_integer(222));
	//v_args[0] = os_new_integer(111);
	//v_args[1] = os_new_integer(222);
	os_dump_object_heap();
	//os_oid_t v_answer = cos_add2(v_args.size(), &v_args[0]);
	os_value v_answer = v_func2(v_args.size(), &v_args[0]);
	os_integer_t v_answer32 = os_get_integer(v_answer);
	os_oid_link(v_answer);
	os_dbg("answer=%d", v_answer32);
	os_dbg("v_args[0]=%lld", os_get_integer(v_args[0]));
	os_dbg("v_args[1]=%lld", os_get_integer(v_args[1]));

	os_dump_object_heap();
	os_dbg("before gc");
	os_cleanup();
	os_dbg("after gc");
	os_dump_object_heap();

	WaitForSingleObject(hThread, INFINITE);

	os_dbg("before gc");
	os_cleanup();
	os_dbg("after gc");
	os_dump_object_heap();
	os_dbg("after dump");

	os_oid_unlink(v_answer);
	os_dbg("before gc");
	os_cleanup();
	os_dbg("after gc");
	os_dump_object_heap();
	os_dbg("after dump");

	return 0;
}
