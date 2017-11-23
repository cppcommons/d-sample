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

private __gshared Database g_db;
shared static this()
{
	g_db = Database("___g_db.db3");
	g_db.run(`
	CREATE TABLE IF NOT EXISTS qiita_posts (
		post_date	text primary key,
		total_count	integer not null,
		json		text
	)`);
}

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

int main(string[] args)
{
	auto count0 = g_db.execute("SELECT count(*) FROM qiita_posts").oneValue!long;
	writefln(`count0=%d`, count0);
	//exit(0);

	string max_check_time = ``;
	File f = File("___g_total.txt", "w");
	f.write("[");
	long count = 0;
	ResultRange results = g_db.execute("SELECT *, rowid rid FROM qiita_posts ORDER BY post_date");
	loop_a: foreach (Row row; results)
	{
		auto post_date = row["post_date"].as!string;
		writeln(post_date);
		auto json = row["json"].as!string;
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
		loop_b: foreach (ref rec; reverse_array)
		{
			if ((*rec)[`check_time`].get!string > max_check_time)
				max_check_time = (*rec)[`check_time`].get!string;
			//if (count >= 100)
			//	break loop_a;
			if (count > 0)
				f.write(",\n ");
			count++;
			Json outrec = parseJsonString(`{}`);
			//writeln(rec.toPrettyString);
			writefln("%08d %s: %s %s", count, post_date, (*rec)[`created_at`], (*rec)[`title`]);
			writeln(dateparser.parse((*rec)[`created_at`].get!string));
			(*rec).remove(`coediting`);
			(*rec).remove(`group`);
			(*rec).remove(`private`);
			(*rec).remove(`reactions_count`);
			(*rec)[`user`].remove(`description`);
			outrec[`_`] = format!`%08d(likes=%d):%s[%s]`(count,
					(*rec)[`likes_count`].get!long,
					(*rec)[`created_at`].get!string, (*rec)[`title`].get!string);
			outrec[`created_at`] = (*rec)[`created_at`];
			outrec[`title`] = (*rec)[`title`];
			foreach (key, value; (*rec).byKeyValue)
			{
				if (key == `created_at`)
					continue;
				if (key == `title`)
					continue;
				outrec[key] = value;
			}
			//writeln((*rec).serializeToJsonString);
			//f.write("\n");
			//f.write((*rec).serializeToJsonString);
			//f.write("\n");
			f.write(outrec.serializeToJsonString);
		}
		//writeln(json[0 .. 40]);
	}
	//f.write("\n");
	f.write("]");
	f.write("\n");
	f.close();
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
