#include <iomanip>
#include <iostream>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <sstream>
using namespace std;

//#include <stdint.h>

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

static int os_dbg(const char *format, ...);

typedef long long os_integer_t;

typedef os_integer_t os_oid_t;
enum os_type_t
{
	OS_NIL,
	OS_ADDRESS,
	OS_ARRAY,
	OS_BYTES,
	OS_INTEGER,
	OS_OBJECT,
	OS_REAL,
	OS_STRING
};
struct os_value;
typedef os_value *os_value_t;

struct os_value
{
	virtual void release() = 0;
	virtual os_type_t type() = 0;
	virtual void to_ss(std::stringstream &stream) = 0;
	virtual os_integer_t get_integer() = 0;
	virtual const char *get_string() = 0;
	virtual os_integer_t get_length() = 0;
};

struct os_integer : public os_value
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
		return "<INTEGER>";
	}
	virtual os_integer_t get_length()
	{
		return 0;
	}
};

struct os_string : public os_value
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

static int os_printf(const char *format, ...)
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

static int os_dbg(const char *format, ...)
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

typedef std::map<DWORD, os_thread_id> os_thread_map_t;
os_thread_map_t g_os_thread_map;

os_thread_id os_get_thread_id()
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

static std::vector<DWORD> os_get_thread_dword_list()
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

static bool os_is_thread_alive(DWORD thread_dword)
{
	std::vector<DWORD> v_list = os_get_thread_dword_list();
	if (std::count(v_list.begin(), v_list.end(), thread_dword) == 0)
		return false;
	return true;
}

static os_oid_t os_get_next_oid()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		static os_oid_t g_last_oid = 100000;
		g_last_oid++;
		return g_last_oid;
	}
}

struct os_value_entry_t : public os_struct
{
	os_oid_t m_oid;
	os_thread_id m_thread_id;
	os_integer_t m_link_count;
	os_value *m_value;
#if 0x0
	void _init(os_thread_id &thread_id)
	{
		m_thread_id = thread_id;
		m_link_count = 0;
		m_value = nullptr;
	}
#endif
	explicit os_value_entry_t(os_oid_t oid)
	{
		m_oid = oid;
		m_thread_id = os_get_thread_id();
		m_link_count = 0;
		m_value = nullptr;
	}
	void set_value(os_value *value)
	{
		if (m_value)
			m_value->release();
		m_value = value;
	}
	virtual ~os_value_entry_t()
	{
		if (m_value)
			m_value->release();
	}
	const char *c_str()
	{
		std::string v_thread_id = m_thread_id.c_str();
		std::stringstream v_stream;
		v_stream << "os_value_entry_t { " << v_thread_id
				 << " ";
		m_value->to_ss(v_stream);
		v_stream << " }";
		m_debug_output_string = v_stream.str();
		return m_debug_output_string.c_str();
	}
};

//typedef std::map<os_oid_t, os_value_entry_t *> os_object_map_t;
//os_object_map_t g_os_object_map;
typedef std::set<os_value_entry_t *> os_value_set_t;
static os_value_set_t g_os_value_set;

extern void os_oid_link(os_value_entry_t *entry)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		entry->m_link_count++;
	}
}

extern void os_oid_unlink(os_value_entry_t *entry)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		entry->m_link_count--;
	}
}

extern os_value_entry_t *os_new_integer(os_integer_t value)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_register_curr_thread();
		os_oid_t v_oid = os_get_next_oid();
		os_value_entry_t *entry = new os_value_entry_t(v_oid);
		entry->set_value(new os_integer(value));
		g_os_value_set.insert(entry);
		return entry;
	}
}

static os_value_entry_t *os_new_std_string(const std::string &value)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_register_curr_thread();
		os_oid_t v_oid = os_get_next_oid();
		os_value_entry_t *entry = new os_value_entry_t(v_oid);
		entry->set_value(new os_string(value));
		g_os_value_set.insert(entry);
		return entry;
	}
}

extern os_value_entry_t *os_new_string(const char *value, os_integer_t len)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_register_curr_thread();
		os_oid_t v_oid = os_get_next_oid();
		os_value_entry_t *entry = new os_value_entry_t(v_oid);
		entry->set_value(new os_string(value, len));
		g_os_value_set.insert(entry);
		return entry;
	}
}

#if 0x0
static os_value_entry_t *os_find_entry(os_oid_t oid)
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		if (g_os_object_map.count(oid) == 0)
		{
			return nullptr;
		}
		//return &g_os_object_map[oid];
		return g_os_object_map[oid];
	}
}
#endif

extern os_integer_t os_get_integer(os_value_entry_t *entry)
{
	if (!entry)
		return 0;
	return entry->m_value->get_integer();
}

extern void os_set_integer(os_value_entry_t *entry, os_integer_t value)
{
	if (!entry)
		return;
	entry->set_value(new os_integer(value));
}

static void os_dump_object_heap()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_value_set_t::iterator it;
		for (it = g_os_value_set.begin(); it != g_os_value_set.end(); it++)
		{
			os_value_entry_t *v_entry = *it;
			os_oid_t v_oid = v_entry->m_oid;
			os_dbg("[DUMP] oid = %lld : data = %s", v_oid, v_entry->c_str());
		}
	}
}

extern void os_gc()
{
	{
		os_thread_locker locker(g_os_thread_mutex);
		os_thread_id v_thread_id = os_get_thread_id();
		std::vector<DWORD> v_list = os_get_thread_dword_list();
		std::map<DWORD, os_integer_t> v_map;
		for (size_t i = 0; i < v_list.size(); i++)
		{
			v_map[v_list[i]] = 0;
		}
		std::vector<os_value_entry_t *> v_removed;
		os_value_set_t::iterator it;
		for (it = g_os_value_set.begin(); it != g_os_value_set.end(); it++)
		{
			os_value_entry_t *v_entry = *it;
			os_oid_t v_oid = v_entry->m_oid;
			//os_dbg("[SCAN] oid = %lld : data = %s", v_oid, v_entry.c_str());
			if (v_map.count(v_entry->m_thread_id.id) == 0)
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

typedef os_value_entry_t *(*os_function_t)(long argc, os_value_entry_t *args[]);

static os_value_entry_t *cos_add2(long argc, os_value_entry_t *args[])
{
	if (argc < 0)
		return os_new_integer(2);
	os_integer_t a = os_get_integer(args[1]);
	os_integer_t b = os_get_integer(args[2]);
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
	void Release()
	{
		delete this;
	}
	static os_value_entry_t *cos_add2(long argc, os_value_entry_t *args[])
	{
		if (argc < 0)
			return os_new_integer(2);
		int a = (int)os_get_integer(args[1]);
		int b = (int)os_get_integer(args[2]);
		os_set_integer(args[1], a * 10);
		os_set_integer(args[2], b * 10);
		return os_new_integer(a + b);
	}
};

static DWORD WINAPI Thread(LPVOID *data)
{
	//os_register_curr_thread();
	os_new_integer(1234);
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
	os_new_std_string("test string テスト文字列");
	os_new_string("string(1)", -1);
	os_new_string("STRING(2)", 3);
	os_function_t v_func = cos_add2;
	os_function_t v_func2 = C_Class1::cos_add2;

	os_thread_id tid1 = os_get_thread_id();
	os_dbg("tid1=%s", tid1.c_str());
	HANDLE hThread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)Thread, (LPVOID) "カウント数表示：", 0, NULL);

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

	std::vector<os_value_entry_t *> v_args(3);
	v_args[1] = os_new_integer(111);
	v_args[2] = os_new_integer(222);
	os_dump_object_heap();
	//os_oid_t v_answer = cos_add2(2, &v_args[0]);
	os_value_entry_t *v_answer = v_func2(2, &v_args[0]);
	os_integer_t v_answer32 = os_get_integer(v_answer);
	os_oid_link(v_answer);
	os_dbg("answer=%d", v_answer32);
	os_dbg("v_args[1]=%lld", os_get_integer(v_args[1]));
	os_dbg("v_args[2]=%lld", os_get_integer(v_args[2]));

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
