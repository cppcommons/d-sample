module main;

import std.algorithm : startsWith, endsWith;
import std.path : baseName, extension;
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
    string project_file_ext = extension(project_file_name);
    writefln("project_file_ext=%s", project_file_ext);
    if (project_file_ext != ".pro")
    {
        writefln("Project file name is invalid: %s", project_file_name);
        return 1;
    }
    string project_base_name = baseName(project_file_name, project_file_ext);
    //string project_base_name = project_file_name[0..$-4];
    writefln("project_base_name=%s", project_base_name);
    string[] file_name_list;
    for (int i = 2; i < args.length; i++)
    {
        writefln("%d=%s", i, args[i]);
        file_name_list ~= args[i];
    }
    string[] header_list;
    string[] source_list;
    foreach (file_name; file_name_list)
    {
        string file_name_ext = extension(file_name);
        writeln(file_name, " ", file_name_ext);
        if (file_name_ext.startsWith(".h"))
            header_list ~= file_name;
        if (file_name_ext.startsWith(".c"))
            source_list ~= file_name;
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
    if (header_list.length > 0)
    {
        file1.writeln();
        file1.write("HEADERS += ");
        for (int i = 0; i < header_list.length; i++)
        {
            string header = header_list[i];
            if (i > 0)
                file1.write(" \\\n           ");
            file1.writef("%s", header);
        }
        file1.writeln();
    }
    if (source_list.length > 0)
    {
        file1.writeln();
        file1.write("SOURCES += ");
        for (int i = 0; i < source_list.length; i++)
        {
            string source = source_list[i];
            if (i > 0)
                file1.write(" \\\n           ");
            file1.writef("%s", source);
        }
        file1.writeln();
    }
    file1.close();
    return 0;
}
