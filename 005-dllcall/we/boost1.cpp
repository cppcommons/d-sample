#include <iostream>
#include <map>
#include <string>
#include <vector>
using namespace std;

#include <stdint.h>
#include "common.h"

#include <winstl/synch/thread_mutex.hpp>
#include <stlsoft/smartptr/shared_ptr.hpp>
//using namespace stlsoft::winstl_project;

#include <windows.h>
#define _MT
#include <process.h>

//stlsoft::winstl_project::thread_mutex g_thread_mutex;

struct os_thread_locker
{
	stlsoft::winstl_project::thread_mutex &m_mutex;
	explicit os_thread_locker(stlsoft::winstl_project::thread_mutex &mutex) : m_mutex(mutex)
	{
		m_mutex.lock();
	}
	virtual ~os_thread_locker()
	{
		m_mutex.unlock();
	}
};

::int64_t os_get_thread_id()
{
	static TLS_VARIABLE_DECL ::int64_t curr_thread_id = -1;
	static ::int64_t v_thread_id_max = 0;
	static stlsoft::winstl_project::thread_mutex v_mutex;
	{
		os_thread_locker locker(v_mutex);
		if (curr_thread_id == -1)
		{
			v_thread_id_max++;
			curr_thread_id = v_thread_id_max;
		}
	}
	return curr_thread_id;
}

struct os_object_entry_t
{
	::int64_t m_link_count;
	::int64_t m_value;
	explicit os_object_entry_t(): m_link_count(0), m_value(0)
	{
		cout << R"(\m_link_count\=)" << m_link_count << endl;
	}
};

os_object_entry_t X1;
os_object_entry_t X2;

typedef std::map<std::string, void *> func_map_t;
typedef stlsoft::shared_ptr<func_map_t> func_map_ptr_t;
typedef stlsoft::shared_ptr<func_map_t> func_map_ptr_t2;

struct cos_state
{
	//void *func_map;
	func_map_t *func_map;
	//func_map_ptr_t func_map;
	//func_map_t func_map;
	explicit cos_state() : func_map(nullptr)
	{
		cout << "cos_state()" << endl;
		func_map = new func_map_t;
	}
	/*virtual*/ ~cos_state()
	{
		cout << "~cos_state()" << endl;
		delete func_map;
	}
};

typedef stlsoft::shared_ptr<cos_state> cos_state_ptr;
//static cos_state_ptr g_state;
//static TLS_VARIABLE_DECL cos_state_ptr g_state;
//static TLS_VARIABLE_DECL cos_state g_state;
//static cos_state g_state;

struct MYHANDLE
{
};
void dummy(struct MYHANDLE *handle);

struct MYHANDLE_IMPL : public MYHANDLE
{
	std::string m_s;
	::int64_t m_int64;
};

::int64_t cos_add2(struct cos_context *context, int argc, ::int64_t args[])
{
	if (!context)
	{
		return 2; /* return -1; */
	}
	//return args[0];
	//return cos_return_int32(123);
	return 0;
}

struct C_Class1
{
	explicit C_Class1()
	{
		cout << "Constructor" << endl;
	}
	virtual ~C_Class1()
	{
		cout << "Destructor" << endl;
	}
	void Release()
	{
		delete this;
	}
};

/*
enum VariantType
{
	STRING,
	INT64
};*/
struct C_Variant
{
	enum VariantType
	{
		STRING,
		INT64
	};
	VariantType m_type;
	std::string m_s;
	::int64_t m_int64;
	C_Variant(const std::string &x)
	{
		//this.m_s = x;
		m_type = C_Variant::VariantType::STRING;
		m_s = x;
	}
	C_Variant(::int64_t x)
	{
		m_type = C_Variant::VariantType::INT64;
		//this.m_int64 = x;
		/*this.*/ m_int64 = x;
	}
	C_Variant &C_Variant::operator=(const std::string &x)
	{
		m_type = C_Variant::VariantType::STRING;
		m_s = x;
		return (*this);
	}
};

unsigned __stdcall sure1(void *p)
{
	puts((const char *)p);
	_endthreadex(0);
	return 0; //コンパイラの警告を殺す
}

DWORD WINAPI Thread(LPVOID *data)
{
	DWORD wintid = GetCurrentThreadId();
	cout << "wintid=" << wintid << endl;
	::int64_t tid1 = os_get_thread_id();
	cout << tid1 << endl;
	printf("%s start\n", (const char *)data);
	Sleep(1000);
	::int64_t tid2 = os_get_thread_id();
	cout << tid2 << endl;
	printf("%s end\n", (const char *)data);
	ExitThread(0);
	return 0;
}

int main()
{
	::int64_t tid = os_get_thread_id();
	cout << tid << endl;
	HANDLE hThread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)Thread, (LPVOID) "カウント数表示：", 0, NULL);

#if 0x0
	HANDLE handoru;

	handoru = (HANDLE)_beginthreadex(NULL, 0, sure1, "sure1です。", 0, NULL);
	//WaitForSingleObject(handoru, INFINITE); /* スレッドが終了するまで待つ。 */
	//CloseHandle(handoru);					/* ハンドルを閉じる */
#endif

#if 0x1
	typedef stlsoft::shared_ptr<string> StrPtr;
	StrPtr s = StrPtr(new string("pen"));
	vector<StrPtr> v1;
	// vectorに入れたり。
	v1.push_back(StrPtr(new string("this")));
	v1.push_back(StrPtr(new string("is")));
	v1.push_back(StrPtr(new string("a")));
	v1.push_back(s);

	cout << *s << endl;						 // sをpush_backで他にコピーしたからと言って使えなくなったりしない
	cout << "*s.get()=" << *s.get() << endl; // sをpush_backで他にコピーしたからと言って使えなくなったりしない
#endif
	typedef stlsoft::shared_ptr<C_Class1> ClsPtr;
	ClsPtr c1 = ClsPtr(new C_Class1());
	ClsPtr c2 = ClsPtr(new C_Class1());
	/*ClsPtr c3 =*/ClsPtr(new C_Class1());
	ClsPtr c4 = c1;

	cout << "c1.use_count()=" << c1.use_count() << endl;

	C_Variant var1 = 123;
	C_Variant var2 = "abc";
	var1 = "xyz";

	WaitForSingleObject(hThread, INFINITE);

	return 0;
} // ここで全てdeleteされる。
