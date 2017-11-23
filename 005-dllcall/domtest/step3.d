import qiitalib;

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
	/+
	SysTime v_clock = Clock.currTime();
	writeln(ql_systime_to_string(v_clock));
	exit(0);
	+/
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

	//long max_count = 5000;
	//long max_count = 1000;
	long max_count = 100;

	File f = File(format!"qranking.github.io/top-%d.html"(max_count), "wb");
	f.writeln("<html>");
	f.writeln(`	<head><!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=UA-110075493-1"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'UA-110075493-1');
</script>
<!-- Google AdSense -->
<script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
<script>
  (adsbygoogle = window.adsbygoogle || []).push({
    google_ad_client: "ca-pub-6168511236629369",
    enable_page_level_ads: true
  });
</script>
<meta charset="UTF-8" /><title>Qiita Ranking</title></head>`);
	f.writeln("	<body>");
	f.writeln(`<style type="text/css"> 
kbd{
	padding:2px 4px;
	font-size:90%;
	color:#fff;
	background-color:#333;
	border-radius:3px;
	box-shadow:inset 0 -1px 0 rgba(0,0,0,.25)
}
kbd kbd{
	padding:0;
	font-size:100%;
	font-weight:700;
	box-shadow:none
}
.headerContainer{
	background:#458ac5
}
</style>`);
	f.writeln(`<div class="headerContainer">`);
	f.writeln(format!`<h1>Qiitaいいね数ランキング (%d位まで)</h1>`(max_count));
	f.writeln(`<h2>対象記事件数: 222,355件 (2011/09/16～2017/11/23)</h2>`);
	f.writeln(`</div><!--class="headerContainer"-->`);
	f.writeln(`<p>ランキングは毎日更新します。</p>`);
	f.writeln(`<p><i><img width="16" height="16" src="thumb-up-120px.png" /></i>が同じ値の場合は投稿日時の新しいものが上位としています。</p>`);
	for (int i = 0; i < min(records.length, max_count); i++)
	{
		Json* rec = &records[i];
		writeln((*rec).serializeToJsonString);
		writeln((*rec)[`title`].get!string);
		writeln((*rec)[`likes_count`].get!long);
		string user_id = (*rec)[`user`][`id`].get!string;
		//string user_org = (*rec)[`user`][`organization`].get!string;
		long user_item_count = (*rec)[`user`][`items_count`].get!long;
		Json user_org_node = (*rec)[`user`][`organization`];
		string user_org = "";
		if (user_org_node.type == Json.Type.String)
			user_org = user_org_node.get!string;
		if (user_id == "Qiita")
			user_org = ``;
		if (user_id == "javacommons")
			user_org = ``;
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
	<td rowspan="3">%d位</td>
	<td colspan="3">
		<kbd><i><img alt="いいね" width="16" height="16" src="thumb-up-120px.png" /></i>%d</kbd>
		<a target="_blank" href="%s">%s</a>
	</td>
</tr>
<tr>
	<td><center>投稿日時</center></td>
	<td><center>投稿者</center></td>
	<td><center>タグ</center></td>
</tr>
<tr>
	<td>%s<!--投稿日時--></td>
	<td>
		@<a target="_blank" href="http://qiita.com/%s">%s</a>(%d件の記事)%s<br><img width="80" height="80" src="%s">
	</td>
	<td>%s<!--タグ--></td>
</tr>
</table>`(i + 1, //
				(*rec)[`likes_count`].get!long, //
				(*rec)[`url`].get!string, //
				std.xml.encode((*rec)[`title`].get!string), //
				(*rec)[`created_at`].get!string.replace(`T`, ` `)
				.replace(`+09:00`, ``), //
				user_id, //
				user_id, //
				user_item_count, //
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
