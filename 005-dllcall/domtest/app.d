import arsd.dom;
import arsd.curl;

import std.stdio;

void main() {
	auto document = new Document();
	document.parseGarbage(curl("http://digitalmars.com/"));

	writeln(document.querySelector("p"));
}