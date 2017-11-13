typedef long long os_oid_t;

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
