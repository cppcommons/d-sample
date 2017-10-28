module main;

import std.algorithm : startsWith, endsWith;
import std.stdio;
//import std.conv : to;
//import std.stdio : writeln, stdout;
//import std.string : splitLines;

int main(string[] args)
{
    writeln(args.length);
    if (args.length < 3)
    {
        writefln("Usage: emake-qt PROJECT.pro source.cpp header.h ...");
        return 1;
    }
    writefln("Hello World\n");
    string project_file_name = args[1];
    writefln("project_file_name=%s", project_file_name);
    if (!project_file_name.endsWith(".pro"))
    {
        writefln("Project file name is invalid: %s", project_file_name);
        return 1;
    }
    string project_base_name = project_file_name[0..$-4];
    writefln("project_base_name=%s", project_base_name);
    string[] source_name_list;
    source_name_list.length = 0;
    for (int i = 2; i < args.length; i++)
    {
        writefln("%d=%s", i, args[i]);
        source_name_list ~= args[i];
    }
    foreach (source_name; source_name_list)
    {
        writeln(source_name);
    }
    File file1 = File(project_file_name, "w");
    file1.writef(`QT += core xml
QT -= gui
TARGET = %s
TEMPLATE = app
CONFIG += c++14
CONFIG += console
CONFIG -= app_bundle
`, project_base_name);
    file1.close();
    return 0;
}
