module main;
import emake_common;
import emake_common_codeblocks;

import std.algorithm : startsWith, endsWith;
import std.file : copy, setTimes, FileException, PreserveAttributes;
import std.path : baseName, extension;
import std.process : execute, executeShell;
import std.stdio;
import std.typecons : Yes, No;
import std.datetime.systime : Clock;
import std.xml;
import std.string;
import std.array : split;

string get_build_type_number(string ext)
{
	writefln("get_build_type_number(): ext=%s", ext);
	string number = "";
	switch (ext)
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

class CodeblocksProject
{
	EmakeCommand emake_cmd;
	Document doc;

	this(EmakeCommand emake_cmd)
	{
		this.emake_cmd = emake_cmd;
		this.doc = new Document(new Tag("CodeBlocks_project_file"));
		//auto doc = new Document(new Tag("CodeBlocks_project_file"));
		/* 	<FileVersion major="1" minor="6" /> */
		auto fileVersion = new Element("FileVersion");
		this.doc ~= fileVersion;
		fileVersion.tag.attr["major"] = "1";
		fileVersion.tag.attr["minor"] = "6";
	}

	~this()
	{
	}

	void save_to_file(string file_path)
	{
		File file1 = File(emake_cmd.project_file_name ~ ".cbp", "w");
		file1.writeln(`<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>`);
		file1.write(join(this.doc.pretty(4), "\n"));
		file1.close();
	}
}

int main(string[] args)
{
	import std.format : format;

	////writeln(args.length);
	auto emake_cmd = new EmakeCommand("dmd", args);
	if (!emake_cmd.isValid())
		return 1;

	writefln("Command type: %s", emake_cmd.command_type);

	//File file1 = File(emake_cmd.project_file_name ~ ".cbp", "w");
	//file1.writeln(`<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>`);

	auto cbp = new CodeblocksProject(emake_cmd);
	/* <Project> */
	auto project = new Element("Project");
	cbp.doc ~= project;
	/* <Option title="emake-dmd" /> */

	//put_option(project, "title", exe_base_name);
	writeln("emake_cmd.project_file_name=", emake_cmd.project_file_name);
	put_option(project, "title", emake_cmd.project_file_name);
	/* <Option compiler="dmd" /> */
	put_option(project, "compiler", emake_cmd.compiler_type);

	foreach (file_name; emake_cmd.file_name_list)
	{
		/* <Unit filename="emake-dmd.d" /> */
		auto unit = new Element("Unit");
		project ~= unit;
		unit.tag.attr["filename"] = file_name;
	}

	/* <Build> */
	auto build = new Element("Build");
	project ~= build;

	void put_build_target(Element elem, string target_title, string output,
			string object_output, string[] compiler_options)
	{
		Target target;
		target.title = target_title;
		target.output = output;
		target.object_output = object_output;
		target.type = get_build_type_number(emake_cmd.project_file_ext);
		target.compiler = emake_cmd.compiler_type;
		target.compiler_options = compiler_options;
		target.import_dir_list = emake_cmd.import_dir_list;
		target.lib_file_list = emake_cmd.lib_file_list;
		target.debug_arguments = emake_cmd.debug_arguments;
		elem.register_build_target(target);
	}

	put_build_target(build, "Debug", emake_cmd.exe_base_name ~ "_d",
			emake_cmd.project_file_name ~ ".bin/dmd-obj/Debug/", ["-g", "-debug"]);

	put_build_target(build, "Release", emake_cmd.exe_base_name,
			emake_cmd.project_file_name ~ ".bin/dmd-obj/Release/", ["-O"]);

	/+
	foreach (file_name; emake_cmd.file_name_list)
	{
		/* <Unit filename="emake-dmd.d" /> */
		auto unit = new Element("Unit");
		project ~= unit;
		unit.tag.attr["filename"] = file_name;
	}
	+/

	// Pretty-print
	//writefln(join(doc.pretty(4), "\n"));

	cbp.save_to_file(emake_cmd.project_file_name ~ ".cbp");
	//file1.write(join(cbp.doc.pretty(4), "\n"));
	//file1.close();

	switch (emake_cmd.command_type[0])
	{
	case "generate":
		break;
	case "edit":
		string[] cb_command = ["codeblocks", emake_cmd.project_file_name ~ ".cbp"];
		writeln(cb_command);
		execute(cb_command);
		break;
	case "build", "run":
		string[] cb_command = [
			"codeblocks", "--build", format!"--target=%s"(emake_cmd.command_type[1] == "release"
				? "Release" : "Debug"), emake_cmd.project_file_name ~ ".cbp"
		];
		writeln(cb_command);
		auto ret = execute(cb_command);
		writeln(ret.output);
		if (ret.status != 0)
		{
			writeln("Build Failed!");
			cb_command = ["codeblocks", emake_cmd.project_file_name ~ ".cbp"];
			writeln(cb_command);
			execute(cb_command);
			return ret.status;
		}
		writeln("Build Successful!");
		break;
	default:
		break;
	}
	return 0;
}
