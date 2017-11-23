import dateparser;
import vibe.data.json, vibe.data.serialization;
import core.time;
import std.algorithm;
import std.algorithm.comparison;
import std.algorithm.sorting;
import std.array;
import std.conv;
import std.datetime;
import std.datetime.systime;
import std.file;
import std.format;
import std.path;
import std.stdio;
import std.string;
import std.variant;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

int main(string[] args)
{
	//File f = File("___g_total.txt", "r");
	writeln("Reading JSON...");
	string json = cast(string) read("___g_total.txt");
	SysTime v_start;
	writeln("Reading JSON...done!");

	import std.json;
	v_start = Clock.currTime();
	write("Parsing JSON(1)...");
	stdout.flush();
	JSONValue j = parseJSON(json);
	writeln(Clock.currTime() - v_start);

	v_start = Clock.currTime();
	write("Parsing JSON...");
	stdout.flush();
	Json[] records = parseJsonString(json).get!(Json[]);
	writeln(Clock.currTime() - v_start);

	writeln(records.length);

	v_start = Clock.currTime();
	write("Sorting Records...");
	stdout.flush();
	Json*[] reverse_array;
	long liked_count = 0;
	foreach (ref rec; records)
	{
		if (rec[`likes_count`].get!long < 50)
			continue;
		reverse_array ~= &rec;
		/+
		if (rec[`likes_count`].get!long >= 50)
		{
			liked_count++;
		}
		+/
	}
	//reverse(reverse_array);
	bool myComp(Json* x, Json* y)
	{
		if ((*x)[`likes_count`].get!long != (*y)[`likes_count`].get!long)
		{
			return (*x)[`likes_count`].get!long > (*y)[`likes_count`].get!long;
		}
		return (*x)[`created_at`].get!string > (*y)[`created_at`].get!string;
	}

	sort!myComp(reverse_array);
	writeln(Clock.currTime() - v_start);
	for (int i = 0; i < min(reverse_array.length, 20); i++)
	{
		Json* rec = reverse_array[i];
		writeln((*rec).serializeToJsonString);
	}
	writeln(reverse_array.length);

	Json jsonObj = Json.emptyArray;
	foreach (rec; reverse_array)
	{
		jsonObj.appendArrayElement(*rec);
	}

	assert(jsonObj.type == Json.Type.Array);
	Json[] elems = jsonObj.get!(Json[]);
	File f = File("___j_like_over_50.txt", "w");
	f.write("[");
	long count = 0;
	foreach (ref elem; elems)
	{
		if (count > 0)
			f.write(",\n ");
		count++;
		f.write(elem.serializeToJsonString);
	}
	f.write("]");
	f.write("\n");
	f.close();

	exit(0);

	return 0;
}
