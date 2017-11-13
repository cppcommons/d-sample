class thread_mutex
{
  public:
	thread_mutex()
	{
		::InitializeCriticalSection(&m_cs);
	}
#ifndef __DMC__
	thread_mutex(DWORD spinCount)
	{
		::InitializeCriticalSectionAndSpinCount(&m_cs, spinCount);
	}
#endif /* !__DMC__ */
	~thread_mutex()
	{
		::DeleteCriticalSection(&m_cs);
	}

  public:
	void lock()
	{
		::EnterCriticalSection(&m_cs);
	}
	bool try_lock()
	{
		return ::TryEnterCriticalSection(&m_cs) != FALSE;
	}
	void unlock()
	{
		::LeaveCriticalSection(&m_cs);
	}
#ifndef __DMC__
	DWORD set_spin_count(DWORD spinCount)
	{
		return ::SetCriticalSectionSpinCount(&m_cs, spinCount);
	}
#endif /* !__DMC__ */
  private:
	CRITICAL_SECTION m_cs;
};

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

struct os_thread_locker
{
	//stlsoft::winstl_project::thread_mutex &m_mutex;
	thread_mutex &m_mutex;
	//explicit os_thread_locker(stlsoft::winstl_project::thread_mutex &mutex) : m_mutex(mutex)
	explicit os_thread_locker(thread_mutex &mutex) : m_mutex(mutex)
	{
		m_mutex.lock();
	}
	virtual ~os_thread_locker()
	{
		m_mutex.unlock();
	}
};

//typedef long long os_oid_t;
typedef long long os_sid_t;

struct os_data
{
	virtual void release() = 0;
	virtual os_type_t type() = 0;
	virtual void to_ss(std::stringstream &stream) = 0;
	virtual long long get_integer() = 0;
	virtual const char *get_string() = 0;
	virtual long long get_length() = 0;
	virtual os_value *get_array() = 0;
	virtual void *get_handle() = 0;
};

struct os_array : public os_data
{
	std::vector<os_value> m_value;
	explicit os_array(long long len)
	{
		m_value.resize(len + 1);
	}
	virtual void release()
	{
		size_t sz = (m_value.size() - 1);
		os_dbg("os_array::release(): length=%zu", sz);
		delete this;
	}
	virtual os_type_t type()
	{
		return OS_ARRAY;
	}
	virtual void to_ss(std::stringstream &stream)
	{
		stream << "{array of " << (m_value.size() - 1) << " elements}";
	}
	virtual long long get_integer()
	{
		return 0;
	}
	virtual const char *get_string()
	{
		return "";
	}
	virtual long long get_length()
	{
		return m_value.size();
	}
	virtual os_value *get_array()
	{
		return &m_value[0];
	}
	virtual void *get_handle()
	{
		return nullptr;
	}
};

struct os_handle : public os_data
{
	void *m_value;
	explicit os_handle(void *value)
	{
		m_value = value;
	}
	virtual void release()
	{
		os_dbg("os_handle::release(): %p", m_value);
		delete this;
	}
	virtual os_type_t type()
	{
		return OS_HANDLE;
	}
	virtual void to_ss(std::stringstream &stream)
	{
		stream << m_value;
	}
	virtual long long get_integer()
	{
		return 0;
	}
	virtual const char *get_string()
	{
		return "";
	}
	virtual long long get_length()
	{
		return 0;
	}
	virtual os_value *get_array()
	{
		return nullptr;
	}
	virtual void *get_handle()
	{
		return m_value;
	}
};

struct os_integer : public os_data
{
	long long m_value;
	explicit os_integer(long long value)
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
	virtual long long get_integer()
	{
		return m_value;
	}
	virtual const char *get_string()
	{
		return "";
	}
	virtual long long get_length()
	{
		return 0;
	}
	virtual os_value *get_array()
	{
		return nullptr;
	}
	virtual void *get_handle()
	{
		return nullptr;
	}
};

struct os_string : public os_data
{
	std::string m_value;
	explicit os_string(const std::string &value)
	{
		m_value = value;
	}
	explicit os_string(const char *value, long long len)
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
	virtual long long get_integer()
	{
		return 0;
	}
	virtual const char *get_string()
	{
		return m_value.c_str();
	}
	virtual long long get_length()
	{
		return m_value.size();
	}
	virtual os_value *get_array()
	{
		return nullptr;
	}
	virtual void *get_handle()
	{
		return nullptr;
	}
};
