import os2;
import vc6;

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

	os_int32 test_int = vc6_add2(111, 222);
	writeln(`test_int=`, test_int);

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

	os_new_string(cast(char*)"abc".ptr);

	os_object xxx = os_new_integer(123);

	os_int64 xxx2 = os_get_integer(xxx, 0);
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
	os_dump_heap();
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
