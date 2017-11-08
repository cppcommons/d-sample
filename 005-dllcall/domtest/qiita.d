import dateparser;
import jsonizer;

//import core.sync.barrier;
import core.sync.rwmutex;
import core.sync.semaphore;
import core.thread;
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

import d2sqlite3;
import std.typecons : Nullable;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

int main(string[] args)
{
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
	http.perform();

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
