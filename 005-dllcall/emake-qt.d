module main;
import std.algorithm : startsWith, endsWith;
import std.array : replace;
import std.datetime.systime : Clock;
import std.file : copy, setTimes, FileException, PreserveAttributes;
import std.format : format;
import std.path : baseName, extension;
import std.process : execute, executeShell;
import std.stdio;
import std.typecons : Yes, No;

import emake_common;

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
	//string exe_base_name = remove_surrounding_underscore(project_base_name);
	string exe_base_name = project_base_name;
	File file1 = File(project_file_name, "w");
	file1.writef(`QT += core xml
QT -= gui

TARGET = %s
TEMPLATE = app
CONFIG += c++14
CONFIG += console
CONFIG -= app_bundle
`, exe_base_name);
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
	file1.writeln();
	file1.writefln(`Release:TARGET = %s`, exe_base_name);
	file1.writeln(`Release:DESTDIR = $$OUT_PWD
Release:OBJECTS_DIR = $$OUT_PWD/release/.obj
Release:MOC_DIR = $$OUT_PWD/release/.moc
Release:RCC_DIR = $$OUT_PWD/release/.rcc
Release:UI_DIR = $$OUT_PWD/release/.ui`.replace(`release/`, format!`%s.exe.bin/release/`(exe_base_name)));
	file1.writeln();
	file1.writefln(`Debug:TARGET = %s-d`, exe_base_name);
	file1.writeln(`Debug:DESTDIR = $$OUT_PWD
Debug:OBJECTS_DIR = $$OUT_PWD/debug/.obj
Debug:MOC_DIR = $$OUT_PWD/debug/.moc
Debug:RCC_DIR = $$OUT_PWD/debug/.rcc
Debug:UI_DIR = $$OUT_PWD/debug/.ui`.replace(`debug/`, format!`%s.exe.bin/debug/`(exe_base_name)));
/+
Release:TARGET = emake-gcc-r
Release:DESTDIR = $$OUT_PWD
Release:OBJECTS_DIR = release/.obj
Release:MOC_DIR = release/.moc
Release:RCC_DIR = release/.rcc
Release:UI_DIR = release/.ui

Debug:TARGET = emake-gcc-d
Debug:DESTDIR = $$OUT_PWD
Debug:OBJECTS_DIR = debug/.obj
Debug:MOC_DIR = debug/.moc
Debug:RCC_DIR = debug/.rcc
Debug:UI_DIR = debug/.ui
+/	
	file1.close();
	string makefile_name = project_base_name ~ ".mk";
	string[] cmdLine = ["qmake", "-o", makefile_name, project_file_name];
	writeln(cmdLine);
	auto cmd = execute(cmdLine);
	//if (dmd.status != 0) writeln("Compilation failed:\n", dmd.output);
	write(cmd.output);
	writeln("cmd.status=", cmd.status);
	if (cmd.status != 0)
		return cmd.status;
	try
	{
		auto currentTime = Clock.currTime();
		setTimes(exe_base_name ~ ".exe.bin", currentTime, currentTime);
	}
	catch (FileException ex)
	{
	}
	cmdLine = ["mingw32-make", "-f", makefile_name ~ ".Release"];
	writeln(cmdLine);
	int rc = emake_run_command(cmdLine);
	//cmd = execute(cmdLine);
	//write(cmd.output);
	writeln("cmd.status=", rc);
	if (rc != 0)
		return rc;
	/+
	try
	{
		copy("./release/" ~ exe_base_name ~ ".exe", exe_base_name ~ ".exe", No.preserveAttributes);
		auto currentTime = Clock.currTime();
		setTimes(exe_base_name ~ ".exe", currentTime, currentTime);
		writefln("Copy successful: %s", exe_base_name ~ ".exe");
	}
	catch (FileException ex)
	{
		writefln("Copy failure: %s", project_base_name ~ ".exe");
	}
	+/
	return 0;
}
