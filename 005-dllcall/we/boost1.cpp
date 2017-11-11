#include <iomanip>
#include <iostream>
#include <map>
#include <string>
#include <vector>
#include <sstream>
using namespace std;

#include <stdint.h>
#include "common.h"

#include <winstl/synch/thread_mutex.hpp>
#include <stlsoft/smartptr/shared_ptr.hpp>

#include <windows.h>
#define _MT
#include <process.h>

#include <tlhelp32.h> // CreateToolhelp32Snapshot()

stlsoft::winstl_project::thread_mutex g_os_thread_mutex;

struct os_struct
{
	std::string m_debug_output_string;
};

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

static int os_write_consoleA(HANDLE hconsole, const char *format, va_list args)
{
	const int BUFF_LEN = 10240;
	static char v_buffer[BUFF_LEN + 1];
	v_buffer[BUFF_LEN] = 0;
	//int len = wvsprintfA((LPSTR)v_buffer, format, args); // Win32 API
	int len = vsnprintf(v_buffer, BUFF_LEN, format, args); // Win32 API

	for (int i = 0; i < len; i++)
	{
		if (v_buffer[i] == 0)
		{
			v_buffer[i] = '@';
		}
	}
	DWORD dwWriteByte;
	WriteConsoleA(hconsole, v_buffer, len, &dwWriteByte, NULL);
	OutputDebugStringA((LPCSTR)v_buffer);
	return len;
}

int os_printf(const char *format, ...)
{
	static stlsoft::winstl_project::thread_mutex v_mutex;
	{
		os_thread_locker locker(v_mutex);
		va_list args;
		va_start(args, format);
		int len = os_write_consoleA(GetStdHandle(STD_OUTPUT_HANDLE), format, args);
		va_end(args);
		return len;
	}
}

int os_dbg(const char *format, ...)
{
	static stlsoft::winstl_project::thread_mutex v_mutex;
	{
		os_thread_locker locker(v_mutex);
		char v_buffer[1024 + 1];
		v_buffer[1024] = 0;
		wsprintfA((LPSTR)v_buffer, "[DEBUG] %s\n", format); // Win32 API
		va_list args;
		va_start(args, format);
		int len = os_write_consoleA(GetStdHandle(STD_OUTPUT_HANDLE), v_buffer, args);
		va_end(args);
		return len;
	}
}

struct os_thread_id : public os_struct
{
	DWORD id;
	::int64_t no;
	const char *c_str()
	{
		std::stringstream v_stream;
		v_stream << "[" << no
				 << ":0x"
				 << std::setw(8)
				 << std::setfill('0')
				 << std::hex
				 //<< std::uppercase
				 << id
				 << "]";
		m_debug_output_string = v_stream.str();
		return m_debug_output_string.c_str();
	}
};

typedef std::map<DWORD, os_thread_id> os_thread_map_t;
os_thread_map_t g_os_thread_map;

os_thread_id os_get_thread_id()
{
	static TLS_VARIABLE_DECL ::int64_t curr_thread_no = -1;
	static ::int64_t v_thread_id_max = 0;
	static stlsoft::winstl_project::thread_mutex v_mutex;
	{
		os_thread_locker locker(v_mutex);
		if (curr_thread_no == -1)
		{
			v_thread_id_max++;
			curr_thread_no = v_thread_id_max;
		}
	}
	os_thread_id result;
	result.id = ::GetCurrentThreadId();
	result.no = curr_thread_no;
	return result;
}

os_thread_id &os_register_curr_thread()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_thread_id v_id = os_get_thread_id();
		if (g_os_thread_map.count(v_id.id) == 0)
		{
			g_os_thread_map[v_id.id] = v_id;
		}
		os_thread_id &v_old_id = g_os_thread_map[v_id.id];
		v_old_id.no = v_id.no;
		return v_old_id;
	}
}

std::vector<DWORD> os_get_thread_dword_list()
{
	std::vector<DWORD> result;
	DWORD v_proc_id = ::GetCurrentProcessId();
	HANDLE h_snapshot = ::CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
	if (h_snapshot == INVALID_HANDLE_VALUE)
	{
		return result;
	}
	THREADENTRY32 v_entry;
	v_entry.dwSize = sizeof(THREADENTRY32);
	if (!::Thread32First(h_snapshot, &v_entry))
	{
		goto Exit;
	}
	do
	{
		if (v_entry.th32OwnerProcessID == v_proc_id)
			result.push_back(v_entry.th32ThreadID);
	} while (::Thread32Next(h_snapshot, &v_entry));
Exit:
	::CloseHandle(h_snapshot);
	return result;
}

bool os_is_thread_alive(DWORD thread_dword)
{
	std::vector<DWORD> v_list = os_get_thread_dword_list();
	if (std::count(v_list.begin(), v_list.end(), thread_dword) == 0)
		return false;
	return true;
}

typedef ::int64_t os_oid_t;
//os_oid_t g_max_oid = 0;
os_oid_t g_max_oid = 100000;

os_oid_t os_get_next_oid()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		g_max_oid++;
		return g_max_oid;
	}
}

struct os_object_entry_t : public os_struct
{
	os_thread_id m_thread_id;
	::int64_t m_link_count;
	::int64_t m_value;
	void _init(os_thread_id &thread_id, ::int64_t link_count, ::int64_t value)
	{
		m_thread_id = thread_id;
		m_link_count = link_count;
		m_value = value;
	}
	explicit os_object_entry_t() //: m_link_count(0), m_value(0)
	{
		_init(os_get_thread_id(), 0, 0);
	}
	explicit os_object_entry_t(::int64_t value)
	{
		_init(os_get_thread_id(), 0, value);
		os_dbg("%s", c_str());
	}
	const char *c_str()
	{
		std::string v_thread_id = m_thread_id.c_str();
		std::stringstream v_stream;
		v_stream << "os_object_entry_t { " << v_thread_id
				 << " "
				 << m_value
				 << " }";
		m_debug_output_string = v_stream.str();
		return m_debug_output_string.c_str();
	}
};

//os_object_entry_t X1(111);
//os_object_entry_t X2(222);

typedef std::map<os_oid_t, os_object_entry_t> os_object_map_t;
os_object_map_t g_os_object_map;

os_oid_t os_oid_link(os_oid_t oid)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_object_map_t::iterator it;
		if (g_os_object_map.count(oid) == 0)
			return 0;
		g_os_object_map[oid].m_link_count++;
		return oid;
	}
}

os_oid_t os_new_int64(::int64_t value)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_register_curr_thread();
		os_oid_t v_oid = os_get_next_oid();
		os_object_entry_t v_entry;
		v_entry.m_value = value;
		g_os_object_map[v_oid] = v_entry;
		return v_oid;
	}
}

::int32_t os_get_int32(os_oid_t oid)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		if (g_os_object_map.count(oid) == 0)
		{
			return 0;
		}
		::int32_t result = (::int32_t)g_os_object_map[oid].m_value;
		return result;
	}
}

void os_dump_object_heap()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_object_map_t::iterator it;
		for (it = g_os_object_map.begin(); it != g_os_object_map.end(); it++)
		{
			os_oid_t v_oid = it->first;
			os_object_entry_t &v_entry = it->second;
			os_dbg("[DUMP] oid = %lld : data = %s", v_oid, v_entry.c_str());
		}
	}
}

void os_gc()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_thread_id v_thread_id = os_get_thread_id();
		std::vector<DWORD> v_list = os_get_thread_dword_list();
		std::map<DWORD, ::int64_t> v_map;
		for (size_t i = 0; i < v_list.size(); i++)
		{
			v_map[v_list[i]] = 0;
		}
		os_object_map_t::iterator it;
		std::vector<os_oid_t> v_removed;
		for (it = g_os_object_map.begin(); it != g_os_object_map.end(); it++)
		{
			os_oid_t v_oid = it->first;
			os_object_entry_t &v_entry = it->second;
			//os_dbg("[SCAN] oid = %lld : data = %s", v_oid, v_entry.c_str());
			if (v_map.count(v_entry.m_thread_id.id) == 0)
			{
				//os_dbg("[GC-1] oid = %lld : data = %s", v_oid, v_entry.c_str());
				v_removed.push_back(v_oid);
			}
			else if (v_entry.m_link_count > 0)
			{
				continue;
			}
			else if (v_entry.m_thread_id.no == v_thread_id.no)
			{
				//os_dbg("[GC-2] oid = %lld : data = %s", v_oid, v_entry.c_str());
				v_removed.push_back(v_oid);
			}
		}
		for (size_t i = 0; i < v_removed.size(); i++)
		{
			g_os_object_map.erase(v_removed[i]);
		}
	}
}

#if 0x0
typedef std::map<std::string, void *> func_map_t;
typedef stlsoft::shared_ptr<func_map_t> func_map_ptr_t;
typedef stlsoft::shared_ptr<func_map_t> func_map_ptr_t2;
#endif

enum OS_VALUE_TYPE
{
	OS_TYPE_INT32 = -100001,
	OS_TYPE_INT64 = -100002
};

enum OS_ARGS_LENGTH_TYPE
{
	OS_ARGS_END = -200001,
	OS_ARGS_VARIABLE = -200002
};

enum OS_STATUS
{
	OS_STASUS_OK = 0,
	OS_STASUS_NG = -1
};

os_oid_t cos_add2(int argc, os_oid_t args[])
{
	if (argc < 0)
	{
		switch (argc)
		{
		case -1:
			return OS_TYPE_INT32; // return OS_TYPE_ANY;
		case -2:
			return OS_TYPE_INT32;
		default:
			return OS_ARGS_END; // return OS_ARGS_VARIABLE;
		}
	}
	::int32_t a = os_get_int32(args[1]);
	::int32_t b = os_get_int32(args[2]);
	args[0] = os_new_int64(a + b);
	return 0; /* return Exception Object(plus) or Status(minus) when error. */
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

DWORD WINAPI Thread(LPVOID *data)
{
	//os_register_curr_thread();
	os_new_int64(1234);
	os_thread_id tid1 = os_get_thread_id();
	os_dbg("tid1=%s", tid1.c_str());
	os_dbg("%s start", (const char *)data);
	Sleep(1000);
	os_thread_id tid2 = os_get_thread_id();
	os_dbg("tid2=%s", tid2.c_str());
	os_dbg("%s end", (const char *)data);
	ExitThread(0);
	return 0;
}

int main()
{
	//os_thread_id &tid0 = os_register_curr_thread();
	//os_dbg("tid0=%s", tid0.c_str());
	os_thread_id tid1 = os_get_thread_id();
	os_dbg("tid1=%s", tid1.c_str());
	HANDLE hThread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)Thread, (LPVOID) "カウント数表示：", 0, NULL);

#if 0x1
	typedef stlsoft::shared_ptr<string> StrPtr;
	StrPtr s = StrPtr(new string("pen"));
	vector<StrPtr> v1;
	// vectorに入れたり。
	v1.push_back(StrPtr(new string("this")));
	v1.push_back(StrPtr(new string("is")));
	v1.push_back(StrPtr(new string("a")));
	v1.push_back(s);

	os_dbg("%s", (*s).c_str());
	os_dbg("%s", (*s.get()).c_str());
#endif
	typedef stlsoft::shared_ptr<C_Class1> ClsPtr;
	ClsPtr c1 = ClsPtr(new C_Class1());
	ClsPtr c2 = ClsPtr(new C_Class1());
	/*ClsPtr c3 =*/ClsPtr(new C_Class1());
	ClsPtr c4 = c1;

	os_dbg("c1.use_count()=%d", c1.use_count());

	C_Variant var1 = 123;
	C_Variant var2 = "abc";
	var1 = "xyz";

	{
		os_thread_map_t::iterator it;
		for (it = g_os_thread_map.begin(); it != g_os_thread_map.end(); it++)
		{
			DWORD v_thread_dword = it->first;
			os_thread_id &v_thread_id = it->second;
			os_dbg("v_thread_dword=0x%08x v_thread_id.c_str()=%s ALIVE=%d",
				   v_thread_dword, v_thread_id.c_str(), os_is_thread_alive(v_thread_dword));
		}
	}

	std::vector<os_oid_t> v_args(3);
	v_args[1] = os_new_int64(111);
	v_args[2] = os_new_int64(222);
	os_oid_t v_status = cos_add2(2, &v_args[0]);
	::int32_t answer = os_get_int32(v_args[0]);
	os_oid_link(v_args[0]);
	os_dbg("answer=%d", answer);

	os_dump_object_heap();
	os_dbg("before gc");
	os_gc();
	os_dbg("after gc");
	os_dump_object_heap();

	WaitForSingleObject(hThread, INFINITE);
	{
		os_thread_map_t::iterator it;
		for (it = g_os_thread_map.begin(); it != g_os_thread_map.end(); it++)
		{
			DWORD v_thread_dword = it->first;
			os_thread_id &v_thread_id = it->second;
			os_dbg("v_thread_dword=0x%08x v_thread_id.c_str()=%s ALIVE=%d",
				   v_thread_dword, v_thread_id.c_str(), os_is_thread_alive(v_thread_dword));
		}
	}
	os_dbg("before gc");
	os_gc();
	os_dbg("after gc");
	os_dump_object_heap();
	os_dbg("after dump");

	return 0;
}
