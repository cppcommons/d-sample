import my_common;
import std.stdio;

private void exit(int code)
{
	import std.c.stdlib;

	std.c.stdlib.exit(code);
}

int main()
{
	scope (success)
		writeln("test @", __FILE__, ":", __LINE__, " succeeded.");

	registerString("the section", "the key", "the value");
	writeln(retrieveString("the section", "the key", "default value"));
	writeln(retrieveString("the section", "no key", "default value"));
	encryptString("password", "string section", "string key", "string value");
	writeln(decryptString("password", "string section", "string key", "default value"));
	writeln(decryptString("password2", "string section", "string key", "default value2"));
	writeln(decryptString("password", "string section", "no key", "default value3"));
	stdout.write("input: ");
	stdout.flush();
	string line;
	line = stdin.readln();
	if (line is null)
	{
		writeln("null");
	}
	else
	{
		write(line);
	}
	return 0;
}
