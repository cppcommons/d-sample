import dateparser;
import std.net.curl;
import jsonizer;
import std.array;
import std.conv;
import std.datetime;
import std.file;
import std.format;
import std.json;
import std.path;
import std.regex;
import std.stdio;
import std.string;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

struct QPost
{
	mixin JsonizeMe; // this is required to support jsonization
	@jsonize
	{
		string uuid;
		long favCount;
		string title;
		string href;
		string header;
		string description;
		string tags;
		string postDate;
	}
}

version (TEST1) int main(string[] args)
{
	// "2011/09/16"
	version (none)
	{
		const short year0 = 2011;
		const ubyte month0 = 9;
	}
	else
	{
		const short year0 = 2016;
		const ubyte month0 = 9;
	}
	SysTime v_date = Clock.currTime();
	assert(v_date >= SysTime(DateTime(year0, month0, 1)));
	string v_str = format!`%04d-%02d-%02d`(v_date.year, v_date.month, v_date.day);
	writeln(v_str);
	a: for (short year = year0; year <= short.max; year++)
	{
		b: for (Month month = Month.jan; month <= Month.dec; month++)
		{
			if (year == year0 && month < month0)
				continue;
			writefln(`year=%d month=%u`, year, month);
			if (year == v_date.year && month == v_date.month)
				break a;
		}
	}
	return 0;
}
