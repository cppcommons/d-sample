module qiitadb;

import d2sqlite3;
import std.typecons : Nullable;

public __gshared Database g_db;
shared static this()
{
	g_db = Database("___g_db.db3");
	g_db.run(`
	CREATE TABLE IF NOT EXISTS qiita_posts (
		post_date	text primary key,
		total_count	integer not null,
		json		text not null
	)`);
}
