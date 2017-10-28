module emake_common;
import std.algorithm : startsWith, endsWith;
import std.process : pipeProcess, wait, Redirect;
import std.stdio : writeln;

string remove_surrounding_underscore(string s)
{
    while (s.startsWith("_"))
    {
        s = s[1..$];
    }
    while (s.endsWith("_"))
    {
        s = s[0..$-1];
    }
    return s;
}

int emake_run_command(string[] dub_cmdline)
{
    auto pipes = pipeProcess(dub_cmdline, Redirect.stdout | Redirect.stderr);
    foreach (line; pipes.stdout.byLine)
        writeln(line);
    int rc = wait(pipes.pid);
    return rc;
}
