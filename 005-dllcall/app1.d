// Note: exception handling is left aside for clarity.
import std.stdio;
import d2sqlite3;
import std.typecons : Nullable;

extern (C)
{
	void* gc_getProxy();
	//void gc_setProxy(void* p);
	//void gc_clrProxy();
}

alias extern (C) void function(void*) proc_DLL_Initialize;
alias extern (C) void function() proc_DLL_Terminate;
alias extern (C) int function(int, int) proc_add;
alias extern (C) int function(int, int) proc_multiply;
alias extern (C) int function() proc_myfunc;

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

version (unittest)
{
}
else
	int main()
{
	import core.sys.windows.windows; // C:\D\dmd2\src\druntime\src\core\sys\windows

	writeln("start!スタート!");
	stdout.flush();

	auto dll = LoadLibraryA("mylib.dll");
	writeln("*0", dll is null);
	stdout.flush();
	auto DLL_Initialize = cast(proc_DLL_Initialize) GetProcAddress(dll, "DLL_Initialize");
	writeln("*1", DLL_Initialize is null);
	stdout.flush();
	//DLL_Initialize(gc_getProxy());
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
	return 0;
}