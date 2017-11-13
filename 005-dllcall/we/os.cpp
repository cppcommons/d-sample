#include "os.h"

#ifdef __DMC__
#define _WIN32_WINNT 0x403
#endif /* __DMC__ */
#include <windows.h>
#include <tlhelp32.h> // CreateToolhelp32Snapshot()
#include <iomanip>
#include <iostream>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <sstream>
using namespace std;

//#include <winstl/synch/thread_mutex.hpp>
//#include <stlsoft/smartptr/shared_ptr.hpp>

#ifdef __GNUC__
#define THREAD_LOCAL __thread
#else
#define THREAD_LOCAL __declspec(thread)
#endif

#include "os-def.h"

//static stlsoft::winstl_project::thread_mutex g_os_thread_mutex;
static thread_mutex g_os_thread_mutex;

static inline os_sid_t os_next_sid(
	thread_mutex &mutex, os_sid_t &max_counter)
{
	os_sid_t result;
	mutex.lock();
	max_counter++;
	result = max_counter;
	mutex.unlock();
	return result;
}

struct os_thread_info
{
	static os_sid_t s_sid_max;
	DWORD m_dword;
	os_sid_t m_sid;
	explicit os_thread_info(DWORD dword)
	{
		m_dword = dword;
		m_sid = os_next_sid(g_os_thread_mutex, s_sid_max);
	}
	std::string m_display;
	const char *c_str()
	{
		if (m_display.empty())
		{
			std::stringstream v_stream;
			v_stream << "[" << m_sid
					 << ":0x"
					 << std::setw(8)
					 << std::setfill('0')
					 << std::hex
					 //<< std::uppercase
					 << m_dword
					 << "]";
			m_display = v_stream.str();
		}
		return m_display.c_str();
	}
};
os_sid_t os_thread_info::s_sid_max = 0;

struct os_struct
{
	std::string m_debug_output_string;
};

struct os_thread_id : public os_struct
{
	DWORD dword;
	long long no;
	const char *c_str()
	{
		std::stringstream v_stream;
		v_stream << "[" << no
				 << ":0x"
				 << std::setw(8)
				 << std::setfill('0')
				 << std::hex
				 //<< std::uppercase
				 << dword
				 << "]";
		m_debug_output_string = v_stream.str();
		return m_debug_output_string.c_str();
	}
};

static long long os_get_thread_no()
{
	static THREAD_LOCAL long long curr_thread_no2 = -1;
	static long long v_thread_id_max2 = 0;
	//static stlsoft::winstl_project::thread_mutex v_mutex2;
	static thread_mutex v_mutex2;
	os_dbg("os_get_thread_no(1)");
	os_dbg("os_get_thread_no(2)");
	if (curr_thread_no2 > 0)
		return curr_thread_no2;
	os_dbg("os_get_thread_no(3)");
	{
		//os_thread_locker locker(v_mutex2);
		//os_thread_locker locker(g_os_thread_mutex);
		os_dbg("os_get_thread_no(4)");
		v_mutex2.lock();
		if (curr_thread_no2 == -1)
		{
			os_dbg("os_get_thread_no(5)");
			v_thread_id_max2++;
			curr_thread_no2 = v_thread_id_max2;
		}
		v_mutex2.unlock();
		os_dbg("os_get_thread_no(6)");
		return curr_thread_no2;
	}
}

static os_thread_id os_get_thread_id()
{
#if 0x0
	static THREAD_LOCAL long long curr_thread_no = -1;
	static long long v_thread_id_max = 0;
	static stlsoft::winstl_project::thread_mutex v_mutex;
	{
		os_thread_locker locker(v_mutex);
		if (curr_thread_no == -1)
		{
			v_thread_id_max++;
			curr_thread_no = v_thread_id_max;
		}
	}
#endif
	static THREAD_LOCAL bool v_initilized = false;
	//static THREAD_LOCAL os_thread_id v_thread_id;
	static THREAD_LOCAL long long v_thread_no;
	static THREAD_LOCAL DWORD v_thread_dword;
	if (!v_initilized)
	{
		v_thread_no = os_get_thread_no();
		v_thread_dword = ::GetCurrentThreadId();
	}
	os_thread_id result;
	result.no = v_thread_no;
	result.dword = v_thread_dword;
	return result;
#if 0x0
	os_dbg("os_get_thread_id(1)");
	os_thread_id result;
	//result.no = curr_thread_no; //os_get_thread_no();
	result.no = os_get_thread_no();
	//os_get_thread_no();
	os_dbg("os_get_thread_id(2)");
	result.dword = ::GetCurrentThreadId();
	os_dbg("os_get_thread_id(3)");
	return result;
#endif
}

static std::set<DWORD> os_get_thread_dword_list()
{
	std::set<DWORD> result;
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
		goto label_exit;
	}
	do
	{
		if (v_entry.th32OwnerProcessID == v_proc_id)
			result.insert(v_entry.th32ThreadID);
	} while (::Thread32Next(h_snapshot, &v_entry));
label_exit:
	::CloseHandle(h_snapshot);
	return result;
}

static os_sid_t os_get_next_oid()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		static os_sid_t g_last_oid = 100000;
		g_last_oid++;
		return g_last_oid;
	}
}

struct os_variant_t : public os_struct
{
	os_sid_t m_oid;
	os_thread_id m_thread_id;
	long long m_link_count;
	os_data *m_value;
	explicit os_variant_t(os_sid_t oid)
	{
		m_oid = oid;
		m_thread_id = os_get_thread_id();
		m_link_count = 0;
		m_value = nullptr;
	}
	void set_value(os_data *value)
	{
		if (m_value)
			m_value->release();
		m_value = value;
	}
	virtual ~os_variant_t()
	{
		if (m_value)
			m_value->release();
	}
	const char *c_str()
	{
		std::string v_thread_id = m_thread_id.c_str();
		std::stringstream v_stream;
		v_stream << "os_variant_t { " << v_thread_id
				 << " ";
		m_value->to_ss(v_stream);
		v_stream << " }";
		m_debug_output_string = v_stream.str();
		return m_debug_output_string.c_str();
	}
};

typedef std::set<os_variant_t *> os_value_set_t;
static os_value_set_t g_os_value_set;

extern bool os_mark(os_value entry)
{
	if (!entry)
		return false;
	{
		os_thread_locker locker(g_os_thread_mutex);
		if (entry->m_value->type() == OS_ARRAY)
			return false;
		entry->m_link_count++;
		return true;
	}
}

extern bool os_unmark(os_value entry)
{
	if (!entry)
		return false;
	{
		os_thread_locker locker(g_os_thread_mutex);
		if (entry->m_value->type() == OS_ARRAY)
			return false;
		entry->m_link_count--;
		return true;
	}
}

static inline os_value os_new_value(os_data *data)
{
	os_dbg("os_new_value() start!");
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_dbg("os_new_value(1)");
		os_sid_t v_oid = os_get_next_oid();
		os_dbg("os_new_value(1.1)");
		os_value entry = new os_variant_t(v_oid);
		os_dbg("os_new_value(2)");
		entry->set_value(data);
		g_os_value_set.insert(entry);
		os_dbg("os_new_value(3)");
		return entry;
	}
}

extern os_value os_new_array(long long len)
{
	os_dbg("os_new_array() start!");
	return os_new_value(new os_array(len));
}

extern os_value *os_get_array(os_value value)
{
	if (!value)
		return nullptr;
	return value->m_value->get_array();
}

extern os_value os_new_integer(long long data)
{
	return os_new_value(new os_integer(data));
}

extern long long os_get_integer(os_value value)
{
	if (!value)
		return 0;
	return value->m_value->get_integer();
}

extern os_value os_new_handle(void *data)
{
	return os_new_value(new os_handle(data));
}

extern void *os_get_handle(os_value value)
{
	if (!value)
		return 0;
	return value->m_value->get_handle();
}

extern os_value os_new_string(const char *data, long long len)
{
	return os_new_value(new os_string(data, len));
}

extern const char *os_get_string(os_value value)
{
	if (!value)
		return 0;
	return value->m_value->get_string();
}

extern void os_dump_heap()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_value_set_t::iterator it;
		for (it = g_os_value_set.begin(); it != g_os_value_set.end(); it++)
		{
			os_value v_entry = *it;
			os_sid_t v_oid = v_entry->m_oid;
			os_dbg("[DUMP] oid = %lld : data = %s", v_oid, v_entry->c_str());
		}
	}
}

static void os_cleanup(bool reset)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_thread_id v_thread_id = os_get_thread_id();
		//long long v_thread_no = os_get_thread_no();
		std::set<DWORD> v_thread_list = os_get_thread_dword_list();
		std::vector<os_variant_t *> v_removed;
		os_value_set_t::iterator it;
		for (it = g_os_value_set.begin(); it != g_os_value_set.end(); it++)
		{
			os_variant_t *v_entry = *it;
			os_sid_t v_oid = v_entry->m_oid;
			if (reset && v_entry->m_thread_id.no == v_thread_id.no)
			{
				v_entry->m_link_count = 0;
			}
			if (v_entry->m_thread_id.no == v_thread_id.no)
			{
				if (v_entry->m_link_count <= 0)
					v_removed.push_back(v_entry);
			}
			else if (v_thread_list.count(v_entry->m_thread_id.dword) == 0)
			{
				v_removed.push_back(v_entry);
			}
		}
		for (size_t i = 0; i < v_removed.size(); i++)
		{
			delete v_removed[i];
			g_os_value_set.erase(v_removed[i]);
		}
	}
}

extern void os_sweep()
{
	os_cleanup(false);
}

extern void os_clear()
{
	os_cleanup(true);
}

extern long long os_arg_count(os_function_t fn)
{
	os_value v_count = fn(-1, nullptr);
	return os_get_integer(v_count);
}

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

static thread_mutex v_print_mutex;
extern int os_printf(const char *format, ...)
{
	{
		os_thread_locker locker(v_print_mutex);
		va_list args;
		va_start(args, format);
		int len = os_write_consoleA(GetStdHandle(STD_OUTPUT_HANDLE), format, args);
		va_end(args);
		return len;
	}
}

extern int os_dbg(const char *format, ...)
{
	//static stlsoft::winstl_project::thread_mutex v_mutex;
	{
		os_thread_locker locker(v_print_mutex);
		char v_buffer[1024 + 1];
		v_buffer[1024] = 0;
		wsprintfA((LPSTR)v_buffer, "[DEBUG] %s\n", format);
		va_list args;
		va_start(args, format);
		int len = os_write_consoleA(GetStdHandle(STD_OUTPUT_HANDLE), v_buffer, args);
		va_end(args);
		return len;
	}
}
