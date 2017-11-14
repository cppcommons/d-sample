import os1;
import lib1;

extern (C)
{
	alias ulong os_value;
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

	long os_get_length(os_value value);
	os_value os_new_array(os_heap heap, long len);
	os_value* os_get_array(os_value value);
	os_value os_new_handle(os_heap heap, void* data);
	void* os_get_handle(os_value value);
	os_value os_new_integer(os_heap heap, long data);
	long os_get_integer(os_value value);
	os_value os_new_string(os_heap heap, char* data, long len);
	char* os_get_string(os_value value);
	void os_dump_heap(os_heap heap);
	bool os_mark(os_value entry);
	bool os_unmark(os_value entry);
	void os_sweep(os_heap heap);
	void os_clear(os_heap heap);
}

import core.sync.mutex;
import std.algorithm.sorting;
import std.array;
import std.format;
import std.stdio;

static __gshared Mutex g_os_thread_mutex;
static this()
{
	g_os_thread_mutex = new Mutex;
}

static long os_get_next_thread_no()
{
	static long g_os_thread_no_max = 0;
	{
		g_os_thread_mutex.lock();
		scope (exit)
			g_os_thread_mutex.unlock();
		g_os_thread_no_max++;
		return g_os_thread_no_max;
	}
}

static long os_get_next_value_id()
{
	static long g_os_value_id_max = 100000;
	{
		g_os_thread_mutex.lock();
		scope (exit)
			g_os_thread_mutex.unlock();
		g_os_value_id_max++;
		return g_os_value_id_max;
	}
}

static uint os_get_thread_id()
{
	import core.sys.windows.windows;

	return GetCurrentThreadId();
}

static long[uint] g_os_thread_no_map;

static long os_get_thread_no(uint thread_id)
{
	{
		g_os_thread_mutex.lock();
		scope (exit)
			g_os_thread_mutex.unlock();
		long* found = thread_id in g_os_thread_no_map;
		if (found)
			return (*found);
		long thread_no = os_get_next_thread_no();
		g_os_thread_no_map[thread_id] = thread_no;
		return thread_no;
	}
}

static os_object[os_value] g_os_value_map;

abstract class os_object
{
	bool m_marked = false;
	long m_id;
	uint m_thread_id;
	long m_thread_no;
	long get_integer();
	override string toString() const pure @safe;
	this()
	{
		m_id = os_get_next_value_id();
		m_thread_id = os_get_thread_id();
		m_thread_no = os_get_thread_no(m_thread_id);
	}

	string thread_display() const pure @safe
	{
		auto app = appender!string();
		app ~= "[";
		app ~= format!`tid=%u`(m_thread_id);
		app ~= format!`(no=%d)`(m_thread_no);
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

	override long get_integer()
	{
		return m_value;
	}

	override string toString() const pure @safe
	{
		auto app = appender!string();
		app ~= "[";
		app ~= format!`id=%d:`(m_id);
		//app ~= format!`:tid=%u`(m_thread_id);
		app ~= thread_display();
		app ~= format!` %d`(m_value);
		app.put("]");
		return app.data;
	}
}

extern (C) long os_get_length(os_value value);
extern (C) os_value os_new_array(os_heap heap, long len);
extern (C) os_value* os_get_array(os_value value);
extern (C) os_value os_new_handle(os_heap heap, void* data);
extern (C) void* os_get_handle(os_value value);
extern (C) os_value os_new_integer(os_heap heap, long data)
{
	writeln(`os_new_integer(): data=`, data);
	auto o = new os_integer(data);
	{
		g_os_thread_mutex.lock();
		scope (exit)
			g_os_thread_mutex.unlock();
		g_os_value_map[o.m_id] = o;
	}
	return o.m_id;
}

extern (C) long os_get_integer(os_value value)
{
	import std.stdio;

	if (value == 0)
		return 0;
	{
		g_os_thread_mutex.lock();
		scope (exit)
			g_os_thread_mutex.unlock();
		os_object* found = value in g_os_value_map;
		if (!found)
			return 0;
		writeln(`[DEBUG] `, *found);
		return (*found).get_integer();
	}
}

extern (C) os_value os_new_string(os_heap heap, char* data, long len);
extern (C) char* os_get_string(os_value value);
extern (C) void os_dump_heap(os_heap heap)
{
	{
		g_os_thread_mutex.lock();
		scope (exit)
			g_os_thread_mutex.unlock();
		os_value[] keys = g_os_value_map.keys();
		alias myComp = (x, y) => x < y;
		keys.sort!(myComp);
		writeln(keys);
	}
}

extern (C) bool os_mark(os_value entry);
extern (C) bool os_unmark(os_value entry);
extern (C) void os_sweep(os_heap heap);
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
		return 0;
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
	os_value[2] argv;
	argv[0] = os_new_integer(0, 11);
	argv[1] = os_new_integer(0, 22);
	os_dump_heap(0);
	os_value answer = my_add2(0, 2, argv.ptr);
	os_dump_heap(0);
	writeln(answer);
	long answer2 = os_get_integer(answer);
	writeln(`answer2=`, answer2);
	int[os_value] dummy;
	int* bbb = answer in dummy;
	exit(0);
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
