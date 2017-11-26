module qiitadb;

import d2sqlite3;
import std.typecons : Nullable;

import ddbc;
import hibernated.core;
import std.algorithm;
import std.stdio;

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

/+
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
		json			text not null
	)`);
	return db;
}
+/

public __gshared
{
	DataSource g_DataSource;
	SessionFactory g_SessionFactory;
	Connection g_Connection;
}

shared static ~this()
{
	g_Connection.close();
	g_SessionFactory.close();
}

shared static this()
{
	EntityMetaData schema = new SchemaInfoImpl!(Qiita, User, Customer, AccountType, Address, Role);
	import ddbc.drivers.sqliteddbc;

	SQLITEDriver driver = new SQLITEDriver();
	string url = "___hibernated.db3";
	string[string] params;
	Dialect dialect = new SQLiteDialect();
	g_DataSource = new ConnectionPoolDataSourceImpl(driver, url, params);
	g_SessionFactory = new SessionFactoryImpl(schema, dialect, g_DataSource);
	g_Connection = g_DataSource.getConnection();
	//g_Connection.setAutoCommit(false);
	g_SessionFactory.getDBMetaData().updateDBSchema(g_Connection, false, true);
	auto stmt = g_Connection.createStatement();
	scope (exit)
		stmt.close();
	stmt.executeUpdate(`CREATE INDEX IF NOT EXISTS idx_qiita_user_id on qiita (user_id)`);
	stmt.executeUpdate(`CREATE INDEX IF NOT EXISTS idx_qiita_created_at on qiita (created_at)`);
	stmt.executeUpdate(`CREATE INDEX IF NOT EXISTS idx_qiita_updated_at on qiita (updated_at)`);
	stmt.executeUpdate(`CREATE INDEX IF NOT EXISTS idx_qiita_likes_count on qiita (likes_count)`);
}

/+
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
		json			text not null
	)`);
	try
	{
		db.run(`CREATE INDEX IF NOT EXISTS idx_qiita_user_id on qiita (user_id)`);
		db.run(`CREATE INDEX IF NOT EXISTS idx_qiita_created_at on qiita (created_at)`);
		db.run(`CREATE INDEX IF NOT EXISTS idx_qiita_updated_at on qiita (updated_at)`);
		db.run(`CREATE INDEX IF NOT EXISTS idx_qiita_likes_count on qiita (likes_count)`);
	}
+/

class Qiita
{
	@Id string uuid;
	@NotNull
	{
		string user_id;
		string created_at;
		string updated_at;
		long likes_count;
		string title;
		string tags;
		string check_time;
		string post_date;
		string json;
	}
	override string toString() const
	{
		return format!`class_Qiita{uuid:%s, created_at:"%s"}`(uuid, created_at);
	}
}

// Annotations of entity classes

class User
{
	long id;
	string name;
	Customer customer;
	@ManyToMany // cannot be inferred, requires annotation
	LazyCollection!Role roles;
	override string toString() const
	{
		return format!`User{%s}`(name);
	}
}

class Customer
{
	int id;
	string name;
	// Embedded is inferred from type of Address
	Address address;

	Lazy!AccountType accountType; // ManyToOne inferred

	User[] users; // OneToMany inferred

	this()
	{
		address = new Address();
	}
}

@Embeddable class Address
{
	string zip;
	string city;
	string streetAddress;
}

class AccountType
{
	int id;
	string name;
}

class Role
{
	int id;
	string name;
	@ManyToMany // w/o this annotation will be OneToMany by convention
	LazyCollection!User users;
}
