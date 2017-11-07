import dateparser;
import jsonizer;

//import core.sync.barrier;
import core.sync.rwmutex;
import core.thread;
import std.array;
import std.conv;
import std.datetime;
import std.file;
import std.format;
import std.json;
import std.net.curl;
import std.path;
import std.process;
import std.regex;
import std.stdio;
import std.string;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

struct QPost
{
	mixin JsonizeMe; // this is required to support jsonization
	@jsonize
	{
		string uuid;
		long favCount;
		string title;
		string href;
		string header;
		string description;
		string tags;
		string postDate;
	}
}

static __gshared SysTime[] schedule;

//__gshared ReadWriteMutex mutex;
private __gshared ReadWriteMutex mutex;
static this()
{
	mutex = new ReadWriteMutex(ReadWriteMutex.Policy.PREFER_WRITERS);
}

version (TEST1) int main(string[] args)
{
	// "2011/09/16"
	version (none)
	{
		const short year0 = 2011;
		const ubyte month0 = 9;
	}
	else
	{
		const short year0 = 2017;
		const ubyte month0 = 9;
	}
	SysTime v_date = Clock.currTime();
	assert(v_date >= SysTime(DateTime(year0, month0, 1)));
	string v_str = format!`%04d-%02d-%02d`(v_date.year, v_date.month, v_date.day);
	writeln(v_str);
	a: for (short year = year0; year <= short.max; year++)
	{
		b: for (Month month = Month.jan; month <= Month.dec; month++)
		{
			if (year == year0 && month < month0)
				continue;
			writefln(`year=%d month=%u`, year, month);
			schedule ~= SysTime(DateTime(year, month, 1));
			if (year == v_date.year && month == v_date.month)
				break a;
		}
	}
	foreach (v_sample; schedule)
	{
		writeln(v_sample);
	}
	synchronized (mutex.writer)
	{
		writeln("writing...");
	}
	synchronized (mutex.reader)
	{
		writeln("reading...");
	}

	bool pop(out SysTime head)
	{
		synchronized (mutex.writer)
		{
			if (schedule.length == 0)
				return false;
			head = schedule[0];
			schedule = schedule[1 .. $];
			return true;
		}
	}

	int run_command(string[] cmdline)
	{
		auto pipes = pipeProcess(cmdline, Redirect.stdout | Redirect.stderrToStdout);
		foreach (line; pipes.stdout.byLine)
		{
			import std.stdio : stdout;

			writeln(line);
			stdout.flush();
		}
		int rc = wait(pipes.pid);
		return rc;
	}

	void writerFn()
	{
		SysTime v_st;
		if (!pop(v_st))
			return;
		writeln(`v_st=`, v_st);
		string v_period = format!`%04d-%02d`(v_st.year, v_st.month);
		writeln(`v_period=`, v_period);
		string[] cmd = ["domtest.exe", v_period];
		run_command(cmd);
	}

	Thread t1 = new Thread(&writerFn).start();
	Thread t2 = new Thread(&writerFn).start();
	//Thread t3 = new Thread(&writerFn).start();
	while (t1.isRunning || t2.isRunning)
	{
		Thread.sleep(dur!("msecs")(50));
	}

	delete t1;
	delete t2;

	writeln("All finished!");
	return 0;
}
