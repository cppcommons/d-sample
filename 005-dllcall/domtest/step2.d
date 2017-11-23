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
	v_start = Clock.currTime();
	write("Parsing JSON...");
	stdout.flush();
	Json[] records = parseJsonString(json).get!(Json[]);
	//Duration v_duration = Clock.currTime() - v_start;
	writeln(Clock.currTime() - v_start);
	//f.write(outrec.serializeToJsonString);
	writeln(records.length);
	v_start = Clock.currTime();
	write("Sorting Records...");
	stdout.flush();
	Json*[] reverse_array;
	foreach (ref rec; records)
	{
		reverse_array ~= &rec;
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
	for (int i=0; i<min(reverse_array.length, 20); i++)
	{
		Json *rec = reverse_array[i];
		writeln((*rec).serializeToJsonString);
	}
	exit(0);

	return 0;
}
