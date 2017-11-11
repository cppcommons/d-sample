#include <iomanip>
#include <iostream>
#include <map>
#include <string>
#include <vector>
#include <sstream>
using namespace std;

#include <stdint.h>
//#include "common.h"

#include <winstl/synch/thread_mutex.hpp>
//#include <stlsoft/smartptr/shared_ptr.hpp>

#include <windows.h>
#define _MT
#include <process.h>

#include <tlhelp32.h> // CreateToolhelp32Snapshot()

#ifdef __GNUC__
#define THREAD_LOCAL __thread
#else
#define THREAD_LOCAL __declspec(thread)
#endif

//#define OS_UINT32_MAX 4294967295
//#define OS_INT32_MIN (-2147483647L - 1)

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
	static THREAD_LOCAL ::int64_t curr_thread_no = -1;
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

//os_oid_t g_os_direct_value_range = 0x7fffffff;
os_oid_t g_os_direct_value_range = 0xffffffff;
os_oid_t g_os_direct_value_min = (-g_os_direct_value_range - 1);
os_oid_t g_min_oid = g_os_direct_value_min;

os_oid_t os_get_next_oid()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		//g_max_oid++;
		//return g_max_oid;
		g_min_oid--;
		return g_min_oid;
	}
}

struct os_object_entry_t : public os_struct
{
	enum value_type_t
	{
		INTEGER,
		REAL,
		STRING,
		OBJECT,
		NIL
	};
	os_thread_id m_thread_id;
	::int64_t m_link_count;
	//::int64_t m_value;
	value_type_t m_type;
	union {
		::int64_t m_integer;
		double m_real;
		void *m_this;
	} m_simple;
	std::string m_string;
	std::vector<os_oid_t> m_array;
	void _init(os_thread_id &thread_id, ::int64_t link_count, ::int64_t value)
	{
		m_thread_id = thread_id;
		m_link_count = link_count;
		//m_value = value;
		m_type = value_type_t::INTEGER;
		m_simple.m_integer = value;
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
				 << m_simple.m_integer
				 << " }";
		m_debug_output_string = v_stream.str();
		return m_debug_output_string.c_str();
	}
};

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

void os_oid_unlink(os_oid_t oid)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_object_map_t::iterator it;
		if (g_os_object_map.count(oid) == 0)
			return;
		g_os_object_map[oid].m_link_count--;
	}
}

os_oid_t os_new_int64(::int64_t value, bool prefer_direct = false)
{
	if (prefer_direct && value >= g_os_direct_value_min)
	{
		return (os_oid_t)value;
	}
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_register_curr_thread();
		os_oid_t v_oid = os_get_next_oid();
		os_object_entry_t v_entry;
		v_entry.m_type = os_object_entry_t::value_type_t::INTEGER;
		v_entry.m_simple.m_integer = value;
		g_os_object_map[v_oid] = v_entry;
		return v_oid;
	}
}

os_object_entry_t *os_find_entry(os_oid_t oid)
{
	if (oid >= g_os_direct_value_min)
	{
		return nullptr;
	}
	{
		os_thread_locker locker(g_os_thread_mutex);
		if (g_os_object_map.count(oid) == 0)
		{
			return nullptr;
		}
		return &g_os_object_map[oid];
	}
}

::int32_t os_get_int32(os_oid_t oid)
{
	if (oid >= g_os_direct_value_min)
	{
		return (::int32_t)oid;
	}
	os_object_entry_t *v_entry = os_find_entry(oid);
	if (!v_entry) return 0;
	return (::int32_t)(*v_entry).m_simple.m_integer;
}

void os_set_int32(os_oid_t oid, ::int32_t value)
{
	os_object_entry_t *v_entry = os_find_entry(oid);
	if (!v_entry) return;
	(*v_entry).m_type = os_object_entry_t::value_type_t::INTEGER;
	(*v_entry).m_simple.m_integer = value;
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

typedef os_oid_t (*os_function_t)(int argc, os_oid_t args[]);

os_oid_t cos_add2(int argc, os_oid_t args[])
{
	if (argc < 0)
		return 2;
	::int32_t a = os_get_int32(args[1]);
	::int32_t b = os_get_int32(args[2]);
	return os_new_int64(a + b, true);
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
	static os_oid_t cos_add2(int argc, os_oid_t args[])
	{
		if (argc < 0)
			return 2;
		::int32_t a = os_get_int32(args[1]);
		::int32_t b = os_get_int32(args[2]);
		os_set_int32(args[1], a * 10);
		os_set_int32(args[2], b * 10);
		return os_new_int64(a + b, true);
	}
};

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
	os_function_t v_func = cos_add2;
	os_function_t v_func2 = C_Class1::cos_add2;

	os_thread_id tid1 = os_get_thread_id();
	os_dbg("tid1=%s", tid1.c_str());
	HANDLE hThread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)Thread, (LPVOID) "カウント数表示：", 0, NULL);

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
	//v_args[2] = os_new_int64(222);
	//v_args[2] = 333;
	v_args[2] = -12;
	//os_oid_t v_answer = cos_add2(2, &v_args[0]);
	os_oid_t v_answer = v_func2(2, &v_args[0]);
	::int32_t v_answer32 = os_get_int32(v_answer);
	os_oid_link(v_answer);
	os_dbg("answer=%d", v_answer32);
	os_dbg("v_args[1]=%d", os_get_int32(v_args[1]));
	os_dbg("v_args[2]=%d", os_get_int32(v_args[2]));

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

	os_oid_unlink(v_answer);
	os_dbg("before gc");
	os_gc();
	os_dbg("after gc");
	os_dump_object_heap();
	os_dbg("after dump");

	return 0;
}
