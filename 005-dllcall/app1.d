// Note: exception handling is left aside for clarity.
import std.stdio;
import d2sqlite3;
import std.typecons : Nullable;

alias extern (C) int function(int, int) proc_add;
alias extern (C) int function(int, int) proc_multiply;
alias extern (C) int function() proc_myfunc;

extern (C) int add2(int, int);
extern (C) int test1();
extern (C) int test2();

unittest
{
	assert(1 + 2 == 3);
	auto arr = [1, 2, 3];
	assert(arr.length == 4); // 間違ってるけど Emacs が教えてくれる！
}

unittest
{
	// このコードはunittestでコンパイルされた時のみ実行される
	writeln("this is unittest code");
	//assert(add(1,2) == 3); // error
	writeln("test clear");
}

int a; // スレッドごとに別々の静的変数を用意
shared int b; // スレッド間で共有される静的変数を用意

version (unittest)
{
}
else
	int main()
{
	import core.sys.windows.windows; // C:\D\dmd2\src\druntime\src\core\sys\windows

	writeln("start!スタート!");
	stdout.flush();

	{
		import std.conv : to;

		//import std.net.curl : byChunkAsync;
		import easy.std.net.curl : byChunkAsync;
		import std.stdio : stdout, writeln;

		ubyte[] bytes;
		foreach (chunk; byChunkAsync("http://dlang.org", 20))
		{
			writeln(chunk);
			stdout.flush();
			bytes ~= chunk;
		}
		writeln("bytes.length=", bytes.length);
		writeln(cast(char[]) bytes);
	}

	auto dll = LoadLibraryA("mylib.dll");
	writeln("*1", dll is null);
	stdout.flush();
	auto add = cast(proc_add) GetProcAddress(dll, "add");
	writeln("*2", add is null);
	stdout.flush();
	auto multiply = cast(proc_multiply) GetProcAddress(dll, "multiply");
	writeln("*3", multiply is null);
	stdout.flush();
	auto myfunc = cast(proc_myfunc) GetProcAddress(dll, "myfunc");
	writeln("*4", myfunc is null);
	stdout.flush();
	writeln("*5", myfunc is null);
	stdout.flush();
	writeln(add(1, 1));
	stdout.flush();
	writeln(multiply(2, 3));
	stdout.flush();
	writeln(myfunc());
	stdout.flush();
	writeln("*6");
	stdout.flush();
	//FreeLibrary(dll);
	writeln("*7");
	stdout.flush();
	writeln("before add2()");
	writeln("add2(): ", add2(11, 22));
	//int rc = test1();
	//writeln("rc=", rc);

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
	//writeln("test2(): ", test2());
	//writeln("test2(): ", test2());

	{
		import std.stdio;
		import core.thread;

		int result1, result2;
		auto tg = new ThreadGroup;
		tg.create = { // ここを実行するスレッドから見えているのは main 関数から見える a とは別の a
			a++;
			result1 = test2();
		};
		tg.create = {
			b++; // ここを実行するスレッドから見えているのは main 関数から見える b と同じ b
			result2 = test2();
		};
		tg.joinAll();
		writeln(a); // main 関数から見える a は変更されていないので 0
		writeln(cast(int) b); // 共有しているので変更されて 1
		writeln(result1, " ", result2);
	}

	{
		import std.stdio;
		import core.sync.mutex: Mutex;
		import core.thread;

		//static __gshared int total;
		//static shared int total;
		int total;
		void sync_fun()
		{
			synchronized
			{
				total += 1;
			}
		}

		int total2;
		shared Mutex mtx = new shared Mutex();
		void sync_fun2()
		{
			mtx.lock_nothrow();
			total2 += 1;
			mtx.unlock_nothrow();
		}

		int result1, result2;
		auto tg = new ThreadGroup;
		tg.create = {
			for (int i = 0; i < 1000; i++)
			{
				sync_fun();
				sync_fun2();
			}
		};
		tg.create = {
			for (int i = 0; i < 1000; i++)
			{
				sync_fun();
				sync_fun2();
			}
		};
		tg.joinAll();
		writeln("total=", total);
		writeln("total2=", total2);
	}

	return 0;
}
