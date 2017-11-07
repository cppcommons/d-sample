import dateparser;
import jsonizer;

//import core.sync.barrier;
import core.sync.rwmutex;
import core.sync.semaphore;
import core.thread;
import std.array;
import std.conv;
import std.datetime;
import std.file;
import std.format;
import std.json;
import std.net.curl;
import std.path;
import std.process;
import std.regex;
import std.stdio;
import std.string;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

int main(string[] args)
{
	// Get with custom data receivers
	auto http = HTTP("http://qiita.com/api/v2/items/1a182f187fd2a8df29c2");
	http.addRequestHeader(`Authorization`, `Bearer 06ade23e3803334f43a0671f2a7c5087305578bd`);
	http.onReceiveHeader = (in char[] key, in char[] value) {
		writeln(key ~ ": " ~ value);
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
	assert(jsonObj.type == JSON_TYPE.OBJECT);
	foreach(key; jsonObj.object.keys)
	{
		writeln(key);
	}
	writeln(jsonObj.object[`created_at`].toString);
	return 0;
}
