//import qiitalib;
//import qiitadb;

import arsd.dom;
import vibe.data.json;

import dateparser;

//import jsonizer;

//import core.sync.barrier;
import core.sync.rwmutex;
import core.sync.semaphore;
import core.thread;
import core.time;
import std.algorithm;
import std.algorithm.mutation;
import std.algorithm.sorting;
import std.algorithm.setops;
import std.array;
import std.conv;
import std.datetime;
import std.datetime.systime;
import std.file;
import std.format;

//import std.json;
import std.net.curl;
import std.path;
import std.process;
import std.regex;
import std.stdio;
import std.string;
import std.variant;

import d2sqlite3;
import std.typecons : Nullable;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

/+
Variant getJsonObjectProp(ref Json jsonObj, string prop_name)
{
	Variant result;
	if (jsonObj.type != Json.Type.Object)
		return result;
	foreach (key, value; jsonObj.byKeyValue)
	{
		//writefln("%s: %s", key, value);
		if (key == prop_name)
			result = value.to!string;
	}
	return result;
}
+/

public string ql_systime_to_string(SysTime t)
{
	SysTime t_of_sec = SysTime(DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second));
	return t_of_sec.toISOExtString() ~ `+09:00`;
}

string g_start_time;
shared static this()
{
	g_start_time = ql_systime_to_string(Clock.currTime());
}

Element[] get_result(string period, ref long[] range_array)
{
	long start = range_array[0];
	long end = range_array[range_array.length - 1];
	size_t page = 1;
	Element[] result;
	for (;;)
	{
		string url = format!`https://qiita.com/search?page=%d&sort=created&q=created%%3D%s+stocks%%3A>%%3D%d+stocks%%3A<%%3D%d`(page, period, start, end);
		string html = cast(string) get(url);
		auto document = new Document();
		document.parseGarbage(html);
		Element[] elems = document.getElementsByClassName(`searchResult`);
		result ~= elems;
		if (start != end) break;
		if (elems.length < 10) break;
		page++;
	}
	return result;
}

void handle_range(string period, ref long[] range_array)
{
	if (range_array.length == 0)
		return;
	Element[] elems = get_result(period, range_array);
	if (range_array.length == 1)
	{
		if (elems.length == 0)
			return;
		writefln("%s[stocks-%d]=%d", period, range_array[0], elems.length);
		version(none)
		foreach (ref elem; elems)
		{
			string uuid = elem.getAttribute(`data-uuid`);
			string title = elem.requireSelector(`.searchResult_itemTitle`).innerText;
			string href = elem.getElementsByClassName(`searchResult_itemTitle`)[0].requireSelector("a")
				.getAttribute("href");
			//writefln(`  %s[%d-stocks]: [%s] %s (https://qiita.com%s)`,
			//	period, range_array[0], uuid, title, href);
			writefln(`  %s[%d-stocks]: %s`,
				period, range_array[0], title);
		}
		return;
	}
	if (elems.length == 0)
		return;
	size_t half = range_array.length / 2;
	long[] array1 = range_array[0 .. half];
	long[] array2 = range_array[half .. $];
	handle_range(period, array1);
	handle_range(period, array2);
}

void handle_one_day(string period)
{
	size_t range_size = 8192 * 2;
	long[] range_array;
	range_array.length = range_size;
	for (size_t i = 0; i < range_array.length; i++)
	{
		range_array[i] = i + 1;
	}
	handle_range(period, range_array);
}

int main(string[] args)
{
	//const SysTime v_first_date = SysTime(DateTime(2011, 9, 16));
	const SysTime v_first_date = SysTime(DateTime(2016, 9, 16));
	SysTime v_curr_time = Clock.currTime();
	SysTime v_curr_date = SysTime(DateTime(v_curr_time.year, v_curr_time.month, v_curr_time.day));
	SysTime v_date = v_first_date;
	long count = 0;
	a: for (;;)
	{
		//writeln(v_date);
		string v_str = format!`%04d-%02d-%02d`(v_date.year, v_date.month, v_date.day);
		writeln(v_str);
		handle_one_day(v_str);
		count++;
		if (v_date == v_curr_date)
			break a;
		v_date += dur!`days`(1);
	}
	writefln(`%d days handled!`, count);
	exit(0);
	return 0;
}
