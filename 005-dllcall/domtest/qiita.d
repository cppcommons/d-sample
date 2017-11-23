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

bool handle_one_day(SysTime v_date)
{
	const int per_page = 100;
	string v_period = format!`%04d-%02d-%02d`(v_date.year, v_date.month, v_date.day);

	/+
	g_db.run(`
	CREATE TABLE IF NOT EXISTS qiita_posts (
		post_date	text primary key,
		total_count	integer not null,
		json		text
	)`);
	+/
	auto count = g_db.execute(format!"SELECT count(*) FROM qiita_posts WHERE post_date == '%s'"(v_period))
		.oneValue!long;
	//writefln(`count=%d`, count);
	if (count)
	{
		Row row = g_db.execute(format!"SELECT *, rowid rid FROM qiita_posts WHERE post_date == '%s'"(v_period))
			.front();
		auto total_count2 = row["total_count"].as!long;
		auto json2 = row["json"].as!string;
		Json jsonValue = parseJsonString(cast(string) json2);
		if (jsonValue.type != Json.Type.Array)
		{
			exit(1);
		}
		if (jsonValue.length != total_count2)
		{
			//exit(1);
		}
		//writeln(json2);
		//writefln(`[%s: complete (%d)]`, v_period, total_count2);
		return true;
	}

	Json newJsonValue = Json.emptyArray;

	writefln(`[%s: page=1]`, v_period);
	auto qhttp1 = new C_QiitaApiServie();
	string url1 = format!`http://qiita.com/api/v2/items?query=created%%3A%s&per_page=%d&page=1`(
			v_period, per_page);
	int rc1 = qhttp1.get(url1);
	//writeln(rc1);
	//stdout.flush();
	if (rc1 != 0)
		return false;
	//writeln(qhttp1.http.headers);
	//stdout.flush();
	long total_count = to!long(qhttp1.http.headers[`total-count`]);
	//writeln(`total_count=`, total_count);
	//stdout.flush();

	string check_time = ql_systime_to_string(Clock.currTime());
	foreach (val1; qhttp1.jsonValue[])
	{
		val1.remove(`body`);
		val1.remove(`rendered_body`);
		val1[`check_time`] = check_time;
		newJsonValue.appendArrayElement(val1);
	}

	long page_count = (total_count + per_page - 1) / per_page;
	//writeln(`page_count=`, page_count);

	for (int page_no = 2; page_no <= page_count; page_no++)
	{
		writefln(`[%s: page=%d]`, v_period, page_no);
		auto qhttp2 = new C_QiitaApiServie();
		string url2 = format!`http://qiita.com/api/v2/items?query=created%%3A%s&per_page=%d&page=%d`(v_period,
				per_page, page_no);
		int rc2 = qhttp2.get(url2);
		//writeln(rc2);
		if (rc2 != 0)
			return false;
		check_time = ql_systime_to_string(Clock.currTime());
		foreach (val2; qhttp2.jsonValue[])
		{
			val2.remove(`body`);
			val2.remove(`rendered_body`);
			val2[`check_time`] = check_time;
			newJsonValue.appendArrayElement(val2);
		}
	}
	writeln(`newJsonValue.array.length=`, newJsonValue.array.length);
	//writefln(`qhttp1.rateRemaining=%d`, qhttp1.rateRemaining);

	version (none)
		if (newJsonValue.array.length != total_count)
		{
			writeln(`total_count=`, total_count);
			writeln(`exiting!`);
			sleepForSeconds(3);
			//writeln(cast(string)qhttp1.http.data);
			//exit(1);
			return false;
		}

	//string json = newJsonValue.serializeToJsonString();
	string json = newJsonValue.toPrettyString();

	//writeln(json);
	Statement statement = g_db.prepare(
			"INSERT INTO qiita_posts (post_date, total_count, json) VALUES (:post_date, :total_count, :json)");

	// Bind values one by one (by parameter name or index)
	statement.bind(":post_date", v_period);
	statement.bind(":total_count", total_count);
	statement.bind(":json", json);
	statement.execute();
	statement.reset(); // Need to reset the statement after execution.
	version (none)
	{
		auto rowid = g_db.execute("SELECT last_insert_rowid()").oneValue!long;
		writeln("rowid=", rowid);
	}
	version (none)
	{
		ResultRange results = g_db.execute(
				format!"SELECT *, rowid rid FROM qiita_posts WHERE post_date == '%s'"(v_period));
		foreach (Row row; results)
		{
			auto json2 = row["json"].as!string;
			writeln(json2);
			exit(0);
		}
	}

	return true;
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

int main(string[] args)
{
	//write("\a");
	//stdout.flush();
	//exit(0);
	const SysTime v_first_date = SysTime(DateTime(2011, 9, 16));
	//const SysTime v_first_date = SysTime(DateTime(2016, 9, 16));
	SysTime v_curr_time = Clock.currTime();
	SysTime v_curr_date = SysTime(DateTime(v_curr_time.year, v_curr_time.month, v_curr_time.day));

	SysTime v_date = v_first_date;
	a: for (;;)
	{
		//bool jmp = true;
		//if (jmp)
		//	break;
		//writeln(v_date);
		string v_str = format!`%04d-%02d-%02d`(v_date.year, v_date.month, v_date.day);
		//writeln(v_str);
		if (!handle_one_day(v_date))
			handle_one_day_2(v_date);
		if (v_date == v_curr_date)
			break a;
		v_date += dur!`days`(1);
	}
	long count = 0;
	ResultRange results = g_db.execute("SELECT *, rowid rid FROM qiita_posts ORDER BY post_date");
	foreach (Row row; results)
	{
		auto post_date = row["post_date"].as!string;
		writeln(post_date);
		auto json = row["json"].as!string;
		Json jsonValue = parseJsonString(json);
		Json*[] reverse_array;
		foreach (ref rec; jsonValue[])
		{
			reverse_array ~= &rec;
		}
		//reverse(reverse_array);
		bool myComp(Json* x, Json* y)
		{
			return (*x)[`created_at`].get!string < (*y)[`created_at`].get!string;
		}

		sort!myComp(reverse_array);
		foreach (ref rec; reverse_array)
		{
			count++;
			//writeln(rec.toPrettyString);
			writefln("%08d %s: %s %s", count, post_date, (*rec)[`created_at`], (*rec)[`title`]);
			writeln(dateparser.parse((*rec)[`created_at`].get!string));
		}
		//writeln(json[0 .. 40]);
	}

	/+
{
        "reactions_count": 0,
        "comments_count": 0,
        "url": "http://qiita.com/shinofara/items/381c8f57bf39c52d240a",
        "group": null,
        "created_at": "2013-03-20T01:44:54+09:00",
        "likes_count": 11,
        "title": "シェルスクリプトで、マルチスレッド処理風実装",
        "tags": [
                {
                        "name": "shell",
                        "versions": []
                }
        ],
        "id": "381c8f57bf39c52d240a",
        "updated_at": "2013-03-20T01:58:35+09:00",
        "coediting": false,
        "private": false,
        "user": {
                "github_login_name": "shinofara",
                "twitter_screen_name": "shinofara",
                "description": "work:\r\nEmacs/VisualStudioCode\r\nGolang/PHP/Pyhton/Shell\r\nAWS/Docker/VirtualBox/Mac\r\nVagrant/Terraform
/Packer/Ansible\r\nOSS/LT\r\n\r\nlike:\r\nPhoto/Diving/Snowboard\r\n\r\nhistory:\r\nY! -> schoo -> Y! -> MedPeer",
                "items_count": 62,
                "followees_count": 6,
                "followers_count": 37,
                "name": "しのふぁら",
                "organization": "メドピア",
                "profile_image_url": "https://qiita-image-store.s3.amazonaws.com/0/8529/profile-images/1473681060",
                "website_url": "https://log.shinofara.xyz/",
                "facebook_id": "shinofara",
                "id": "shinofara",
                "linkedin_id": "yuki-shinohara-a4476060",
                "location": "Tokyo",
                "permanent_id": 8529
        }
}
^CTerminate batch job (Y/N)? y+/

	exit(0);

	/+
	_loop_a: for (int i = 0; i < 2000; i++)
	{
		auto qhttp = new C_QiitaApiServie();
		int rc = qhttp.get("http://qiita.com/api/v2/items?query=created%3A2016-12-01&per_page=10");
		writeln(rc);
		stdout.flush();
		if (rc != 0)
			break _loop_a;
		writefln(`i=%d`, i);
		stdout.flush();
		writeln(qhttp.http.headers);
		stdout.flush();
		writeln(`qhttp.rateRemaining=`, qhttp.rateRemaining);
		writeln(`qhttp.rateResetTime=`, qhttp.rateResetTime);
	}

	exit(0);
	+/

	/+
	writeln("start!スタート!");
	// Open a database in memory.
	//auto db = Database(":memory:");
	auto db = Database("___test.db3");

	// Create a table
	db.run("DROP TABLE IF EXISTS person;
        CREATE TABLE person (
          id    INTEGER PRIMARY KEY,
          name  TEXT NOT NULL,
          score FLOAT
        )");

	// Prepare an INSERT statement
	Statement statement = db.prepare("INSERT INTO person (name, score)
     VALUES (:name, :score)");

	// Bind values one by one (by parameter name or index)
	statement.bind(":name", "John");
	statement.bind(2, 77.5);
	statement.execute();
	statement.reset(); // Need to reset the statement after execution.
	auto rowid = db.execute("SELECT last_insert_rowid()").oneValue!long;
	writeln("rowid=", rowid);
	Statement statement2 = db.prepare("SELECT name FROM person WHERE rowid == :rowid");
	statement2.bind(":rowid", rowid);
	auto name1 = statement2.execute().oneValue!string;
	writeln("name1=", name1);

	// Bind muliple values at the same time
	statement.bindAll("John", null);
	statement.execute();
	statement.reset();
	auto rowid2 = db.execute("SELECT last_insert_rowid()").oneValue!long;
	writeln("rowid=", rowid2);

	// Bind, execute and reset in one call
	statement.inject("Clara", 88.1);
	auto rowid3 = db.execute("SELECT last_insert_rowid()").oneValue!long;
	writeln("rowid=", rowid3);

	// Count the changes
	assert(db.totalChanges == 3);

	// Count the Johns in the table.
	auto count = db.execute("SELECT count(*) FROM person WHERE name == 'John'").oneValue!long;
	assert(count == 2);

	// Read the data from the table lazily
	ResultRange results = db.execute("SELECT *, rowid rid FROM person");
	foreach (Row row; results)
	{
		// Retrieve "id", which is the column at index 0, and contains an int,
		// e.g. using the peek function (best performance).
		auto id = row.peek!long(0);

		// Retrieve "name", e.g. using opIndex(string), which returns a ColumnData.
		auto name = row["name"].as!string;
		writeln(name);

		auto rowidx = row["rid"].as!ulong;
		writeln(rowidx);
		// Retrieve "score", which is at index 2, e.g. using the peek function,
		// using a Nullable type
		//auto score = row.peek!(Nullable!double)(2);
		auto score = row["score"].as!(Nullable!double);
		//score2.nullify();
		if (!score.isNull)
		{
			writeln(score);
		}
		else
		{
			writeln("<NULL>");
		}
	}
	+/
	return 0;
}
