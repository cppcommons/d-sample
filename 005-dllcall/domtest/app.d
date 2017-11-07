import arsd.dom;
import dateparser;

//import easy.windows.std.net.curl;
import std.net.curl;
import jsonizer;
import std.array;
import std.conv;
import std.datetime;
import std.file;
import std.format;
import std.json;
import std.path;
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
	}
}

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

void write_post_list_to_file(string path, ref QPost[] posts)
{
	prepare_for_wite_path(path);
	auto f = File(path, "wb");
	string json = toJSON(posts).toPrettyString(JSONOptions.doNotEscapeSlashes);
	f.rawWrite(json);
	f.close();
}

int main(string[] args)
{
	writeln(`1`);
	assert(parse("2003-09-25") == SysTime(DateTime(2003, 9, 25)));
	assert(parse("09/25/2003") == SysTime(DateTime(2003, 9, 25)));
	assert(parse("Sep 2003") == SysTime(DateTime(2003, 9, 1)));
	assert(parse("Jan 01, 2017") == SysTime(DateTime(2017, 1, 1)));

	writeln(args);

	if (args.length != 2)
	{
		return 1;
	}

	//string target_period = `2016-12`;
	string target_period = `2017-11`;
	string file_name = `___monthly-data-` ~ target_period ~ `.json`;
	if (exists(file_name))
	{
		writefln(`%s exists!`, file_name);
		return 0;
	}
	/+
	S s = {1, 1.23f};
	writeln(toJSON(s));
	S[] list;
	list ~= s;
	list ~= s;
	writeln(toJSON(list));
	JSONValue json = toJSON(list);
	S[] list2 = json.fromJSON!(S[]);
	writeln(list2);
	+/
	QPost[] posts;
	for (int i = 0; i < int.max; i++)
	{
		string url = format!`https://qiita.com/search?sort=created&q=created%%3A%s&page=%d`(
				target_period, i + 1);
		writeln("url=", url);
		//stdout.flush();
		string html = cast(string) get( //"https://qiita.com/search?sort=created&q=created%3A2016-12&page=1"
				//format!`https://qiita.com/search?sort=created&q=created%%3A2016-12&page=%d`(i + 1)
				url);
		//writeln(html);
		auto document = new Document();
		document.parseGarbage(html);
		//writeln(document.querySelector("p"));
		Element[] elems = document.getElementsByClassName(`searchResult`);
		writeln(elems.length);
		//stdout.flush();
		if (!elems.length)
			break;
		//writeln("i+1=", i + 1);
		//stdout.flush();
		//QPost[] posts;
		foreach (ref elem; elems)
		{
			QPost post;
			//writeln(elem.outerHTML);
			post.uuid = elem.getAttribute(`data-uuid`);
			post.favCount = to!long(elem.getElementsByClassName(
					`searchResult_statusList`)[0].innerText.strip);
			//post.title = elem.getElementsByClassName(`searchResult_itemTitle`)[0].innerText;
			post.title = elem.requireSelector(`.searchResult_itemTitle`).innerText;
			post.href = elem.getElementsByClassName(`searchResult_itemTitle`)[0].requireSelector("a")
				.getAttribute("href");
			post.header = elem.getElementsByClassName(`searchResult_header`)[0].innerText;
			post.description = elem.getElementsByClassName(`searchResult_snippet`)[0].innerText;
			string[] tag_array;
			foreach (ref tag; elem.getElementsByClassName(`tagList_item`))
			{
				//writefln("tag=%s", tag.innerText);
				tag_array ~= tag.innerText;
			}
			post.tags = tag_array.join(`|`);
			posts ~= post;
			writefln(`%d: post.title=%s (%d) %s`, i + 1, post.title, post.favCount, post.header);
			stdout.flush();
			//handle_revisions(post);
		}
		//writeln(toJSON(posts).toPrettyString(JSONOptions.doNotEscapeSlashes));
		//stdout.flush();
	}
	write_post_list_to_file(file_name, posts);
	return 0;
}

