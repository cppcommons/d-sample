import qiitalib;
import qiitadb, ddbc, hibernated.core;

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

__gshared static
{
	Session g_Session;
	Connection g_Conn;
	ddbc.Statement g_Statement;

}

shared static ~this()
{
	g_Statement.close();
	g_Session.close();
}

shared static this()
{
	g_Session = g_SessionFactory.openSession();
	g_Conn = (cast(SessionImpl) g_Session).conn;
	g_Statement = g_Conn.createStatement();
}

int main(string[] args)
{
	Query q = g_Session.createQuery(
			"FROM Qiita WHERE likes_count >= 50 ORDER BY likes_count desc, created_at desc");
	Qiita[] rows = q.list!Qiita();
	Json[] records;
	foreach (row; rows)
	{
		string json = row.json;
		records ~= parseJsonString(json);
	}
	/+
	ResultRange results = db1.execute(
			`SELECT json FROM qiita WHERE likes_count >= 50 ORDER BY likes_count desc, created_at desc`);
	Json[] records;
	foreach (Row row; results)
	{
		string json = row["json"].as!string;
		records ~= parseJsonString(json);
	}
	+/

	//long max_count = 5000;
	//long max_count = 1000;
	long max_count = 100;
	//long max_count = 2;

	File f = File(format!"qranking.github.io/top-%d.html"(max_count), "wb");
	f.writeln("<html>");
	f.writefln(`	<head>%s
		<meta charset="UTF-8" />
		<title>Qiita Ranking</title>
		<link rel="stylesheet" type="text/css" href="qranking.css">
	</head>`, ql_html_head_insert);
	f.writeln("	<body>");
	f.writeln(`<div class="headerContainer">`);
	f.writeln(format!`<h1>Qiitaいいね数ランキング (%d位まで)</h1>`(max_count));
	f.writeln(`<h2>対象記事件数: 222,355件 (2011/09/16～2017/11/23)</h2>`);
	f.writeln(`</div><!--class="headerContainer"-->`);
	f.writeln(`<p>ランキングは毎日更新します。</p>`);
	f.writeln(`<p><i><img width="16" height="16" src="thumb-up-120px.png" /></i>が同じ値の場合は投稿日時の新しいものが上位としています。</p>`);
	for (int i = 0; i < min(records.length, max_count); i++)
	{
		writeln(i + 1, "/", min(records.length, max_count));
		Json* rec = &records[i];
		//writeln((*rec).serializeToJsonString);
		//writeln((*rec)[`title`].get!string);
		//writeln((*rec)[`likes_count`].get!long);
		string user_id = (*rec)[`user`][`id`].get!string;
		long user_permanent_id = (*rec)[`user`][`permanent_id`].get!long;
		create_user_page(user_id, user_permanent_id /+, records+/ );
		long user_item_count = (*rec)[`user`][`items_count`].get!long;
		Json user_org_node = (*rec)[`user`][`organization`];
		string user_org = (*rec)[`user`][`organization`].get!string;
		//string user_org = "";
		//if (user_org_node.type == Json.Type.String)
		//	user_org = user_org_node.get!string;
		/+
		if (user_id == "Qiita")
			user_org = ``;
		if (user_id == "javacommons")
			user_org = ``;
		+/
		if (!user_org.empty)
			user_org = `<br />(` ~ user_org ~ ` 所属)`;
		Json[] tags = (*rec)[`tags`].get!(Json[]);
		string tags_html = ``;
		foreach (ref tag; tags)
		{
			tags_html ~= `<b>[` ~ tag[`name`].get!string ~ `]</b> `;
		}
		//f.write(std.xml.encode((*rec)[`title`].get!string));
		f.writeln(format!`<table border="1" style="height:150px;">
<tr>
	<td rowspan="3">%d位</td>
	<td colspan="4">
		<kbd><i><img alt="いいね" width="16" height="16" src="thumb-up-120px.png" /></i>%d</kbd>
		<a target="_blank" href="%s">%s</a>
	</td>
</tr>
<tr>
	<td style="width:100px;"><center>投稿日時</center></td>
	<td style="width:200px;"><center>投稿者</center></td>
	<td style="width:150px;"><center>タグ</center></td>
	<td style="width:350px;"><center>本文</center></td>
</tr>
<tr>
	<td style="width:100px;">
		<!--投稿日時--><center>%s</center>
	</td>
	<td style="width:200px;">
		<!--投稿者-->
		<center>
			@<a href="user/%s.html">%s</a>(%d件の記事)%s<br><img width="80" height="80" src="%s">
		</center>
	</td>
	<td style="width:150px;">
		<!--タグ-->
		<center>%s</center>
	</td>
	<td style="width:350px;">
		<!--本文-->
		<div style="width:350px;height:150px;overflow-x:hidden;overflow-y:scroll;">%s</div>
	</td>
</tr>
</table>`(i + 1, //
				(*rec)[`likes_count`].get!long, //
				(*rec)[`url`].get!string, //
				std.xml.encode((*rec)[`title`].get!string), //
				(*rec)[`created_at`].get!string.replace(`T`, `<br />`).replace(`+09:00`,
				``), //
				user_permanent_id, //
				user_id, //
				user_item_count, //
				user_org, //
				(*rec)[`user`][`profile_image_url`].get!string, //
				tags_html,
				//std.xml.encode((*rec)[`body`].get!string).replace("\n", `<br />`) //
				(*rec)[`rendered_body`].get!string //
				));
		f.writeln("<br />");
	}
	f.writeln("	</body>");
	f.writeln("</html>");
	f.close();
	exit(0);
	return 0;
}

void create_user_page(string target_user_id, long user_permanent_id /+, ref Json[] records0+/ )
{
	Query q = g_Session.createQuery("FROM Qiita WHERE user_id=:Id ORDER BY likes_count desc, created_at desc")
		.setParameter("Id", target_user_id);
	Qiita[] rows = q.list!Qiita();
	Json[] records;
	foreach (row; rows)
	{
		string json = row.json;
		records ~= parseJsonString(json);
	}
	/+
	ResultRange results = db1.execute(
			format!`SELECT json FROM qiita WHERE user_id="%s" ORDER BY likes_count desc, created_at desc`(
			target_user_id));
	//if (results.empty)
	//	return false;
	Json[] records;
	foreach (Row row; results)
	{
		string json = row["json"].as!string;
		records ~= parseJsonString(json);
	}
	+/
	string file_name = format!"qranking.github.io/user/%d.html"(user_permanent_id);
	if (exists(file_name))
		return;
	File f = File(file_name, "wb");
	f.writeln("<html>");
	f.writefln(`	<head>%s
		<meta charset="UTF-8" />
		<title>Qiita Ranking (%s)</title>
		<link rel="stylesheet" type="text/css" href="../qranking.css">
	</head>`, ql_html_head_insert, target_user_id);
	f.writeln("	<body>");
	f.writeln(`<div class="headerContainer">`);
	f.writeln(format!`<h1>Qiitaいいね数ランキング (%s さんの投稿分)</h1>`(
			target_user_id));
	f.writeln(`</div><!--class="headerContainer"-->`);
	f.writeln(
			`<p><a href="#" onclick="javascript:window.history.back(-1);return false;">[戻る]</a></p>`);
	f.writeln(`<p><i><img width="16" height="16" src="../thumb-up-120px.png" /></i>が同じ値の場合は投稿日時の新しいものが上位としています。</p>`);
	f.writeln(`<p><i><img width="16" height="16" src="../thumb-up-120px.png" /></i>がついていない記事は表示していません。</p>`);
	for (int i = 0; i < min(100, records.length); i++)
	{
		Json* rec = &records[i];
		if ((*rec)[`likes_count`].get!long == 0)
			break;
		//writeln((*rec).serializeToJsonString);
		//writeln((*rec)[`title`].get!string);
		//writeln((*rec)[`likes_count`].get!long);
		string user_id = (*rec)[`user`][`id`].get!string;
		//if (user_id != target_user_id)
		//	continue;
		long user_item_count = (*rec)[`user`][`items_count`].get!long;
		string user_org = (*rec)[`user`][`organization`].get!string;
		//Json user_org_node = (*rec)[`user`][`organization`];
		//string user_org = "";
		//if (user_org_node.type == Json.Type.String)
		//	user_org = user_org_node.get!string;
		/+
		if (user_id == "Qiita")
			user_org = ``;
		if (user_id == "javacommons")
			user_org = ``;
		+/
		if (!user_org.empty)
			user_org = `<br />(` ~ user_org ~ ` 所属)`;
		Json[] tags = (*rec)[`tags`].get!(Json[]);
		string tags_html = ``;
		foreach (ref tag; tags)
		{
			tags_html ~= `<b>[` ~ tag[`name`].get!string ~ `]</b> `;
		}
		//f.write(std.xml.encode((*rec)[`title`].get!string));
		f.writeln(format!`<table border="1">
<tr>
	<td rowspan="3"><center>%sさんの<br />%d位</center></td>
	<td colspan="4">
		<kbd><i><img alt="いいね" width="16" height="16" src="../thumb-up-120px.png" /></i>%d</kbd>
		<a target="_blank" href="%s">%s</a>
	</td>
</tr>
<tr>
	<td style="width:100px;"><center>投稿日時</center></td>
	<td style="width:200px;"><center>投稿者</center></td>
	<td style="width:150px;"><center>タグ</center></td>
	<td style="width:350px;"><center>本文</center></td>
</tr>
<tr>
	<td style="width:100px;">
		<!--投稿日時--><center>%s</center>
	</td>
	<td style="width:200px;">
		@%s%s<br><img width="80" height="80" src="%s">
	</td>
	<td style="width:150px;">
		<!--タグ-->
		<center>%s</center>
	</td>
	<td style="width:350px;">
		<!--本文-->
		<div style="width:350px;height:150px;overflow-x:hidden;overflow-y:scroll;">%s</div>
	</td>
</tr>
</table>`(user_id, //
				i + 1, //
				(*rec)[`likes_count`].get!long, //
				(*rec)[`url`].get!string, //
				std.xml.encode((*rec)[`title`].get!string), //
				(*rec)[`created_at`].get!string.replace(`T`, ` `)
				.replace(`+09:00`, ``), //
				user_id, //
				user_org, //
				(*rec)[`user`][`profile_image_url`].get!string, //
				tags_html,
				(*rec)[`rendered_body`].get!string //
				));
		f.writeln("<br />");
	}
	f.writeln("	</body>");
	f.writeln("</html>");
	f.close();
}
