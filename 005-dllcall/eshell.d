module main;
import std.algorithm : canFind, endsWith, startsWith;
import std.file : copy, dirEntries, setTimes, FileException, PreserveAttributes,
    SpanMode;
import std.path : baseName, extension;
import std.process : execute, executeShell;
import std.stdio;
import std.typecons : Yes, No;
import std.datetime.systime : Clock;
import std.xml;
import std.string;
import std.array : split;

import emake_common;

int main(string[] args)
{
    string[] cmdline;
    for (int i = 1; i < args.length; i++)
    {
        string arg = args[i];
        if (arg.canFind('?') || arg.canFind('*') || arg.canFind('{') || arg.canFind('}'))
        {
            auto files = dirEntries("", arg, SpanMode.shallow);
            foreach (f; files)
            {
                //writeln(arg, "==>", f.name);
                cmdline ~= f.name;
            }
        }
        else
        {
            //writeln(arg);
            cmdline ~= arg;
        }

    }
    writeln(cmdline);
    int rc = emake_run_command(cmdline);
    writefln("Exit code: %d", rc);
    return rc;
}
