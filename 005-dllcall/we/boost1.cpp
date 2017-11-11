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

os_oid_t os_new_int64(::int64_t value)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_oid_t v_oid = os_get_next_oid();
		os_object_entry_t v_entry;
		v_entry.m_value = value;
		g_os_object_map[v_oid] = v_entry;
		return v_oid;
	}
}

void dummy()
{
#if 0x1
	for (int i = 0; i < 5; i++)
	{
		/*os_oid_t*/ os_new_int64(i);
		//os_oid_t key = os_get_next_oid();
		//os_object_entry_t myentry((i + 1) * 10);
		//g_os_object_map[key] = myentry;
	}
#endif
	os_object_map_t::iterator map_ite;
	for (map_ite = g_os_object_map.begin(); map_ite != g_os_object_map.end(); map_ite++)
	{
		os_dbg("key = %lld : data = [%s]", map_ite->first, map_ite->second.c_str());
		//os_dbg("key = %lld : data = [0x%08x]", map_ite->first, map_ite->second.c_str());
		os_dbg("m_value=%lld", map_ite->second.m_value);
		os_dbg("c_str()=%s", map_ite->second.c_str());
	}
}

typedef std::map<std::string, void *> func_map_t;
typedef stlsoft::shared_ptr<func_map_t> func_map_ptr_t;
typedef stlsoft::shared_ptr<func_map_t> func_map_ptr_t2;

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
	os_register_curr_thread();
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
	os_thread_id &tid0 = os_register_curr_thread();
	os_dbg("tid0=%s", tid0.c_str());
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

	dummy();

	//os_thread_map_t	g_os_thread_map;
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

	return 0;
} // ここで全てdeleteされる。
