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
	f.writeln(`<p><i><img width="16" height="16" src="thumb-up-120px.png" /></i>が同じ値の場合は投稿日時の新しいものが上位としています。</p>`);
	for (int i = 0; i < min(records.length, 100); i++)
	{
		Json* rec = &records[i];
		writeln((*rec).serializeToJsonString);
		writeln((*rec)[`title`].get!string);
		writeln((*rec)[`likes_count`].get!long);
		string user_id = (*rec)[`user`][`id`].get!string;
		//string user_org = (*rec)[`user`][`organization`].get!string;
		Json user_org_node = (*rec)[`user`][`organization`];
		string user_org = "";
		if (user_org_node.type == Json.Type.String)
			user_org = user_org_node.get!string;
		if (user_id == "Qiita") user_org = ``;
		if (user_id == "javacommons") user_org = ``;
		if (!user_org.empty) user_org = `<br />(` ~ user_org ~ ` 所属)`;
		Json[] tags = (*rec)[`tags`].get!(Json[]);
		string tags_html = ``;
		foreach (ref tag; tags)
		{
			tags_html ~= `<b>[` ~ tag[`name`].get!string ~ `]</b> `;
		}
		//f.write(std.xml.encode((*rec)[`title`].get!string));
		f.writeln(format!`<table border="1">
<tr>
	<td rowspan="3">%d位</td>
	<td colspan="3">
		<a target="_blank" href="%s">%s</a>
		<i><img alt="いいね" width="16" height="16" src="thumb-up-120px.png" /></i>%d
	</td>
</tr>
<tr>
	<td>投稿日時</td>
	<td>投稿者</td>
	<td>タグ</td>
</tr>
<tr>
	<td>%s<!--投稿日時--></td>
	<td>
		@<a target="_blank" href="http://qiita.com/%s">%s</a>%s<br><img width="80" height="80" src="%s">
	</td>
	<td>%s<!--タグ--></td>
</tr>
</table>`(i + 1, //
				(*rec)[`url`].get!string, //
				std.xml.encode((*rec)[`title`].get!string), //
				(*rec)[`likes_count`].get!long, //
				(*rec)[`created_at`].get!string.replace(`T`, ` `)
				.replace(`+09:00`, ``), //
				user_id, //
				user_id, //
				user_org, //
				(*rec)[`user`][`profile_image_url`].get!string, //
				tags_html));
		f.writeln("<br />");
	}
	f.writeln("	</body>");
	f.writeln("</html>");
	f.close();
	exit(0);
	return 0;
}
