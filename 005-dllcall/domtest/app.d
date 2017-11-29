import my_common;
import vibe.data.json;
import std.array;
import std.conv;
import std.net.curl;
import std.stdio;
import std.string;

import core.sync.rwmutex;
import core.sync.semaphore;
import core.thread;
import core.time;
import std.algorithm;
import std.algorithm.mutation;
import std.algorithm.sorting;
import std.algorithm.setops;
import std.array;
import std.conv;
import std.datetime;
import std.datetime.systime;
import std.file;
import std.format;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

public void sleepForWeeks(long n)
{
	sleepFor(dur!`weeks`(n));
}

public void sleepForDays(long n)
{
	sleepFor(dur!`days`(n));
}

public void sleepForHours(long n)
{
	sleepFor(dur!`hours`(n));
}

public void sleepForMinutes(long n)
{
	sleepFor(dur!`minutes`(n));
}

public void sleepForSeconds(long n)
{
	sleepFor(dur!`seconds`(n));
}

public void sleepFor(Duration duration)
{
	SysTime startTime = Clock.currTime();
	SysTime targetTime = startTime + duration;
	sleepUntil(targetTime);
}

public void sleepUntil(DateTime targetTime)
{
	sleepUntil(SysTime(targetTime));
}

public void sleepUntil(SysTime targetTime)
{
	string systimeToString(SysTime t)
	{
		SysTime t_of_sec = SysTime(DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second));
		return t_of_sec.toISOExtString().replace(`T`, ` `).replace(`-`, `/`);
	}

	string targetTimeStr = systimeToString(targetTime);
	size_t maxWidth = 0;
	for (;;)
	{
		SysTime currTime = Clock.currTime();
		if (currTime >= targetTime)
			break;
		Duration leftTime = targetTime - currTime;
		leftTime = dur!`msecs`(leftTime.total!`msecs`); // 残り時間表示用にミリ秒以下を切り捨て
		string displayStr = format!`Sleeping: until %s (%s left).`(targetTimeStr, leftTime);
		if (displayStr.length > maxWidth)
			maxWidth = displayStr.length;
		displayStr.reserve(maxWidth);
		while (displayStr.length < maxWidth)
			displayStr ~= ` `;
		stderr.writef("%s\r", displayStr);
		stderr.flush();
		Thread.sleep(dur!(`msecs`)(500));
	}
	for (int i = 0; i < maxWidth; i++)
		write(` `);
	stderr.write("\r");
	stderr.write("Sleeping: end.\n");
	stderr.flush();
}

string github_get_username()
{
	string username = retrieveString("github", "username");
	if (username !is null)
		return username;
	stdout.write("github username: ");
	stdout.flush();
	string line;
	line = stdin.readln();
	if (line !is null)
		line = line.strip;
	if (line is null || line.empty)
	{
		stderr.writeln("username is required!");
		exit(1);
		return null;
	}
	else
	{
		registerString("github", "username", line);
		return line;
	}
}

string github_get_password()
{
	shared static string enc_pass = "*";
	string password = decryptString(enc_pass, "github", "password");
	if (password !is null)
		return password;
	stdout.write("github password: ");
	stdout.flush();
	string line;
	line = stdin.readln();
	if (line !is null)
		line = line.strip;
	if (line is null || line.empty)
	{
		stderr.writeln("password is required!");
		exit(1);
		return null;
	}
	else
	{
		encryptString(enc_pass, "github", "password", line);
		return line;
	}
}

class C_GitHubHttp
{
	HTTP.StatusLine statusLine;
	string[string] headers;
	ubyte[] data;
	int get(string url)
	{
		//this.code = 0;
		this.headers.clear();
		this.data.length = 0;
		auto http = HTTP(url);
		string username = github_get_username();
		string password = github_get_password();
		//http.clearRequestHeaders();
		//http.setAuthentication(username, password);
		//http.addRequestHeader(`Authorization`, `Bearer 06ade23e3803334f43a0671f2a7c5087305578bd`);
		http.onReceiveStatusLine = (in HTTP.StatusLine statusLine) {
			this.statusLine = statusLine;
		};
		http.onReceiveHeader = (in char[] key, in char[] value) {
			this.headers[key] = to!string(value);
		};
		http.onReceive = (ubyte[] bytes) {
			this.data ~= bytes;
			return bytes.length;
		};
		//this.code = http.perform(No.throwOnError);
		//return this.code;
		return http.perform(No.throwOnError);
	}

	override string toString() const
	{
		return "???";
	}
}

class C_GitHubApi
{
	C_GitHubHttp http;
	Json jsonValue;
	this()
	{
		this.http = new C_GitHubHttp();
	}

	~this()
	{
		delete this.http;
	}

	int get(string url)
	{
		_loop_a: for (;;)
		{
			this.jsonValue = null;
			int rc = this.http.get(url);
			if (rc != 0)
				return rc;
			writefln("this.http.statusLine.code=%d", this.http.statusLine.code);
			if (this.http.statusLine.code == 403)
			{
				writeln(cast(string) this.http.data);
				//string data = cast(string) this.http.data;
				//if (data.canFind(`API rate limit exceeded`))
				if (("x-ratelimit-remaining" in this.http.headers)
						&& to!long(this.http.headers["x-ratelimit-remaining"]) == 0)
				{
					long rateRemaining;
					SysTime rateResetTime;
					if ("x-ratelimit-remaining" in this.http.headers)
						rateRemaining = to!long(this.http.headers["x-ratelimit-remaining"]);
					long v_rate_reset = 0;
					if ("x-ratelimit-reset" in this.http.headers)
						v_rate_reset = to!long(this.http.headers["x-ratelimit-reset"]);
					rateResetTime = SysTime(unixTimeToStdTime(v_rate_reset));
					writeln(`rate_limit_exceeded error!: rateResetTime=`, rateResetTime);
					/+
					SysTime currentTime = Clock.currTime();
					writeln(currentTime);
					Duration diff = rateResetTime - currentTime;
					writeln(diff);
					Duration diff2 = diff + dur!`seconds`(60);
					writeln(diff2);
					writeln(`Sleeping for: `, diff2);
					sleepForSeconds(diff2.total!`seconds`);
					+/
					sleepUntil(rateResetTime + dur!`seconds`(60));
					continue _loop_a;
				}
				write("\a");
				return -1;
			}
			if (this.http.statusLine.code != 200)
			{
				write("\a");
				return -1;
			}
			if (this.http.headers["content-type"] != "application/json"
					&& this.http.headers["content-type"] != "application/json; charset=utf-8")
			{
				writeln(`not application/json`);
				writeln(this.http.headers);
				return -1;
			}
			try
			{
				this.jsonValue = parseJsonString(cast(string) this.http.data);
			}
			catch (JSONException ex)
			{
				write("\a");
				writeln(ex);
				return -1;
			}
			break _loop_a;
		}

		return 0;
	}
}

int main()
{
	scope (success)
		writeln("test @", __FILE__, ":", __LINE__, " succeeded.");

	//string username = github_get_username();
	//string password = github_get_password();
	//writeln(username, "/", password);
	C_GitHubHttp http = new C_GitHubHttp;
	int rc = http.get("https://api.github.com/repos/cppcommons/d-sample/contents/vc2017-env.bat");
	writeln(rc);
	writeln(http.headers);
	writeln(http.statusLine);
	writeln(http);
	for (;;)
	{
		auto api = new C_GitHubApi;
		int rc2 = api.get(
				"https://api.github.com/repos/cppcommons/d-sample/contents/vc2017-env.bat");
		writeln(rc2);
		writeln(api.http.headers);
		writeln(api.http.statusLine);
		writeln(api.http);
		//writeln(api.jsonValue.serializeToJson);
	}
	//return 0;
}
