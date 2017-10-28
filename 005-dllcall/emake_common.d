module emake_common;
import std.process : pipeProcess, wait, Redirect;
import std.stdio : writeln;

int emake_run_command(string[] dub_cmdline)
{
    auto pipes = pipeProcess(dub_cmdline, Redirect.stdout | Redirect.stderr);
    foreach (line; pipes.stdout.byLine)
        writeln(line);
    int rc = wait(pipes.pid);
    return rc;
}
