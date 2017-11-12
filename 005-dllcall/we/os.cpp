#include "os.h"
#include <iomanip>
#include <iostream>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <sstream>
using namespace std;

#include <winstl/synch/thread_mutex.hpp>
//#include <stlsoft/smartptr/shared_ptr.hpp>

#include <windows.h>
//#define _MT
//#include <process.h>
#include <tlhelp32.h> // CreateToolhelp32Snapshot()

#ifdef __GNUC__
#define THREAD_LOCAL __thread
#else
#define THREAD_LOCAL __declspec(thread)
#endif

typedef os_integer_t os_oid_t;

struct os_data
{
	virtual void release() = 0;
	virtual os_type_t type() = 0;
	virtual void to_ss(std::stringstream &stream) = 0;
	virtual os_integer_t get_integer() = 0;
	virtual const char *get_string() = 0;
	virtual os_integer_t get_length() = 0;
};

struct os_integer : public os_data
{
	os_integer_t m_value;
	explicit os_integer(os_integer_t value)
	{
		m_value = value;
	}
	virtual void release()
	{
		os_dbg("os_integer::release(): %lld", m_value);
		delete this;
	}
	virtual os_type_t type()
	{
		return OS_INTEGER;
	}
	virtual void to_ss(std::stringstream &stream)
	{
		stream << m_value;
	}
	virtual os_integer_t get_integer()
	{
		return m_value;
	}
	virtual const char *get_string()
	{
		return "";
	}
	virtual os_integer_t get_length()
	{
		return 0;
	}
};

struct os_string : public os_data
{
	std::string m_value;
	explicit os_string(const std::string &value)
	{
		m_value = value;
	}
	explicit os_string(const char *value, os_integer_t len)
	{
		if (len < 0)
			m_value = std::string(value);
		else
			m_value = std::string(value, len);
	}
	virtual void release()
	{
		os_dbg("os_string::release(): %s", m_value.c_str());
		delete this;
	}
	virtual os_type_t type()
	{
		return OS_STRING;
	}
	virtual void to_ss(std::stringstream &stream)
	{
		stream << "\"" << m_value << "\"";
	}
	virtual os_integer_t get_integer()
	{
		return 0;
	}
	virtual const char *get_string()
	{
		return m_value.c_str();
	}
	virtual os_integer_t get_length()
	{
		return m_value.size();
	}
};

static stlsoft::winstl_project::thread_mutex g_os_thread_mutex;

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

extern int os_printf(const char *format, ...)
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

extern int os_dbg(const char *format, ...)
{
	static stlsoft::winstl_project::thread_mutex v_mutex;
	{
		os_thread_locker locker(v_mutex);
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

struct os_thread_id : public os_struct
{
	DWORD id;
	os_integer_t no;
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

#if 0x0
typedef std::map<DWORD, os_thread_id> os_thread_map_t;
os_thread_map_t g_os_thread_map;
#endif

static os_thread_id os_get_thread_id()
{
	static THREAD_LOCAL os_integer_t curr_thread_no = -1;
	static os_integer_t v_thread_id_max = 0;
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

#if 0x0
static os_thread_id &os_register_curr_thread()
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
#endif

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

#if 0x0
static bool os_is_thread_alive(DWORD thread_dword)
{
	std::set<DWORD> v_list = os_get_thread_dword_list();
	if (v_list.count(thread_dword) == 0)
		return false;
	return true;
}
#endif

static os_oid_t os_get_next_oid()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		static os_oid_t g_last_oid = 100000;
		g_last_oid++;
		return g_last_oid;
	}
}

struct os_variant_t : public os_struct
{
	os_oid_t m_oid;
	os_thread_id m_thread_id;
	os_integer_t m_link_count;
	os_data *m_value;
	explicit os_variant_t(os_oid_t oid)
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

extern void os_oid_link(os_value entry)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		entry->m_link_count++;
	}
}

extern void os_oid_unlink(os_value entry)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		entry->m_link_count--;
	}
}

static inline os_value os_new_value(os_data *data)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
#if 0x0
		os_register_curr_thread();
#endif
		os_oid_t v_oid = os_get_next_oid();
		os_value entry = new os_variant_t(v_oid);
		entry->set_value(data);
		g_os_value_set.insert(entry);
		return entry;
	}
}

extern os_value os_new_integer(os_integer_t data)
{
	return os_new_value(new os_integer(data));
}

#if 0x0
static os_value os_new_std_string(const std::string &data)
{
	return os_new_value(new os_string(data));
}
#endif

extern os_value os_new_string(const char *data, os_integer_t len)
{
	return os_new_value(new os_string(data, len));
}

extern os_integer_t os_get_integer(os_value value)
{
	if (!value)
		return 0;
	return value->m_value->get_integer();
}

extern void os_set_integer(os_value value, os_integer_t data)
{
	if (!value)
		return;
	value->set_value(new os_integer(data));
}

extern void os_dump_object_heap()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_value_set_t::iterator it;
		for (it = g_os_value_set.begin(); it != g_os_value_set.end(); it++)
		{
			os_value v_entry = *it;
			os_oid_t v_oid = v_entry->m_oid;
			os_dbg("[DUMP] oid = %lld : data = %s", v_oid, v_entry->c_str());
		}
	}
}

extern void os_cleanup()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_thread_id v_thread_id = os_get_thread_id();
		std::set<DWORD> v_thread_list = os_get_thread_dword_list();
		std::vector<os_variant_t *> v_removed;
		os_value_set_t::iterator it;
		for (it = g_os_value_set.begin(); it != g_os_value_set.end(); it++)
		{
			os_variant_t *v_entry = *it;
			os_oid_t v_oid = v_entry->m_oid;
			//os_dbg("[SCAN] oid = %lld : data = %s", v_oid, v_entry.c_str());
			if (v_thread_list.count(v_entry->m_thread_id.id) == 0)
			{
				//os_dbg("[GC-1] oid = %lld : data = %s", v_oid, v_entry.c_str());
				v_removed.push_back(v_entry);
			}
			else if (v_entry->m_link_count > 0)
			{
				continue;
			}
			else if (v_entry->m_thread_id.no == v_thread_id.no)
			{
				//os_dbg("[GC-2] oid = %lld : data = %s", v_oid, v_entry.c_str());
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

extern os_integer_t os_arg_count(os_function_t fn)
{
	os_value v_count = fn(-1, nullptr);
	return os_get_integer(v_count);
}
