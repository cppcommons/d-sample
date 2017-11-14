import os1;
import lib1;

extern (C)
{
	alias char* os_value;
	alias ulong os_heap;
	alias os_value function(os_heap heap, int argc, os_value* argv) os_function;
	enum os_type
	{
		OS_NIL,
		OS_ARRAY,
		OS_BYTES,
		OS1_HANDLE,
		OS_INTEGER,
		OS_REAL,
		OS_STRING,
	}

	long os_get_thread_index();
	long os_get_length(os_value value);
	os_value os_new_array(os_heap heap, long len);
	os_value* os_get_array(os_value value);
	os_value os_new_handle(os_heap heap, void* data);
	void* os_get_handle(os_value value);
	os_value os_new_integer(os_heap heap, long data);
	long os_get_integer(os_value value);
	os_value os_new_string(os_heap heap, char* data);
	os_value os_new_string2(os_heap heap, char* data, long len);
	char* os_get_string(os_value value);
	void os_dump_heap(os_heap heap);
	bool os_mark(os_value value);
	bool os_unmark(os_value value);
	void os_sweep(os_heap heap);
	void os_clear(os_heap heap);
}

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

class os_thread_local
{
	uint m_thread_id;
	BigInt m_thread_no;
	this(int ignored)
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
	g_os_thread_local = new os_thread_local(0);
}

static  /*thread_local*/  ~this()
{
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		/+
		if (g_os_thread_local is null)
		{
			writeln("CALLED AGAIN!");
			return;
		}
		+/
		if (g_os_thread_local.m_thread_no >= 0)
		{
			writefln(`THREAD #%d END.`, g_os_thread_local.m_thread_no);
		}
		delete g_os_thread_local;
		g_os_thread_local = null;
	}
}

version (Windows)
{
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

	static __gshared BigInt g_os_value_id_max;
	shared static this()
	{
		//g_os_value_id_max = "2000000000000000000000000000000000000000000000000000000000000";
		g_os_value_id_max = "100000";
	}

	pragma(inline) static BigInt os_get_next_value_id()
	{
		{
			g_os_global_mutex.lock_nothrow();
			scope (exit)
				g_os_global_mutex.unlock_nothrow();
			g_os_value_id_max++;
			return g_os_value_id_max;
		}
	}

	pragma(inline) static uint os_get_thread_id()
	{
		return g_os_thread_local.m_thread_id;
	}
}

extern (C) long os_get_thread_index()
{
	if (g_os_thread_local.m_thread_no < 0)
		g_os_thread_local.m_thread_no = os_get_next_thread_no();
	return g_os_thread_local.m_thread_no.toLong();
}

class os_map
{
	Mutex m_mutex;
	os_object[char* ] m_map;
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
			m_map[o.m_id_string] = o;
		}
	}

	os_object lookup(os_value value)
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
			m_map.remove(o.m_id_string);
		}
	}

	os_object[] values()
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

abstract class os_object
{
	//long m_id;
	BigInt m_id;
	//immutable(char)* m_id_string;
	char* m_id_string;
	uint m_thread_id;
	long m_thread_no;
	bool m_marked;
	bool m_referred;
	os_value* get_array();
	long get_integer();
	override string toString() const; //pure @safe;
	this()
	{
		m_id = os_get_next_value_id();
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
		//app ~= "(";
		app ~= format!`@%d`(m_thread_no);
		//app ~= ":";
		//app ~= format!`0x%x`(m_thread_id);
		//app ~= ")";
		return app.data;
	}
}

static string os_value_to_string(os_value value) //pure @safe
{
	if (value is null)
		return "null";
	//return "<>";
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		//if (*value == '#')
		//	value++;
		//BigInt id = os_to_string(value);
		//os_object* found = id in g_os_value_map;
		os_object found = g_global_map.lookup(value);
		if (!found)
			return "?";
		return found.toString();
	}
}

class os_array : os_object
{
	os_value[] m_array;
	this(long len)
	{
		m_array.length = cast(uint) len;
	}

	override os_value* get_array()
	{
		return m_array.ptr;
	}

	override long get_integer()
	{
		return 0;
	}

	override string toString() const  //pure @safe
	{
		auto app = appender!string();
		app ~= format!`array(%s)`(oid_string());
		app ~= "[";
		for (uint i = 0; i < m_array.length; i++)
		{
			if (i > 0)
				app ~= ", ";
			app ~= os_value_to_string(cast(char*) m_array[i]);
		}
		app ~= "]";
		return app.data;
	}
}

class os_integer : os_object
{
	long m_value;
	this(long value)
	{
		m_value = value;
	}

	override os_value* get_array()
	{
		return null;
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

extern (C) long os_get_length(os_value value);
extern (C) os_value os_new_array(os_heap heap, long len)
{
	writeln(`os_new_array(): len=`, len);
	auto o = new os_array(len);
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		//g_os_value_map[o.m_id] = o;
		g_global_map.insert(o);
	}
	return o.m_id_string;
}

extern (C) os_value* os_get_array(os_value value)
{
	if (value is null)
		return null;
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		//if (*value == '#')
		//	value++;
		//BigInt id = os_to_string(value);
		//os_object* found = id in g_os_value_map;
		os_object found = g_global_map.lookup(value);
		if (!found)
			return null;
		return found.get_array();
	}
}

extern (C) os_value os_new_handle(os_heap heap, void* data);
extern (C) void* os_get_handle(os_value value);
extern (C) os_value os_new_integer(os_heap heap, long data)
{
	writeln(`os_new_integer(): data=`, data);
	auto o = new os_integer(data);
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		//g_os_value_map[o.m_id] = o;
		g_global_map.insert(o);
	}
	return o.m_id_string;
}

static char[] os_to_string(char* s)
{
	import core.stdc.string : strlen;

	return s ? s[0 .. strlen(s)] : cast(char[]) null;
}

extern (C) long os_get_integer(os_value value)
{
	if (value is null)
		return 0;
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		//if (*value == '#')
		//	value++;
		//BigInt id = os_to_string(value);
		//os_object* found = id in g_os_value_map;
		os_object found = g_global_map.lookup(value);
		if (!found)
			return 0;
		writeln(`[DEBUG] `, found);
		return found.get_integer();
	}
}

extern (C) os_value os_new_string(os_heap heap, char* data, long len);
extern (C) char* os_get_string(os_value value);
extern (C) void os_dump_heap(os_heap heap)
{
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		os_object[] values = g_global_map.values();
		writefln("[DUMP HEAP #%u]", heap);
		foreach (value; values)
		{
			writeln("  ", value);
		}
	}
}

extern (C) bool os_mark(os_value value)
{
	if (value is null)
		return false;
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		//if (*value == '#')
		//	value++;
		//BigInt id = os_to_string(value);
		//os_object* found = id in g_os_value_map;
		os_object found = g_global_map.lookup(value);
		if (!found)
			return false;
		return found.m_marked = true;
	}
}

extern (C) bool os_unmark(os_value value)
{
	if (value is null)
		return false;
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		//if (*value == '#')
		//	value++;
		//BigInt id = os_to_string(value);
		//os_object* found = id in g_os_value_map;
		os_object found = g_global_map.lookup(value);
		if (!found)
			return false;
		return found.m_marked = false;
	}
}

extern (C) void os_sweep(os_heap heap)
{
	{
		g_os_global_mutex.lock_nothrow();
		scope (exit)
			g_os_global_mutex.unlock_nothrow();
		os_object[] values = g_global_map.values();
		//alias myComp2 = (x, y) => x.m_id < y.m_id;
		//values.sort!(myComp2);
		writefln("[SWEEP #%u]", heap);
		foreach (value; values)
		{
			value.m_referred = false;
		}
		foreach (value; values)
		{
			if (!value.m_marked)
				continue;
			value.m_referred = true;
			os_array a = cast(os_array) value;
			if (a !is null)
			{
				for (uint i = 0; i < a.m_array.length; i++)
				{
					os_value elem = a.m_array[i];
					os_object o = g_global_map.lookup(elem);
					if (o)
					{
						o.m_referred = true;
					}
				}
			}
		}
		foreach (value; values)
		{
			if (!value.m_referred)
			{
				g_global_map.remove(value);
			}
		}
	}
}

extern (C) void os_clear(os_heap heap);

//extern (C) os_value my_add2(os_heap heap, int argc, os_value* argv);

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

extern (C) int d_mul2(int a, int b)
{
	writefln(`d_mul(%d, %d)`, a, b);
	return a * b;
}

extern (C) os_value my_mul2(os_heap heap, int argc, os_value* argv)
{
	writeln(`my_mul2(0)`);
	if (argc != 2)
		return null;
	long a0 = os_get_integer(argv[0]);
	long a1 = os_get_integer(argv[1]);
	return os_new_integer(heap, a0 * a1);
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

	import core.sys.windows.windows;

	DWORD v_thread_dword = GetCurrentThreadId();
	writeln(v_thread_dword);

	/+
	A a1 = new A;
	os_value[] testing;
	BinaryHeap!(os_value[]) h3 = BinaryHeap!(os_value[])(testing);
	h3.insert(new os_value(1234));
	h3.insert(new os_value(5678));
	writeln(h3.dup);
	+/
	/+
extern (C):
os_value  my_add2(int argc, os_value *argv);
	+/
	os_value xxx = os_new_integer(0, 123);
	writeln(toString(xxx));
	long xxx2 = os_get_integer(xxx);
	writeln("xxx2=", xxx2);
	os_value dummy_ = os_new_array(0, 2);
	os_value* dummy_v = os_get_array(dummy_);
	os_value v_array_ = os_new_array(0, 2);
	os_mark(v_array_);
	os_value* argv = os_get_array(v_array_);
	//os_value[2] argv;
	argv[0] = os_new_integer(0, 11);
	argv[1] = os_new_integer(0, 22);
	os_dump_heap(0);
	os_value answer = my_add2(0, 2, argv);
	os_mark(answer);
	os_dump_heap(0);
	writeln(answer);
	long answer2 = os_get_integer(answer);
	writeln(`answer2=`, answer2);
	int[os_value] dummy;
	int* bbb = answer in dummy;
	os_sweep(0);
	os_dump_heap(0);

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
			os_new_integer(0, 2222);
			for (int i = 0; i < 1000; i++)
			{
				sync_fun();
				sync_fun2();
			}
		};
		tg.create = {
			os_new_integer(0, 3333);
			for (int i = 0; i < 1000; i++)
			{
				sync_fun();
				sync_fun2();
			}
		};
		tg.joinAll();
		writeln("total=", total);
		writeln("total2=", total2);
		os_dump_heap(0);
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
