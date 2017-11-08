//import arsd.dom;
import vibe.data.json;
import dateparser;

//import easy.windows.std.net.curl;
import std.net.curl;
import std.array;
import std.conv;
import std.datetime;
import std.file;
import std.format;

//import std.json;
import std.path;
import std.regex;
import std.stdio;
import std.string;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

/+
struct S
{
	mixin JsonizeMe; // this is required to support jsonization
	@jsonize
	{ // public serialized members
		int x;
		float f;
	}
	string dontJsonMe; // jsonizer won't touch members not marked with @jsonize
}
+/

void prepare_for_wite_path(string path)
{
	string abs_path = absolutePath(path);
	string dir_path = dirName(abs_path);
	mkdirRecurse(dir_path);
	try
	{
		auto currentTime = Clock.currTime();
		setTimes(dir_path, currentTime, currentTime);
	}
	catch (Exception ex)
	{
	}
}

int main(string[] args)
{
	writeln(`1`);
	assert(parse("2003-09-25") == SysTime(DateTime(2003, 9, 25)));
	assert(parse("09/25/2003") == SysTime(DateTime(2003, 9, 25)));
	assert(parse("Sep 2003") == SysTime(DateTime(2003, 9, 1)));
	assert(parse("Jan 01, 2017") == SysTime(DateTime(2017, 1, 1)));

	//auto v_date = parse("Jan 23, 2017");
	//writefln(`%d/%d/%d`, v_date.year, v_date.month, v_date.day);
	Json j1 = Json(["field1" : Json("foo"), "field2" : Json(42), "field3" : Json(true)]);

	// using piecewise construction
	Json j2 = Json.emptyObject;
	j2["field1"] = "foo";
	j2["field2"] = 42.0;
	j2["field3"] = true;

	// using serialization
	struct S
	{
		string field1;
		double field2;
		bool field3;
	}

	Json j3 = S("foo", 42, true).serializeToJson();

	// using serialization, converting directly to a JSON string
	string j4 = S("foo", 32, true).serializeToJsonString();

	writeln(j4);

	Json x = parseJsonString("{ \"abc\": \"x\tyz\"}");
	writeln(x.serializeToJsonString());
	return 0;
}
