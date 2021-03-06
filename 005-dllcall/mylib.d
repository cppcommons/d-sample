module mylib;

// http://www.kmonos.net/alang/d/dll.html D で作る Win32 DLL - プログラミング言語 D (日本語訳)

import core.sys.windows.dll : SimpleDllMain;

mixin SimpleDllMain; // C:\D\dmd2\src\druntime\import\core\sys\windows\dll.d

//import core.sys.windows.windows;

static this()
{
	import core.stdc.stdio;

	printf("static this for mydll\n");
	fflush(stdout);
}

static ~this()
{
	import core.stdc.stdio;

	printf("static ~this for mydll\n");
	fflush(stdout);
}

int d_func(int a, int b)
{
	return a + b;
}

extern (C) export int add(int i, int j)
{
	return i + j;
}

extern (C) export int multiply(int i, int j)
{
	return i * j;
}

extern (C) export int myfunc()
{
	import std.stdio;
	import d2sqlite3;
	import std.typecons : Nullable;

	writeln("myfunc!スタート!");
	// Open a database in memory.
	auto db = Database(":memory:");

	// Create a table
	db.run("DROP TABLE IF EXISTS person;
        CREATE TABLE person (
          id    INTEGER PRIMARY KEY,
          name  TEXT NOT NULL,
          score FLOAT
        )");

	// Prepare an INSERT statement
	Statement statement = db.prepare("INSERT INTO person (name, score)
     VALUES (:name, :score)");

	// Bind values one by one (by parameter name or index)
	statement.bind(":name", "John");
	statement.bind(2, 77.5);
	statement.execute();
	statement.reset(); // Need to reset the statement after execution.
	auto rowid = db.execute("SELECT last_insert_rowid()").oneValue!long;
	writeln("rowid=", rowid);
	Statement statement2 = db.prepare("SELECT name FROM person WHERE rowid == :rowid");
	statement2.bind(":rowid", rowid);
	auto name1 = statement2.execute().oneValue!string;
	writeln("name1=", name1);

	// Bind muliple values at the same time
	statement.bindAll("John", null);
	statement.execute();
	statement.reset();
	auto rowid2 = db.execute("SELECT last_insert_rowid()").oneValue!long;
	writeln("rowid=", rowid2);

	// Bind, execute and reset in one call
	statement.inject("Clara", 88.1);
	auto rowid3 = db.execute("SELECT last_insert_rowid()").oneValue!long;
	writeln("rowid=", rowid3);

	// Count the changes
	assert(db.totalChanges == 3);

	// Count the Johns in the table.
	auto count = db.execute("SELECT count(*) FROM person WHERE name == 'John'").oneValue!long;
	assert(count == 2);

	// Read the data from the table lazily
	ResultRange results = db.execute("SELECT *, rowid rid FROM person");
	foreach (Row row; results)
	{
		// Retrieve "id", which is the column at index 0, and contains an int,
		// e.g. using the peek function (best performance).
		auto id = row.peek!long(0);

		// Retrieve "name", e.g. using opIndex(string), which returns a ColumnData.
		auto name = row["name"].as!string;
		writeln(name);

		auto rowidx = row["rid"].as!ulong;
		writeln(rowidx);
		// Retrieve "score", which is at index 2, e.g. using the peek function,
		// using a Nullable type
		//auto score = row.peek!(Nullable!double)(2);
		auto score = row["score"].as!(Nullable!double);
		//score2.nullify();
		if (!score.isNull)
		{
			writeln(score);
		}
		else
		{
			writeln("<NULL>");
		}
	}
	stdout.flush();
	return 0;
}
