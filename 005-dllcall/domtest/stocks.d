import qiitalib;
import qiitadb;

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

string g_start_time;
shared static this()
{
	g_start_time = ql_systime_to_string(Clock.currTime());
}

bool handle_one_day_2(SysTime v_date)
{
	string v_period = format!`%04d-%02d-%02d`(v_date.year, v_date.month, v_date.day);
	auto count = g_db.execute(format!"SELECT count(*) FROM qiita_posts WHERE post_date == '%s'"(v_period))
		.oneValue!long;
	if (count)
	{
		return true;
	}

	writefln(`[%s: handle_one_day_2()]`, v_period);
	//string[] uuid_list;
	struct QPost
	{
		string uuid;
		long favCount;
		string title;
		string href;
		string header;
		string description;
		string tags;
	}

	QPost[] posts;
	for (int i = 0; i < int.max; i++)
	{
		string url = format!`https://qiita.com/search?sort=created&q=created%%3A%s&page=%d`(v_period,
				i + 1);
		writeln("url=", url);
		string html = cast(string) get(url);
		auto document = new Document();
		document.parseGarbage(html);
		Element[] elems = document.getElementsByClassName(`searchResult`);
		writeln(elems.length);
		if (!elems.length)
			break;
		foreach (ref elem; elems)
		{
			QPost post;
			post.uuid = elem.getAttribute(`data-uuid`);
			post.favCount = to!long(elem.getElementsByClassName(
					`searchResult_statusList`)[0].innerText.strip);
			post.title = elem.requireSelector(`.searchResult_itemTitle`).innerText;
			post.href = elem.getElementsByClassName(`searchResult_itemTitle`)[0].requireSelector("a")
				.getAttribute("href");
			post.header = elem.getElementsByClassName(`searchResult_header`)[0].innerText;
			/+
			auto re = regex(` posted at ([a-zA-Z]+ [0-9]+, [0-9]+)$`);
			auto m = matchFirst(post.header, re);
			if (!m)
			{
				post.postDate = ``;
			}
			else
			{
				auto v_date = parse(m[1]);
				post.postDate = format!`%04d-%02d-%02d`(v_date.year, v_date.month, v_date.day);
			}
			+/
			post.description = elem.getElementsByClassName(`searchResult_snippet`)[0].innerText;
			string[] tag_array;
			foreach (ref tag; elem.getElementsByClassName(`tagList_item`))
			{
				//writefln("tag=%s", tag.innerText);
				tag_array ~= tag.innerText;
			}
			post.tags = tag_array.join(`|`);
			posts ~= post;
		}
	}
	Json newJsonValue = Json.emptyArray;
	foreach (post; posts)
	{
		writefln(`[%s: handle_one_day_2(): uuid=%s]`, v_period, post.uuid);
		auto http = new C_QiitaApiServie();
		string url = format!`http://qiita.com/api/v2/items/%s`(post.uuid);
		int rc = http.get(url);
		if (rc != 0)
		{
			writefln(`http://qiita.com%s  %s`, post.href, post.title);
			if (http.http.statusLine.code == 403)
			{
				writeln(cast(string) http.http.data);
				sleepForSeconds(10);
			}
			continue;
		}
		//writefln(`http.http.statusLine.code=%d`, http.http.statusLine.code);
		//writeln(cast(string) http.http.data);
		string check_time = ql_systime_to_string(Clock.currTime());
		http.jsonValue[`check_time`] = check_time;
		http.jsonValue[`start_time`] = g_start_time;
		http.jsonValue.remove(`body`);
		newJsonValue.appendArrayElement(http.jsonValue);
	}
	string json = newJsonValue.toPrettyString();
	Statement statement = g_db.prepare(
			"INSERT INTO qiita_posts (post_date, total_count, json) VALUES (:post_date, :total_count, :json)");
	statement.bind(":post_date", v_period);
	statement.bind(":total_count", -1);
	statement.bind(":json", json);
	statement.execute();
	statement.reset(); // Need to reset the statement after execution.
	return true;
}

void handle_range(long start, long end)
{
	string url = format!`https://qiita.com/search?sort=created&q=stocks%%3A>%%3D%d+stocks%%3A<%%3D%d`(
			start, end);
	writeln("url=", url);
	string html = cast(string) get(url);
	auto document = new Document();
	document.parseGarbage(html);
	Element[] elems = document.getElementsByClassName(`searchResult`);
	writefln("[%d-%d]=%d", start, end, elems.length);
}

int main(string[] args)
{
	long range_size = 100;
	long range_end_max = 7000;
	long range_end = range_end_max;
	for (;;)
	{
		long range_start = range_end - (range_size - 1);
		if (range_start <= 0)
			range_start = 1;
		writefln("%d - %d", range_start, range_end);
		handle_range(range_start, range_end);
		range_end -= range_size;
		if (range_end <= 0)
			break;
	}
	exit(0);
	return 0;
}
