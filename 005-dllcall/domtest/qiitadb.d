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

public Database ql_get_db_1(string fileName)
{
	Database db = Database(fileName);
	// pragma auto_vacuum = full;
	db.run(`
	CREATE TABLE IF NOT EXISTS qiita (
		id				text primary key,
		user_id			text not null,
		created_at		text not null,
		updated_at		text not null,
		likes_count		integer not null,
		title			text not null,
		tags			text not null,
		check_time		text not null,
		post_date		text not null,
		rendered_text	text not null,
		json			text not null
	)`);
	try
	{
		db.run(`CREATE INDEX idx_qiita_user_id on qiita (user_id)`);
		db.run(`CREATE INDEX idx_qiita_created_at on qiita (created_at)`);
		db.run(`CREATE INDEX idx_qiita_updated_at on qiita (updated_at)`);
		db.run(`CREATE INDEX idx_qiita_likes_count on qiita (likes_count)`);
	}
	catch (Exception ex)
	{
	}
	return db;
}
