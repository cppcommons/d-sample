//import os1;
import lib1;
import lib2;

extern (C)
{
	alias ulong os_size_t;
	alias long os_offset_t;
	alias os_object function(int argc, os_object* argv) os_function;
	enum os_type
	{
		OS_NIL,
		OS_ADDRESS,
		OS_ARRAY,
		OS_BYTES,
		OS_INTEGER,
		OS_REAL,
		OS_STRING,
	}

	os_array os_new_array(os_size_t size);
	os_size_t os_array_size(os_object array);
	void os_array_clear(os_object array);
	os_object os_get_value(os_object array_or_value, os_offset_t index);
	void os_set_value(os_object array, os_offset_t index, os_object data);
	void os_push_value(os_object array, os_object data);
	//os_address os_new_address(void* data);
	void* os_get_address(os_object array_or_value, os_offset_t index);
	void os_set_address(os_object array, os_offset_t index, void* data);
	void os_push_address(os_object array, void* data);
	os_integer os_new_integer(long data);
	long os_get_integer(os_object array_or_value, os_offset_t index);
	void os_set_integer(os_object array, os_offset_t index, long data);
	void os_push_integer(os_object array, long data);
	os_string os_new_string(char* data);
	os_string os_new_string2(char* data, os_size_t size);
	char* os_get_string(os_object array_or_value, os_offset_t index);
	char* os_get_string2(os_object array_or_value, os_size_t* len, os_offset_t index);
	void os_set_string(os_object array, os_offset_t index, char* data);
	void os_push_string(os_object array, char* data);
	void os_set_string2(os_object array, os_offset_t index, char* data, os_size_t size);
	void os_push_string2(os_object array, char* data, os_size_t size);
	void os_dump_heap();
	bool os_mark(os_object value);
	bool os_unmark(os_object value);
	void os_sweep();
	void os_clear();
}

import core.memory;
import core.sync.mutex;
import std.algorithm.sorting;
import std.array;
import std.bigint;
import std.format;
import std.stdio;
import std.string;

static __gshared Mutex g_os_global_mutex;
shared static this()
{
	g_os_global_mutex = new Mutex;
}

private class os_thread_local
{
	uint m_thread_id;
	BigInt m_thread_no;
	this()
	{
		import core.sys.windows.windows;

		m_thread_id = GetCurrentThreadId();
		m_thread_no = -1;
	}

	~this()
	{
		//if (m_thread_no >= 0)
		{
			writefln(`os_thread_local::~this() #%d.`, m_thread_no);
		}
	}
}

static  /*thread_local*/ os_thread_local g_os_thread_local;
static  /*thread_local*/ this()
{
	g_os_thread_local = new os_thread_local;
}

static  /*thread_local*/  ~this()
{
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		if (g_os_thread_local.m_thread_no >= 0)
		{
			writefln(`THREAD #%d END.`, g_os_thread_local.m_thread_no);
		}
		delete g_os_thread_local;
		g_os_thread_local = null;
	}
}

pragma(inline) static BigInt os_get_next_thread_no()
{
	static __gshared BigInt g_os_thread_no_max = 0;
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		g_os_thread_no_max++;
		return g_os_thread_no_max;
	}
}

static __gshared BigInt g_os_object_id_max;
shared static this()
{
	//g_os_object_id_max = "2000000000000000000000000000000000000000000000000000000000000";
	g_os_object_id_max = "100000";
}

pragma(inline) static BigInt os_get_next_object_id()
{
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		g_os_object_id_max++;
		return g_os_object_id_max;
	}
}

pragma(inline) static uint os_get_thread_id()
{
	return g_os_thread_local.m_thread_id;
}

extern (C) BigInt os_get_thread_index()
{
	if (g_os_thread_local.m_thread_no < 0)
		g_os_thread_local.m_thread_no = os_get_next_thread_no();
	return g_os_thread_local.m_thread_no;
}

private class os_map
{
	Mutex m_mutex;
	os_object[os_object] m_map;
	this()
	{
		m_mutex = new Mutex;
	}

	void insert(os_object o)
	{
		if (o is null)
			return;
		{
			m_mutex.lock_nothrow();
			scope (exit)
				m_mutex.unlock_nothrow();
			m_map[o] = o;
		}
	}

	os_object lookup(os_object value)
	{
		{
			m_mutex.lock_nothrow();
			scope (exit)
				m_mutex.unlock_nothrow();
			os_object* found = value in m_map;
			if (!found)
				return null;
			return (*found);
		}
	}

	void remove(os_object o)
	{
		if (o is null)
			return;
		{
			m_mutex.lock_nothrow();
			scope (exit)
				m_mutex.unlock_nothrow();
			m_map.remove(o);
		}
	}

	os_object[] objects()
	{
		{
			m_mutex.lock_nothrow();
			scope (exit)
				m_mutex.unlock_nothrow();
			os_object[] result = m_map.values();
			alias compare_fn = (x, y) => x.m_id < y.m_id;
			result.sort!(compare_fn);
			return result;
		}
	}
}

static __gshared os_map g_global_map;
shared static this()
{
	g_global_map = new os_map;
}

/+
private interface os_array_iface
{
	os_object** get_array();
}
+/

private interface os_number_iface
{
	long get_integer();
}

private abstract class os_object

{
	//char[256] eye_catcher;
	BigInt m_id;
	char* m_id_string;
	uint m_thread_id;
	BigInt m_thread_no;
	bool m_marked;
	bool m_referred;
	override string toString() const; //pure @safe;
	this()
	{
		//eye_catcher = "EYE_CATCHER";
		m_id = os_get_next_object_id();
		string s = format(`#%d`, m_id);
		m_id_string = cast(char*) toStringz(s);
		m_thread_id = os_get_thread_id();
		m_thread_no = os_get_thread_index();
		m_marked = false;
		m_referred = false;
	}

	string oid_string() const  //pure @safe
	{
		auto app = appender!string();
		if (m_marked)
			app ~= `<*>`;
		app ~= format!`#%d`(m_id);
		app ~= format!`@%d`(m_thread_no);
		return app.data;
	}
}

private class os_array : os_object //, os_array_iface //, os_number_iface
{
	os_object[] m_array;
	this(os_size_t size)
	{
		m_array.length = cast(size_t) size;
	}

	/+
	override os_object** get_array()
	{
		return m_array.ptr;
	}
	+/

	override string toString() const  //pure @safe
	{
		auto app = appender!string();
		app ~= format!`array(%s)`(oid_string());
		app ~= "[";
		for (uint i = 0; i < m_array.length; i++)
		{
			if (i > 0)
				app ~= ", ";
			os_object o = g_global_map.lookup(cast(os_object) m_array[i]);
			if (!o)
				app ~= "null";
			else
				app ~= o.toString();
		}
		app ~= "]";
		return app.data;
	}
}

private class os_integer : os_object, os_number_iface
{
	long m_value;
	this(long value)
	{
		m_value = value;
	}

	override long get_integer()
	{
		return m_value;
	}

	override string toString() const  //pure @safe
	{
		auto app = appender!string();
		app ~= "{";
		app ~= oid_string();
		app ~= format!` %d`(m_value);
		app ~= "}";
		return app.data;
	}
}

private class os_string : os_object
{
	char[] m_value;
	this(char[] value)
	{
		m_value = value;
	}

	override string toString() const  //pure @safe
	{
		auto app = appender!string();
		app ~= "{";
		app ~= oid_string();
		app ~= format!` "%s"`(m_value);
		app ~= "}";
		return app.data;
	}
}

extern (C) os_array os_new_array(os_size_t size)

{
	auto o = new os_array(size);
	{
		g_global_map.insert(o);
	}
	return o;
}

/+
extern (C) os_object** os_get_array(os_object* value)
{
	if (value is null)
		return null;
	{
		os_object found = g_global_map.lookup(value);
		if (!found)
			return null;
		os_array_iface iface = cast(os_array_iface) found;
		if (!iface)
			return null;
		return iface.get_array();
	}
}
+/

extern (C) os_integer os_new_integer(long data)
{
	auto o = new os_integer(data);
	g_global_map.insert(o);
	return o;
}

extern (C) long os_get_integer(os_object array_or_value, os_offset_t index = -1)
{
	if (array_or_value is null)
		return 0;
	{
		os_object found = g_global_map.lookup(array_or_value);
		if (!found)
			return 0;
		os_number_iface iface = cast(os_number_iface) found;
		if (!iface)
			return 0;
		return iface.get_integer();
	}
}

extern (C) os_object os_new_string(char* data);
extern (C) os_object os_new_string2(char* data, os_size_t size)
{
	char[] s = data[0 .. cast(size_t) size];
	auto o = new os_string(s);
	g_global_map.insert(o);
	return o;
}

os_object os_new_string(string data)
{
	char[] s = cast(char[]) data;
	return os_new_string2(s.ptr, s.length);
}

extern (C) char* os_get_string(os_object array_or_value, os_offset_t index = -1);
extern (C) char* os_get_string2(os_object array_or_value, os_size_t* len, os_offset_t index = -1);

extern (C) void os_dump_heap()
{
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		os_object[] objects = g_global_map.objects();
		writefln("[DUMP HEAP]");
		foreach (o; objects)
		{
			writeln("  ", o.toString());
		}
	}
}

extern (C) bool os_mark(os_object value)
{
	if (value is null)
		return false;
	{
		os_object found = g_global_map.lookup(value);
		if (!found)
			return false;
		return found.m_marked = true;
	}
}

extern (C) bool os_unmark(os_object value)
{
	if (value is null)
		return false;
	{
		os_object found = g_global_map.lookup(value);
		if (!found)
			return false;
		return found.m_marked = false;
	}
}

extern (C) void os_sweep()
{
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		os_object[] objects = g_global_map.objects();
		writefln("[SWEEP]");
		foreach (value; objects)
		{
			value.m_referred = false;
		}
		foreach (value; objects)
		{
			if (!value.m_marked)
				continue;
			value.m_referred = true;
			os_array a = cast(os_array) value;
			if (a !is null)
			{
				for (uint i = 0; i < a.m_array.length; i++)
				{
					os_object elem = a.m_array[i];
					os_object o = g_global_map.lookup(elem);
					if (o)
					{
						o.m_referred = true;
					}
				}
			}
		}
		foreach (value; objects)
		{
			if (!value.m_referred)
			{
				g_global_map.remove(value);
			}
		}
	}
}

extern (C) void os_clear();

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

// http://forum.dlang.org/post/c6ojg9$c8p$1@digitaldaemon.com
char[] toString(char* s)
{
	import core.stdc.string : strlen;

	return s ? s[0 .. strlen(s)] : cast(char[]) null;
}

// http://forum.dlang.org/post/c6ojg9$c8p$1@digitaldaemon.com
wchar[] toString(wchar* s)
{
	import core.stdc.wchar_ : wcslen;

	return s ? s[0 .. wcslen(s)] : cast(wchar[]) null;
}

class A
{
	int m_a;
}

void main(string[] args)
{
	import core.thread;
	import std.stdio;
	import std.string;
	import std.container.binaryheap;
	import std.algorithm.searching; // BinaryHeap.canFind(x)
	import std.range; // BinaryHeap.take(n)

	int[] a = [4, 1, 3, 2, 16, 9, 10, 14, 8, 7];
	BinaryHeap!(int[]) h = heapify(a);
	// largest element
	writeln(h.front); // 16
	writeln(h.canFind(16));
	// a has the heap property
	//assert(equal(a, [16, 14, 10, 8, 7, 9, 3, 2, 4, 1]));
	uint[] tid_list = os_get_thread_dword_list();
	writeln(tid_list);
	//auto h2 = heapify!"a > b"(tid_list);
	BinaryHeap!(uint[]) h2 = heapify(tid_list);
	//writeln(h2);
	writeln(h2.front);
	writeln(h2.dup);
	writeln(h2.front);

	//import core.sys.windows.windows;
	//DWORD v_thread_dword = GetCurrentThreadId();
	//writeln(v_thread_dword);

	os_new_string("abc");

	os_object xxx = os_new_integer(123);
	//writeln(toString(xxx));
	//writeln(xxx.eye_catcher);
	os_string yyy;

	os_get_integer(yyy);
	//my_str1(xxx);

	long xxx2 = os_get_integer(xxx);
	writeln("xxx2=", xxx2);
	writeln("(1)");
	os_object dummy_ = os_new_array(2);
	//os_object** dummy_v = os_get_array(dummy_);
	os_object v_array_ = os_new_array(2);
	os_mark(v_array_);
	//os_object** argv = os_get_array(v_array_);
	writeln("(2)");
	os_object[2] argv;
	argv[0] = os_new_integer(11);
	argv[1] = os_new_integer(22);
	writeln("(2.25)");
	os_dump_heap();
	writeln("(2.26)");
	os_object answer = my_add2(2, argv.ptr);
	writeln("(2.27)");
	os_mark(answer);
	writeln("(2.50)");
	os_dump_heap();
	writeln(answer);
	long answer2 = os_get_integer(answer);
	writeln(`answer2=`, answer2);
	//int[os_object* ] dummy;
	//int* bbb = answer in dummy;
	writeln("(3)");
	os_sweep();
	os_dump_heap();

	writeln("(4)");
	{
		import std.stdio;
		import core.sync.mutex : Mutex;
		import core.thread;

		//static __gshared int total;
		//static shared int total;
		int total;
		void sync_fun()
		{
			synchronized
			{
				total += 1;
			}
		}

		int total2;
		shared Mutex mtx = new shared Mutex();
		void sync_fun2()
		{
			mtx.lock_nothrow();
			total2 += 1;
			mtx.unlock_nothrow();
		}

		int result1, result2;
		auto tg = new ThreadGroup;
		tg.create = {
			//os_new_integer(0, 1111);
			for (int i = 0; i < 1000; i++)
			{
				sync_fun();
				sync_fun2();
			}
		};
		tg.create = {
			os_new_integer(2222);
			for (int i = 0; i < 1000; i++)
			{
				sync_fun();
				sync_fun2();
			}
		};
		tg.create = {
			os_new_integer(3333);
			for (int i = 0; i < 1000; i++)
			{
				sync_fun();
				sync_fun2();
			}
		};
		tg.joinAll();
		writeln("total=", total);
		writeln("total2=", total2);
		os_dump_heap();
	}
}

static uint[] os_get_thread_dword_list()
{
	import core.sys.windows.windows;
	import core.sys.windows.tlhelp32;

	uint[] result;
	DWORD v_proc_id = GetCurrentProcessId();
	HANDLE h_snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
	if (h_snapshot == INVALID_HANDLE_VALUE)
	{
		return result;
	}
	THREADENTRY32 v_entry;
	v_entry.dwSize = THREADENTRY32.sizeof;
	if (!Thread32First(h_snapshot, &v_entry))
	{
		goto label_exit;
	}
	do
	{
		if (v_entry.th32OwnerProcessID == v_proc_id)
			result ~= v_entry.th32ThreadID;
	}
	while (Thread32Next(h_snapshot, &v_entry));
label_exit:
	CloseHandle(h_snapshot);
	return result;
}
