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
import std.xml;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

int main(string[] args)
{
	//File f = File("___g_total.txt", "r");
	writeln("Reading JSON...");
	string json = cast(string) read("___j_like_over_50.txt");
	SysTime v_start;
	writeln("Reading JSON...done!");
	v_start = Clock.currTime();
	write("Parsing JSON...");
	stdout.flush();
	Json[] records = parseJsonString(json).get!(Json[]);
	writeln(Clock.currTime() - v_start);
	writeln(records.length);

	File f = File("qranking.github.io/index.html", "wb");
	f.writeln("<html>");
	f.writeln(`	<head><meta charset="UTF-8" /><title>Ranking Test</title></head>`);
	f.writeln("	<body>");
	f.writeln(`<h1>対象記事件数: 222,355件 (2011/09/16～2017/05/24)</h1>`);
	f.writeln(
			`<p><i>いいね</i>が同じ値の場合は投稿日時の新しいものが上位としています。</p>`);
	for (int i = 0; i < min(records.length, 20); i++)
	{
		Json* rec = &records[i];
		writeln((*rec).serializeToJsonString);
		writeln((*rec)[`title`].get!string);
		writeln((*rec)[`likes_count`].get!long);
		f.write(std.xml.encode((*rec)[`title`].get!string));
		f.writeln(format!`<table border="1">
<tr>
<td rowspan="3">%d位</td>
<td colspan="3">
<a href="%s" target="_blank">%s</a> <kbd><i></i>%d</kbd> (+106)
</td>
</tr>
<tr>
<td>投稿日</td>
<td>投稿者</td>
<td>タグ</td>
</tr>
<tr>
<td>%s</td>
<td>@<a href="http://qiita.com/koher">koher<br><img width="80" height="80" src="%s"></a>
</td>
<td>
<b>[Kotlin]</b> <b>[Java]</b> <b>[Android]</b>
</td>
</tr>
</table>`(i + 1,
				(*rec)[`url`].get!string, std.xml.encode((*rec)[`title`].get!string),
				(*rec)[`likes_count`].get!long, (*rec)[`created_at`].get!string,
				(*rec)[`user`][`profile_image_url`].get!string));
		f.writeln("<br />");
	}
	f.writeln("	</body>");
	f.writeln("</html>");
	f.close();
	exit(0);
	return 0;
}
