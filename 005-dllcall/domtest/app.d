import arsd.dom;
import dateparser;
import easy.windows.std.net.curl;
import jsonizer;
import std.array;
import std.conv;
import std.datetime;
import std.json;
import std.stdio;
import std.string;

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

void main()
{
	assert(parse("2003-09-25") == SysTime(DateTime(2003, 9, 25)));
	assert(parse("09/25/2003") == SysTime(DateTime(2003, 9, 25)));
	assert(parse("Sep 2003") == SysTime(DateTime(2003, 9, 1)));
	assert(parse("Jan 01, 2017") == SysTime(DateTime(2017, 1, 1)));

	S s = {1, 1.23f};
	writeln(toJSON(s));
	S[] list;
	list ~= s;
	list ~= s;
	writeln(toJSON(list));
	JSONValue json = toJSON(list);
	S[] list2 = json.fromJSON!(S[]);
	writeln(list2);
	//string html = curl("https://qiita.com/search?sort=created&q=created%3A2016-12");
	string html = cast(string) get("https://qiita.com/search?sort=created&q=created%3A2016-12");
	//writeln(html);
	auto document = new Document();
	document.parseGarbage(html);
	writeln(document.querySelector("p"));
	Element[] elems = document.getElementsByClassName(`searchResult`);
	writeln(elems.length);
	JSONValue array = parseJSON(`[]`);
	QPost[] posts;
	foreach (ref elem; elems)
	{
		QPost post;
		//writeln(elem.outerHTML);
		JSONValue rec = parseJSON(`{}`);
		rec.object["data-uuid"] = elem.getAttribute(`data-uuid`);
		post.uuid = elem.getAttribute(`data-uuid`);
		post.favCount = to!long(elem.getElementsByClassName(
				`searchResult_statusList`)[0].innerText.strip);
		rec.object["fav-count"] = to!long(elem.getElementsByClassName(
				`searchResult_statusList`)[0].innerText.strip);
		post.title = elem.getElementsByClassName(`searchResult_itemTitle`)[0].innerText;
		rec.object["title"] = elem.getElementsByClassName(`searchResult_itemTitle`)[0].innerText;
		post.href = elem.getElementsByClassName(
				`searchResult_itemTitle`)[0].requireSelector("a").getAttribute("href");
		rec.object["href"] = elem.getElementsByClassName(
				`searchResult_itemTitle`)[0].requireSelector("a").getAttribute("href");
		post.header = elem.getElementsByClassName(`searchResult_header`)[0].innerText;
		rec.object["header"] = elem.getElementsByClassName(`searchResult_header`)[0].innerText;
		post.description = elem.getElementsByClassName(`searchResult_snippet`)[0].innerText;
		rec.object["description"] = elem.getElementsByClassName(
				`searchResult_snippet`)[0].innerText;
		string[] tag_array;
		foreach (ref tag; elem.getElementsByClassName(`tagList_item`))
		{
			writefln("tag=%s", tag.innerText);
			tag_array ~= tag.innerText;
		}
		post.tags = tag_array.join(`|`);
		rec.object["tags"] = tag_array.join(`|`);
		posts ~= post;
		array.array ~= rec;
		writeln();
	}
	writeln(array.toPrettyString(JSONOptions.doNotEscapeSlashes));
	writeln(toJSON(posts).toPrettyString(JSONOptions.doNotEscapeSlashes));
}

version (none) void main()
{
	auto document = new Document();
	// The example document will be defined inline here
	// We could also load the string from a file with
	// std.file.readText or the web with std.net.curl.get
	document.parseGarbage(`<html><head>
     <meta name="author" content="Adam D. Ruppe">
     <title>Test Document</title>
   </head>
   <body>
     <p>This is the first paragraph of our <a
href="test.html">test document</a>.
     <p>This second paragraph also has a <a
href="test2.html">link</a>.
     <p id="custom-paragraph">Old text</p>
   </body>
   </html>`);
	import std.stdio;

	// retrieve and print some meta information
	writeln(document.title);
	writeln(document.getMeta("author"));
	// show a paragraphâs text
	writeln(document.requireSelector("p").innerText);
	// modify all links
	document["a[href]"].setValue("source", "your-site");
	// change some html
	document.requireElementById("custom-paragraph").innerHTML = "New <b>HTML</b>!";
	// show the new document
	writeln(document.toString());
}
