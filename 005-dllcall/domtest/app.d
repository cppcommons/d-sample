import arsd.dom;
import arsd.curl;

import std.stdio;

void main()
{
	string html = curl("https://qiita.com/search?sort=created&q=created%3A2016-12");
	writeln(html);
	auto document = new Document();
	document.parseGarbage(html);
	writeln(document.querySelector("p"));
	Element[] elems = document.getElementsByClassName(`searchResult`);
	writeln(elems.length);
	foreach(ref elem; elems)
	{
		writeln(elem.outerHTML);
		writeln();
		writeln(`data-uuid=`, elem.getAttribute(`data-uuid`));
		writeln(elem.getElementsByClassName(`searchResult_itemTitle`)[0].innerText);
		writeln();
	}
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
