import dateparser;
import jsonizer;

//import core.sync.barrier;
import core.sync.rwmutex;
import core.sync.semaphore;
import core.thread;
import core.time;
import std.array;
import std.conv;
import std.datetime;
import std.datetime.systime;
import std.file;
import std.format;
import std.json;
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

private void sleep_seconds(long secs)
{
	SysTime startTime = Clock.currTime();
	SysTime targetTime = startTime + dur!`seconds`(secs);

	int max_width = 0;
	for (;;)
	{
		SysTime currTime = Clock.currTime();
		if (currTime >= targetTime) break;
		Duration leftTime = targetTime - currTime;
		if (leftTime.total!`msecs` <= 0)
			break;
		string displayStr = format!`Sleeping: %s`(leftTime);
		if (displayStr.length > max_width)
			max_width = displayStr.length;
		while (displayStr.length < max_width)
			displayStr ~= ` `;
		//printf("%s\r", cast(char*) toStringz(displayStr));
		writef("%s\r", displayStr);
		stdout.flush();
		Thread.sleep(dur!("msecs")(500));
	}
	//printf("\n");
	for (int i = 0; i < max_width; i++)
		write(` `);
	write("\r");
	write("Finished Sleeping!\n");
	stdout.flush();
}

private Database g_db;
static this()
{
	g_db = Database("___g_db.db3");
	g_db.run(`
	CREATE TABLE IF NOT EXISTS qiita_posts (
		post_date	text primary key,
		total_count	integer not null,
		json		text
	)`);
}

class C_QiitaApiHttp
{
	int code;
	string[string] headers;
	ubyte[] data;
	int get(string url)
	{
		this.code = 0;
		this.headers.clear();
		this.data.length = 0;
		auto http = HTTP(url);
		http.addRequestHeader(`Authorization`, `Bearer 06ade23e3803334f43a0671f2a7c5087305578bd`);
		http.onReceiveHeader = (in char[] key, in char[] value) {
			this.headers[key] = to!string(value);
		};
		http.onReceive = (ubyte[] bytes) {
			this.data ~= bytes;
			return bytes.length;
		};
		this.code = http.perform(No.throwOnError);
		return this.code;
	}
}

class C_QiitaApiServie
{
	C_QiitaApiHttp http;
	JSONValue jsonValue;
	long rateRemaining;
	SysTime rateResetTime;
	this()
	{
		this.http = new C_QiitaApiHttp();
	}

	~this()
	{
		delete this.http;
	}

	int get(string url)
	{
		_loop_a: for (;;)
		{
			this.jsonValue = null;
			int rc = this.http.get(url);
			if (rc != 0)
				return rc;
			this.rateRemaining = to!long(this.http.headers["rate-remaining"]);
			long v_rate_reset = to!long(this.http.headers["rate-reset"]);
			this.rateResetTime = SysTime(unixTimeToStdTime(v_rate_reset));
			//writeln(this.http.headers);
			if (this.http.headers["content-type"] != "application/json"
					&& this.http.headers["content-type"] != "application/json; charset=utf-8")
			{
				writeln(`not application/json`);
				return -1;
			}
			//JSONValue jsonObj = parseJSON(cast(char[]) this.http.data);
			this.jsonValue = parseJSON(cast(char[]) this.http.data);
			Variant v_type = getJsonObjectProp(this.jsonValue, `type`);
			if (v_type == `rate_limit_exceeded`)
			{
				writeln(`rate_limit_exceeded error!(3)`);
				//long v_rate_reset = to!long(this.http.headers["rate-reset"]);
				//writeln(v_rate_reset);
				//writeln(SysTime(unixTimeToStdTime(v_rate_reset)));
				SysTime currentTime = Clock.currTime();
				writeln(currentTime);
				//SysTime v_reset_time = SysTime(unixTimeToStdTime(v_rate_reset));
				//auto diff = v_reset_time - currentTime;
				Duration diff = this.rateResetTime - currentTime;
				writeln(diff);
				Duration diff2 = diff + dur!`seconds`(60);
				writeln(diff2);
				writeln(diff.total!"minutes");
				writeln(diff.total!"seconds");
				writeln(diff.total!"msecs");
				writeln(`Sleeping for: `, diff2);
				//Thread.sleep(diff2);
				sleep_seconds(diff2.total!`seconds`);
				continue _loop_a;
			}
			break _loop_a;
		}
		return 0;
	}
}

void handle_one_day(SysTime v_date)
{

	exit(0);
}

Variant getJsonObjectProp(ref JSONValue jsonObj, string prop_name)
{
	Variant result;
	if (jsonObj.type != JSON_TYPE.OBJECT)
		return result;
	auto member = (prop_name in jsonObj.object);
	if (!member)
		return result;
	writeln(member.type);
	switch (member.type)
	{
	case JSON_TYPE.FALSE:
		//writeln(`1`);
		result = false;
		break;
	case JSON_TYPE.TRUE:
		//writeln(`2`);
		result = true;
		break;
	case JSON_TYPE.FLOAT:
		//writeln(`3`);
		result = member.floating;
		break;
	case JSON_TYPE.INTEGER:
		//writeln(`4`);
		result = member.integer;
		//writeln(`4b`);
		break;
	case JSON_TYPE.STRING:
		//writeln(`5`);
		result = member.str;
		break;
	default:
		//writeln(`6`);
		break;
	}
	return result;
}

int main(string[] args)
{
	/+
	Duration d = dur!`hours`(2) + dur!`seconds`(1820);
	string d_s = format!`%s`(d);
	writeln(d);
	exit(0);
	+/
	//JSONValue jv = parseJSON("[]");
	JSONValue jv = parseJSON(`{"abc":123}`);
	//auto jvm = jv["xyz"];
	Variant v;
	v = getJsonObjectProp(jv, `abc`);
	writeln(v.hasValue);
	writeln(v.peek!(long));
	writeln(v.get!(double));
	writeln(v.peek!(string));
	//exit(0);
	writeln(v.type);
	writeln(typeid(int));
	writeln(v.type == typeid(long));

	const SysTime v_first_date = SysTime(DateTime(2011, 9, 16));
	SysTime v_curr_time = Clock.currTime();
	SysTime v_curr_date = SysTime(DateTime(v_curr_time.year, v_curr_time.month, v_curr_time.day));

	SysTime v_date = v_first_date;
	a: for (;;)
	{
		//writeln(v_date);
		string v_str = format!`%04d-%02d-%02d`(v_date.year, v_date.month, v_date.day);
		//writeln(v_str);
		if (v_date == v_curr_date)
			break a;
		v_date += dur!`days`(1);
	}

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
	// Get with custom data receivers
	//auto http = HTTP("http://qiita.com/api/v2/items/1a182f187fd2a8df29c2");
	auto http = HTTP("http://qiita.com/api/v2/items?query=created%3A2016-12-01&per_page=100");
	http.addRequestHeader(`Authorization`, `Bearer 06ade23e3803334f43a0671f2a7c5087305578bd`);
	long v_rate_reset = 0;
	http.onReceiveHeader = (in char[] key, in char[] value) {
		writeln(key ~ ": " ~ value);
		if (key == `rate-reset`)
		{
			v_rate_reset = to!long(value);
		}
	};
	ubyte[] bytes;
	http.onReceive = (ubyte[] data) { /+ drop +/
		writeln(`onReceive`);
		bytes ~= data;
		return data.length;
	};
	int code = http.perform(No.throwOnError);
	writeln(`code=`, code);
	Thread.sleep(dur!`msecs`(2000));

	//writeln(cast(char[]) bytes);
	JSONValue jsonObj = parseJSON(cast(char[]) bytes);
	assert(jsonObj.type == JSON_TYPE.ARRAY);
	/+
	assert(jsonObj.type == JSON_TYPE.OBJECT);
	foreach (key; jsonObj.object.keys)
	{
		writeln(key);
	}
	+/
	//writeln(jsonObj.object[`created_at`].toString);
	foreach (ref post; jsonObj.array)
	{
		assert(post.type == JSON_TYPE.OBJECT);
		post.object.remove(`body`);
		post.object.remove(`rendered_body`);
		string v_created_at = post.object[`created_at`].str;
		auto restoredTime = SysTime.fromISOExtString(v_created_at);
		writeln(v_created_at, `=`, restoredTime);
	}
	File f = File(`___temp.json`, `wb`);
	f.write(jsonObj.toPrettyString(JSONOptions.doNotEscapeSlashes));
	f.close();
	writeln(v_rate_reset);
	writeln(SysTime(unixTimeToStdTime(v_rate_reset)));
	SysTime currentTime = Clock.currTime();
	writeln(currentTime);
	SysTime v_reset_time = SysTime(unixTimeToStdTime(v_rate_reset));
	//auto diff = v_reset_time - currentTime;
	Duration diff = v_reset_time - currentTime;
	writeln(diff);
	writeln(diff.total!"minutes");
	writeln(diff.total!"seconds");
	writeln(diff.total!"msecs");

	string a = "";
	string b = null;

	writeln(a == b);

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

	return 0;
}
