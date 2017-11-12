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
	//os_new_std_string("test string テスト文字列");
	os_value s = os_new_string("test string テスト文字列");
	os_dbg("s=[%s]", os_get_string(s));
	os_new_string("string(1)", -1);
	os_new_string("STRING(2)", 3);
	//os_function_t v_func = cos_add2;
	//os_function_t v_func2 = C_Class1::cos_add2;
	os_function_t v_func2 = my_add2;

	//long long cnt1 = os_arg_count(v_func);
	long long cnt2 = os_arg_count(v_func2);
	//os_dbg("cnt1=%lld", cnt1);
	os_dbg("cnt2=%lld", cnt2);

	HANDLE hThread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)Thread, (LPVOID) "カウント数表示：", 0, NULL);

	std::vector<os_value> v_args;
	v_args.push_back(os_new_integer(111));
	v_args.push_back(os_new_integer(222));
	os_dump_heap();
	//os_oid_t v_answer = cos_add2(v_args.size(), &v_args[0]);
	os_value v_answer = v_func2(v_args.size(), &v_args[0]);
	long long v_answer32 = os_get_integer(v_answer);
	os_link(v_answer);
	os_dbg("answer=%d", v_answer32);
	os_dbg("v_args[0]=%lld", os_get_integer(v_args[0]));
	os_dbg("v_args[1]=%lld", os_get_integer(v_args[1]));

	os_dump_heap();
	os_dbg("before gc");
	os_cleanup();
	os_dbg("after gc");
	os_dump_heap();

	WaitForSingleObject(hThread, INFINITE);

	os_dbg("before gc");
	os_cleanup();
	os_dbg("after gc");
	os_dump_heap();
	os_dbg("after dump");

	os_unlink(v_answer);
	os_dbg("before gc");
	os_cleanup();
	os_dbg("after gc");
	os_dump_heap();
	os_dbg("after dump");

	return 0;
}
