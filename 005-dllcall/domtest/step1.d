import qiitalib;
import qiitadb;

import arsd.dom;

import dateparser;
import d2sqlite3, std.typecons : Nullable;
import vibe.data.json;
import core.time;
import std.algorithm;
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

int main(string[] args)
{
	auto count0 = g_db.execute("SELECT count(*) FROM qiita_posts").oneValue!long;
	writefln(`count0=%d`, count0);
	/+
	try
	{
		std.file.remove(`___db1.db3`);
	}
	catch (Exception ex)
	{
	}
	+/
	Database db1 = ql_get_db_1(`___db1.db3`);
	db1.execute("DELETE FROM qiita");
	db1.execute("VACUUM");
	//exit(0);

	/+
	db.run(`
	CREATE TABLE IF NOT EXISTS qiita (
		id			text primary key,
		user_id		text not null,
		created_at	text not null,
		updated_at	text not null,
		likes_count	integer not null,
		title		text not null,
		tags		text not null,
		check_time	text not null,
		json		text not null
	)`);
	+/

	string max_check_time = ``;
	File f = File("___g_total.txt", "w");
	f.write("[");
	long count = 0;
	ResultRange results = g_db.execute("SELECT *, rowid rid FROM qiita_posts ORDER BY post_date");
	loop_a: foreach (Row row; results)
	{
		string post_date = row["post_date"].as!string;
		writeln(post_date);
		string json = row["json"].as!string;
		//string rendered_body = row["rendered_body"].as!string;
		Json jsonValue = parseJsonString(json);
		Json*[] reverse_array;
		foreach (ref rec; jsonValue[])
		{
			reverse_array ~= &rec;
		}
		//reverse(reverse_array);
		bool myComp(Json* x, Json* y)
		{
			return (*x)[`created_at`].get!string < (*y)[`created_at`].get!string;
		}

		sort!myComp(reverse_array);
		db1.begin();
		loop_b: foreach (ref rec; reverse_array)
		{
			if ((*rec)[`check_time`].get!string > max_check_time)
				max_check_time = (*rec)[`check_time`].get!string;
			//if (count >= 100)
			//	break loop_a;
			if (count > 0)
				f.write(",\n ");
			count++;
			//string rendered_text = (*rec)[`rendered_body`].get!string;
			/+
			auto document = new Document();
			document.parseGarbage((*rec)[`rendered_body`].get!string);
			string rendered_text = document.root.innerText;
			if (rendered_text is null)
				rendered_text = ``;
			+/
			/+
			string[] lines = splitLines(rendered_text);
			lines = lines[0..min(20, lines.length)];
			rendered_text = lines.join("\n");
			+/
			Json outrec = parseJsonString(`{}`);
			//writeln(rec.toPrettyString);
			writefln("%08d %s: %s %s", count, post_date, (*rec)[`created_at`], (*rec)[`title`]);
			//writeln(dateparser.parse((*rec)[`created_at`].get!string));
			string user_id = (*rec)[`user`][`id`].get!string;
			if (user_id == `Qiita` || user_id == `javacommons`)
			{
				(*rec)[`user`][`organization`] = "";
			}
			else if ((*rec)[`user`][`organization`].type != Json.Type.String)
			{
				(*rec)[`user`][`organization`] = "";
			}
			//(*rec).remove(`rendered_body`);
			(*rec).remove(`coediting`);
			(*rec).remove(`group`);
			(*rec).remove(`private`);
			(*rec).remove(`reactions_count`);
			(*rec)[`user`].remove(`description`);
			(*rec)[`user`].remove(`twitter_screen_name`);
			(*rec)[`user`].remove(`github_login_name`);
			(*rec)[`user`].remove(`website_url`);
			(*rec)[`user`].remove(`linkedin_id`);
			(*rec)[`user`].remove(`followees_count`);
			(*rec)[`user`].remove(`followers_count`);
			(*rec)[`user`].remove(`facebook_id`);
			(*rec)[`user`].remove(`location`);
			outrec[`_`] = format!`%08d(likes=%d):%s[%s]`(count,
					(*rec)[`likes_count`].get!long,
					(*rec)[`created_at`].get!string, (*rec)[`title`].get!string);
			//outrec[`created_at`] = (*rec)[`created_at`];
			//outrec[`title`] = (*rec)[`title`];
			foreach (key, value; (*rec).byKeyValue)
			{
				//if (key == `created_at`)
				//	continue;
				//if (key == `title`)
				//	continue;
				outrec[key] = value;
			}
			f.write(outrec.serializeToJsonString);
			outrec.remove(`_`);
			Statement statement = db1.prepare(`INSERT INTO qiita (
	id,
	user_id,
	created_at,
	updated_at,
	likes_count,
	title,
	tags,
	check_time,
	post_date,
	json
) VALUES (
	:id,
	:user_id,
	:created_at,
	:updated_at,
	:likes_count,
	:title,
	:tags,
	:check_time,
	:post_date,
	:json
)`);
			string tags_string = "";
			foreach (tag; outrec[`tags`].get!(Json[]))
			{
				if (!tags_string.empty)
					tags_string ~= ":";
				tags_string ~= `<` ~ tag[`name`].get!string ~ `>`;
			}
			statement.bind(`:id`, outrec[`id`].get!string);
			statement.bind(`:user_id`, outrec[`user`][`id`].get!string);
			statement.bind(`:created_at`, outrec[`created_at`].get!string);
			statement.bind(`:updated_at`, outrec[`updated_at`].get!string);
			statement.bind(`:likes_count`, outrec[`likes_count`].get!long);
			statement.bind(`:title`, outrec[`title`].get!string);
			statement.bind(`:tags`, tags_string);
			statement.bind(`:check_time`, outrec[`check_time`].get!string);
			statement.bind(`:post_date`, post_date);
			//statement.bind(`:rendered_text`, rendered_text);
			statement.bind(`:json`, outrec.serializeToJsonString);
			statement.execute();
			statement.reset(); // Need to reset the statement after execution.
		}
		db1.commit();
	}
	f.write("]");
	f.write("\n");
	f.close();
	writeln(`idx_qiita_user_id`);
		db1.run(`CREATE INDEX IF NOT EXISTS idx_qiita_user_id on qiita (user_id)`);
	writeln(`idx_qiita_created_at`);
		db1.run(`CREATE INDEX IF NOT EXISTS idx_qiita_created_at on qiita (created_at)`);
	writeln(`idx_qiita_updated_at`);
		db1.run(`CREATE INDEX IF NOT EXISTS idx_qiita_updated_at on qiita (updated_at)`);
	writeln(`idx_qiita_likes_count`);
		db1.run(`CREATE INDEX IF NOT EXISTS idx_qiita_likes_count on qiita (likes_count)`);
	/+
	max_check_time = max_check_time.replace(`T`, `-`).replace(`:`, ``).replace(`+0900`, ``);
	string file_name = format!`___j_total_%s.json`(max_check_time);
	try
	{
		remove(file_name);
	}
	catch (Exception ex)
	{

	}
	//rename("___g_total.txt", file_name);
	+/
	/+
{
        "reactions_count": 0,
        "comments_count": 0,
        "url": "http://qiita.com/shinofara/items/381c8f57bf39c52d240a",
        "group": null,
        "created_at": "2013-03-20T01:44:54+09:00",
        "likes_count": 11,
        "title": "シェルスクリプトで、マルチスレッド処理風実装",
        "tags": [
                {
                        "name": "shell",
                        "versions": []
                }
        ],
        "id": "381c8f57bf39c52d240a",
        "updated_at": "2013-03-20T01:58:35+09:00",
        "coediting": false,
        "private": false,
        "user": {
                "github_login_name": "shinofara",
                "twitter_screen_name": "shinofara",
                "description": "work:\r\nEmacs/VisualStudioCode\r\nGolang/PHP/Pyhton/Shell\r\nAWS/Docker/VirtualBox/Mac\r\nVagrant/Terraform
/Packer/Ansible\r\nOSS/LT\r\n\r\nlike:\r\nPhoto/Diving/Snowboard\r\n\r\nhistory:\r\nY! -> schoo -> Y! -> MedPeer",
                "items_count": 62,
                "followees_count": 6,
                "followers_count": 37,
                "name": "しのふぁら",
                "organization": "メドピア",
                "profile_image_url": "https://qiita-image-store.s3.amazonaws.com/0/8529/profile-images/1473681060",
                "website_url": "https://log.shinofara.xyz/",
                "facebook_id": "shinofara",
                "id": "shinofara",
                "linkedin_id": "yuki-shinohara-a4476060",
                "location": "Tokyo",
                "permanent_id": 8529
        }
}
^CTerminate batch job (Y/N)? y+/

	exit(0);

	return 0;
}
