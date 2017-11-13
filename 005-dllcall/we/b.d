import os;
import lib1;

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

	import core.sys.windows.windows;
	DWORD v_thread_dword = GetCurrentThreadId();
	writeln(v_thread_dword);

	A a1 = new A;
	A *b = &a1;
	/+
extern (C):
os_value  my_add2(int argc, os_value *argv);
	+/
	/+
	os_value[2] argv;
	argv[0] = os_new_integer(11);
	argv[1] = os_new_integer(22);
	os_value answer = my_add2(2, argv.ptr);
	+/
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
	} while (Thread32Next(h_snapshot, &v_entry));
label_exit:
	CloseHandle(h_snapshot);
	return result;
}

/+
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
+/
