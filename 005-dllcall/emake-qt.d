module main;

import std.stdio;

int main(string[] args)
{
    writefln("Hello World\n");
    foreach(arg; args)
    {
        writeln(arg);
    }
	return 0;
}
