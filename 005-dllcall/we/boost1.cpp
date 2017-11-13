#include "os.h"

#include "lib1.h"

#include <windows.h>
#define _MT
#include <process.h>
#include <vector>

#ifdef __GNUC__
#define THREAD_LOCAL __thread
#else
#define THREAD_LOCAL __declspec(thread)
#endif

static DWORD WINAPI Thread(LPVOID *data)
{
	os_new_integer(1234);
	Sleep(1000);
	ExitThread(0);
	return 0;
}

int main()
{
	os_dbg("DBG!");
	os_value my_handle = os_new_handle((void *)0x123456);
	os_value ary_ = os_new_array(3);
	os_value *ary = os_get_array(ary_);
	for (int i = 0; i < 4; i++)
	{
		os_value v = ary[i];
		os_dbg("v=0x%016x", v);
	}
	//os_new_std_string("test string テスト文字列");
	os_value s = os_new_string("test string テスト文字列");
	std::string buffer;
	os_get_string(s, buffer);
	os_dbg("buffer=[%s]", buffer.c_str());

	os_dbg("s=[%s]", os_get_string(s));
	os_new_string("string(1)", -1);
	os_new_string("STRING(2)", 3);
	//os_function_t v_func = cos_add2;
	//os_function_t v_func2 = C_Class1::cos_add2;
	os_function_t v_func2 = my_add2;

	//long long cnt1 = os_arg_count(v_func);
	//long long cnt2 = os_arg_count(v_func2);
	//os_dbg("cnt1=%lld", cnt1);
	//os_dbg("cnt2=%lld", cnt2);

	HANDLE hThread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)Thread, (LPVOID) "カウント数表示：", 0, NULL);

	std::vector<os_value> v_args;
	v_args.push_back(os_new_integer(111));
	v_args.push_back(os_new_integer(222));
	os_dump_heap();
	//os_oid_t v_answer = cos_add2(v_args.size(), &v_args[0]);
	os_value v_answer = v_func2(v_args.size(), &v_args[0]);
	long long v_answer32 = os_get_integer(v_answer);
	os_mark(v_answer);
	os_dbg("answer=%d", v_answer32);
	os_dbg("v_args[0]=%lld", os_get_integer(v_args[0]));
	os_dbg("v_args[1]=%lld", os_get_integer(v_args[1]));

	os_value ary2_ = os_new_array(2);
	os_mark(ary2_);
	os_value *ary2 = os_get_array(ary2_);
	ary2[0] = os_new_integer(11);
	ary2[1] = os_new_integer(22);
	os_dump_heap();
	os_value v_answer2 = v_func2(2, ary2);
	os_dbg("v_answer2=%lld", os_get_integer(v_answer2));
	os_dbg("ary2[0]=%lld", os_get_integer(ary2[0]));
	os_dbg("ary2[1]=%lld", os_get_integer(ary2[1]));

	os_dump_heap();
	os_dbg("before gc");
	os_sweep();
	os_dbg("after gc");
	os_dump_heap();

	WaitForSingleObject(hThread, INFINITE);

	os_dbg("before gc");
	os_sweep();
	os_dbg("after gc");
	os_dump_heap();
	os_dbg("after dump");

	//os_unmark(v_answer);
	os_dbg("before reset");
	//os_sweep();
	os_clear();
	os_dbg("after reset");
	os_dump_heap();
	os_dbg("after dump");

	return 0;
}
