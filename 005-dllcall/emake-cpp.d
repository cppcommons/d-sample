module main;
import std.algorithm : startsWith, endsWith;
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

string[] listdir(string pathname)
{
	import std.algorithm;
	import std.array;
	import std.file;
	import std.path;

	return std.file.dirEntries(pathname, SpanMode.shallow)
		.filter!(a => a.isFile).map!(a => std.path.baseName(a.name)).array;
}

private struct Target
{
	string title;
	string output;
	string object_output;
	string type;
	string compiler;
	string[] compiler_options;
	string[] import_dir_list;
	string[] lib_file_list;
	string[] linker_flags;
	string[] debug_arguments;
}

private void put_build_target(ref Element elem, Target record)
{
	/* <Target title="Debug"> */
	auto target = new Element("Target");
	elem ~= target;
	target.tag.attr["title"] = record.title;
	auto opt = new Element("Option");
	target ~= opt;
	opt.tag.attr["output"] = record.output;
	opt.tag.attr["prefix_auto"] = "1";
	opt.tag.attr["extension_auto"] = "1";
	opt = new Element("Option");
	target ~= opt;
	opt.tag.attr["object_output"] = record.object_output;
	opt = new Element("Option");
	target ~= opt;
	opt.tag.attr["type"] = record.type;
	opt = new Element("Option");
	target ~= opt;
	opt.tag.attr["compiler"] = record.compiler;
	opt = new Element("Option");
	target ~= opt;
	opt.tag.attr["createDefFile"] = "1"; // <Option createDefFile="1" />
	if (record.debug_arguments.length > 0)
	{
		opt = new Element("Option");
		target ~= opt;
		opt.tag.attr["parameters"] = record.debug_arguments.join(" ");
	}
	if (record.compiler_options.length > 0 || record.import_dir_list.length > 0)
	{
		auto compiler = new Element("Compiler");
		target ~= compiler;
		foreach (compiler_option; record.compiler_options)
		{
			auto add = new Element("Add");
			compiler ~= add;
			add.tag.attr["option"] = compiler_option;
			/+
            if (compiler_option.startsWith("-I"))
            {
                // <Add directory="../../d-lib" />
                add.tag.attr["directory"] = compiler_option[2 .. $];
            }
            else
            {
                add.tag.attr["option"] = compiler_option;
            }
			+/
		}
		foreach (import_dir; record.import_dir_list)
		{
			auto add = new Element("Add");
			compiler ~= add;
			add.tag.attr["directory"] = import_dir;
		}
	}
	if (record.lib_file_list.length > 0 || record.linker_flags.length > 0)
	{
		auto linker = new Element("Linker");
		target ~= linker;
		foreach (lib_file; record.lib_file_list)
		{
			auto add = new Element("Add");
			linker ~= add;
			// <Add library="../../d-lib/pegged-dm32.lib"
			add.tag.attr["library"] = lib_file;
		}
		foreach (linker_flag; record.linker_flags)
		{
			auto add = new Element("Add");
			linker ~= add;
			// <Add option="-p512"
			add.tag.attr["option"] = linker_flag;
		}
	}
	if (record.linker_flags.length > 0)
	{
		auto linker = new Element("Linker");
		target ~= linker;
		foreach (lib_file; record.lib_file_list)
		{
			auto add = new Element("Add");
			linker ~= add;
			// <Add library="../../d-lib/pegged-dm32.lib"
			add.tag.attr["library"] = lib_file;
		}
	}
}

int main(string[] args)
{
	////writeln(args.length);
	auto emake_cmd = new EmakeCommand("dmc", args);
	if (!emake_cmd.isValid())
		return 1;

	writefln("Command type: %s", emake_cmd.command_type);

	//File file1 = File(emake_cmd.project_base_name ~ ".cbp", "w");
	File file1 = File(emake_cmd.project_file_name ~ ".cbp", "w");
	file1.writeln(`<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>`);

	auto doc = new Document(new Tag("CodeBlocks_project_file"));
	/* 	<FileVersion major="1" minor="6" /> */
	auto fileVersion = new Element("FileVersion");
	doc ~= fileVersion;
	fileVersion.tag.attr["major"] = "1";
	fileVersion.tag.attr["minor"] = "6";
	/* <Project> */
	auto project = new Element("Project");
	doc ~= project;
	/* <Option title="emake-dmd" /> */
	void add_option(ref Element elem, string opt_name, string opt_value)
	{
		auto opt = new Element("Option");
		elem ~= opt;
		opt.tag.attr[opt_name] = opt_value;
	}

	//add_option(project, "title", exe_base_name);
	add_option(project, "title", emake_cmd.project_base_name);
	/* <Option compiler="dmd" /> */
	add_option(project, "compiler", "dmc");

	/* <Build> */
	auto build = new Element("Build");
	project ~= build;

	string get_build_type_number(string ext)
	{
		writefln("get_build_type_number(): ext=%s", ext);
		string number = "";
		switch (emake_cmd.project_file_ext)
		{
		case ".exe":
			number = "1";
			break;
		case ".lib":
			number = "2";
			break;
		case ".dll":
			number = "3";
			break;
		default:
			break;
		}
		return number;
	}

	Target targetDebug;
	targetDebug.title = "Debug";
	targetDebug.output = emake_cmd.exe_base_name ~ "_d";
	//targetDebug.object_output = emake_cmd.project_base_name ~ ".bin/dmc-obj/Debug/";
	targetDebug.object_output = emake_cmd.project_file_name ~ ".bin/dmc-obj/Debug/";
	targetDebug.type = get_build_type_number(emake_cmd.project_file_ext); //"1";
	targetDebug.compiler = "dmc";
	targetDebug.compiler_options = ["-w-", "-Ae", "-g"];
	targetDebug.import_dir_list = emake_cmd.import_dir_list;
	/+
    foreach (import_dir; emake_cmd.import_dir_list)
    {
        targetDebug.compiler_options ~= import_dir;
    }
	+/
	targetDebug.lib_file_list = emake_cmd.lib_file_list;
	targetDebug.linker_flags = emake_cmd.linker_flags;
	targetDebug.debug_arguments = emake_cmd.debug_arguments;
	put_build_target(build, targetDebug);

	Target targetRelease;
	targetRelease.title = "Release";
	targetRelease.output = emake_cmd.exe_base_name;
	//targetRelease.object_output = emake_cmd.project_base_name ~ ".bin/dmc-obj/Release/";
	targetRelease.object_output = emake_cmd.project_file_name ~ ".bin/dmc-obj/Release/";
	targetRelease.type = get_build_type_number(emake_cmd.project_file_ext); //"1";
	targetRelease.compiler = "dmc";
	targetRelease.compiler_options = ["-w-", "-Ae", "-o"];
	targetRelease.import_dir_list = emake_cmd.import_dir_list;
	/+
    foreach (import_dir; emake_cmd.import_dir_list)
    {
        targetRelease.compiler_options ~= import_dir;
    }
	+/
	targetRelease.lib_file_list = emake_cmd.lib_file_list;
	targetRelease.linker_flags = emake_cmd.linker_flags;
	targetRelease.debug_arguments = emake_cmd.debug_arguments;
	put_build_target(build, targetRelease);

	foreach (file_name; emake_cmd.file_name_list)
	{
		writefln("file_name=%s", file_name);
		stdout.flush();
		//auto dFiles = dirEntries("", "*.{d,di}", SpanMode.shallow);
		auto dFiles = dirEntries("", file_name, SpanMode.shallow);
		foreach (d; dFiles)
		{
			writeln(file_name, "==>", d.name);
			/* <Unit filename="emake-dmd.d" /> */
			auto unit = new Element("Unit");
			project ~= unit;
			unit.tag.attr["filename"] = d.name;
		}
	}

	// Pretty-print
	//writefln(join(doc.pretty(4), "\n"));

	file1.write(join(doc.pretty(4), "\n"));
	file1.close();

	switch (emake_cmd.command_type[0])
	{
	case "generate":
		break;
	case "build", "run":
		/+
        string[] cb_command = [
            "cmd", "/c", "start", "/w", "codeblocks", "--no-batch-window-close", "--target=Release",
            "--build", emake_cmd.project_base_name ~ ".cbp"
        ];+/
		string[] cb_command = [
			/*"cmd", "/c", "start", "/w",*/ "codeblocks", //"/na", "/nd",
			//"--target=Release", "--build", emake_cmd.project_base_name ~ ".cbp"
			"--target=Release", "--build", emake_cmd.project_file_name ~ ".cbp"
		];
		writeln(cb_command);
		int rc = emake_run_command_1(cb_command);
		if (rc != 0)
		{
			//cb_command = ["cmd", "/c", "start", "codeblocks", emake_cmd.project_base_name ~ ".cbp"];
			cb_command = ["cmd", "/c", "start", "codeblocks", emake_cmd.project_file_name ~ ".cbp"];
			writeln(cb_command);
			/* rc = */
			emake_run_command_1(cb_command);
			writeln("Build Failed!");
			return rc;
		}
		writeln("Build Successful!");
		break;
	default:
		break;
	}
	return 0;
}
