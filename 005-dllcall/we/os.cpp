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

static os_sid_t os_thread_info_sid_max = 0;
struct os_thread_info
{
	DWORD m_dword;
	os_sid_t m_sid;
	explicit os_thread_info(DWORD thread_dword)
	{
		m_dword = thread_dword;
		m_sid = os_next_sid(g_os_thread_mutex, os_thread_info_sid_max);
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

std::map<DWORD, os_thread_info *> g_thread_info_map;

static os_thread_info *os_get_thread_info(DWORD thread_dword)
{
	if (g_thread_info_map.count(thread_dword) == 0)
	{
		os_thread_info *v_info = new os_thread_info(thread_dword);
		g_thread_info_map[thread_dword] = v_info;
	}
	return g_thread_info_map[thread_dword];
}

struct os_struct
{
	std::string m_debug_output_string;
};

static os_sid_t os_get_next_oid()
{
	static os_sid_t g_value_sid_max = 100000;
	return os_next_sid(g_os_thread_mutex, g_value_sid_max);
}

struct os_variant_t : public os_struct
{
	os_sid_t m_oid;
	os_thread_info *m_thread_info;
	//long long m_link_count;
	bool m_marked;
	os_data *m_value;
	explicit os_variant_t(os_sid_t oid)
	{
		m_oid = oid;
		//m_thread_id = os_get_thread_id();
		DWORD v_thread_dword = ::GetCurrentThreadId();
		m_thread_info = os_get_thread_info(v_thread_dword);
		//m_link_count = 0;
		m_marked = false;
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
		//std::string v_thread_id = m_thread_id.c_str();
		std::string v_thread_id = m_thread_info->c_str();
		std::stringstream v_stream;
		v_stream << "os_variant_t { " << v_thread_id
				 << " MARK="
				 << m_marked
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
		//if (entry->m_value->type() == OS_ARRAY)
		//	return false;
		entry->m_marked = true;
		return true;
	}
}

extern long long os_get_length(os_value value)
{
	if (!value)
		return 0;
	return value->m_value->get_length();
}

static inline os_value os_new_value(os_data *data)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_sid_t v_oid = os_get_next_oid();
		os_value entry = new os_variant_t(v_oid);
		entry->set_value(data);
		g_os_value_set.insert(entry);
		return entry;
	}
}

extern os_value os_new_array(long long len)
{
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
		DWORD v_thread_dword = ::GetCurrentThreadId();
		//os_thread_id v_thread_id = os_get_thread_id();
		os_thread_info *v_thread_info = os_get_thread_info(v_thread_dword);
		std::set<DWORD> v_thread_list = os_get_thread_dword_list();
		std::vector<os_variant_t *> v_removed;
		os_value_set_t::iterator it;
		for (it = g_os_value_set.begin(); it != g_os_value_set.end(); it++)
		{
			os_variant_t *v_entry = *it;
			os_sid_t v_oid = v_entry->m_oid;
			if (reset && v_entry->m_thread_info->m_sid == v_thread_info->m_sid)
			{
				v_entry->m_marked = false;
			}
			if (v_entry->m_thread_info->m_sid == v_thread_info->m_sid)
			{
				if (!v_entry->m_marked)
					v_removed.push_back(v_entry);
			}
			else if (v_thread_list.count(v_entry->m_thread_info->m_dword) == 0)
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

#if 0x0
extern long long os_arg_count(os_function_t fn)
{
	os_value v_count = fn(-1, nullptr);
	return os_get_integer(v_count);
}
#endif