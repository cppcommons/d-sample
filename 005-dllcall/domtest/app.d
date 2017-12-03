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
import std.typecons;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
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

string github_get_token()
{
	string token = retrieveString("github", "token");
	if (token !is null)
	{
		writeln(`token=`, token);
		return token;
	}
	stdout.write("github token: ");
	stdout.flush();
	string line;
	line = stdin.readln();
	if (line !is null)
		line = line.strip;
	if (line is null || line.empty)
	{
		stderr.writeln("token is required!");
		exit(1);
		return null;
	}
	else
	{
		registerString("github", "token", line);
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
		this.headers.clear();
		this.data.length = 0;
		auto http = HTTP(url);
		//http.clearRequestHeaders();
		//string username = github_get_username();
		//string password = github_get_password();
		string token = github_get_token();
		//http.setAuthentication(username, password);
		http.addRequestHeader(`Authorization`, format!`token %s`(token));
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
			if (this.http.statusLine.code != 200 && this.http.statusLine.code != 403)
			{
				writeln(this.http.headers);
				writeln(cast(string) this.http.data);
				exit(1);
			}
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
	/+
	C_GitHubHttp http = new C_GitHubHttp;
	int rc = http.get("https://api.github.com/repos/cppcommons/d-sample/contents/vc2017-env.bat");
	writeln(rc);
	writeln(http.headers);
	writeln(http.statusLine);
	writeln(http);
	+/

	auto commits = new C_GitHubApi;
	int rc1 = commits.get("https://api.github.com/repos/cppcommons/d-sample/commits");
	auto last_commit = commits.jsonValue.get!(Json[])[0];

	auto api = new C_GitHubApi;
	//int rc2 = api.get("https://api.github.com/repos/cppcommons/d-sample/contents/vc2017-env.bat");
	int rc2 = api.get(
			"https://api.github.com/repos/cppcommons/d-sample/contents?ref="
			~ last_commit[`sha`].get!string);
	writeln(rc2);
	writeln(api.http.headers);
	writeln(api.http.statusLine);
	writeln(api.http);
	//writeln(api.jsonValue.serializeToJson);
	//writeln(api.jsonValue.toPrettyString);
	auto entryList = api.jsonValue.get!(Json[]);
	foreach (entry; entryList)
	{
		if (entry[`name`].get!string == `000-misc` || entry[`name`].get!string == `005-dllcall`)
		{
			writeln(entry.toPrettyString);
		}
	}
	writeln(api.http.headers[`etag`]);
	//writeln(last_commit.toPrettyString);
	//writeln(last_commit[`sha`].get!string);

	/+
	auto tree = new C_GitHubApi;
	int rc3 = tree.get(format!"https://api.github.com/repos/cppcommons/d-sample/git/trees/%s?recursive=1"(
			last_commit[`sha`].get!string));
	writeln(tree.jsonValue.toPrettyString);
+/

	auto master = new C_GitHubApi;
	int rc4 = master.get(
			format!"https://api.github.com/repos/cppcommons/d-sample/branches/%s"(`master`));
	//writeln(master.jsonValue.toPrettyString);
	writeln(master.http.headers[`etag`]);
	//writeln(master.jsonValue[`commit`][`commit`][`tree`][`sha`].get!string);
	//writeln(master.jsonValue[`commit`][`commit`][`tree`][`url`].get!string);
	writeln(master.jsonValue[`commit`][`sha`].get!string);
	writeln(last_commit[`sha`].get!string);

	auto tree = new C_GitHubApi;
	int rc3 = tree.get(
			master.jsonValue[`commit`][`commit`][`tree`][`url`].get!string ~ `?recursive=1`);
	writeln(tree.jsonValue.toPrettyString);
	writeln(tree.http.headers["x-ratelimit-remaining"]);

	// https://raw.githubusercontent.com/cppcommons/d-sample/^
	// d14b2a455037be7dfd22f7786a01187a6e25cf6c/vc2017-env.bat

	/+
	auto http = HTTP();
	string username = github_get_username();
	string password = github_get_password();
	http.setAuthentication(username, password);
	string post_data = `{
  "scopes": [
    "repo"
  ],
  "note": "edub command"
}`;
	auto response = post(`https://api.github.com/authorizations`, post_data, http);
	writeln(response);
	+/

	/+
	auto http = HTTP();
	http.addRequestHeader(`Authorization`, `token b8642e618ce422e33e9c1509a0f869f3cfc1d9fc`);
	auto response = get(format!"https://api.github.com/repos/cppcommons/d-sample/branches/%s"(`master`), http);
	writeln(`response=`, response);
	+/

	Nullable!(int, int.min) i = int.min;

	return 0;
}
