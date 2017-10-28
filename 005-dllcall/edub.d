module main;
import std.algorithm : startsWith, endsWith;
import std.file : copy, setTimes, FileException, PreserveAttributes;
import std.path : baseName, extension;
import std.process : execute, executeShell;
import std.stdio;
import std.typecons : Yes, No;
import std.datetime.systime : Clock;

int main(string[] args)
{
    writeln(args.length);
    if (args.length < 2)
    {
        writefln("Usage: edub PROJECT.json [build/run]");
        return 1;
    }
    string project_file_name = args[1];
    writefln("project_file_name=%s", project_file_name);
    try
    {
        copy(project_file_name, "dub.json", Yes.preserveAttributes);
        auto currentTime = Clock.currTime();
        setTimes("dub.json", currentTime, currentTime);
        writefln("Copy successful: %s ==> dub.json", project_file_name);
    }
    catch (FileException ex)
    {
        writefln("Copy failure: %s", project_file_name);
    }
    string[] dub_cmdline;
    dub_cmdline ~= "dub";
    for (int i = 2; i < args.length; i++)
    {
        dub_cmdline ~= args[i];
    }
    writeln(dub_cmdline);
    auto cmd = execute(dub_cmdline);
    write(cmd.output);
    writeln("cmd.status=", cmd.status);
    return cmd.status;
    return 0;
}
