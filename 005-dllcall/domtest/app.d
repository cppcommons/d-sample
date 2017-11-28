import my_common;
import std.array;
import std.conv;
import std.net.curl;
import std.stdio;
import std.string;

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
		http.setAuthentication(username, password);
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
	return 0;
}
