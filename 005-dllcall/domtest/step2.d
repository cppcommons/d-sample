import qiitadb;
import d2sqlite3, std.typecons : Nullable;

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

__gshared static Database db1;
shared static this()
{
	/*Database*/ db1 = ql_get_db_1(`___db1.db3`);
}

int main(string[] args)
{
	doIt("___j_like_over_50_2.txt", "SELECT json FROM qiita WHERE likes_count >= 50 ORDER BY likes_count desc");
	doIt("___j_like_over_50_Ruby.txt",
	 `SELECT json FROM qiita WHERE tags like "%<Ruby>%" AND likes_count >= 50 ORDER BY likes_count desc`);
	exit(0);
	return 0;
}

void doIt(string fileName, string sql)
{
	File f = File(fileName, "w");
	f.write("[");
	long count = 0;
	ResultRange results = db1.execute(sql);
	foreach (Row row; results)
	{
		if (count > 0)
			f.write(",\n ");
		count++;
		auto json = row["json"].as!string;
		f.write(json);
	}
	f.write("]");
	f.write("\n");
	f.close();
}
