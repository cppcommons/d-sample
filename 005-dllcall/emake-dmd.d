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

class CodeblocksProject
{
	EmakeCommand emake_cmd;
	Document doc;
	Element project;
	Element build;

	this(EmakeCommand emake_cmd)
	{
		this.emake_cmd = emake_cmd;
		this.doc = new Document(new Tag("CodeBlocks_project_file"));
		/* 	<FileVersion major="1" minor="6" /> */
		auto fileVersion = new Element("FileVersion");
		this.doc ~= fileVersion;
		fileVersion.tag.attr["major"] = "1";
		fileVersion.tag.attr["minor"] = "6";
		/* <Project> */
		this.project = new Element("Project");
		this.doc ~= this.project;
		writeln("emake_cmd.project_file_name=", this.emake_cmd.project_file_name);
		this.project.put_option("title", this.emake_cmd.project_file_name);
		this.project.put_option("compiler", this.emake_cmd.compiler_type);
		foreach (file_name; this.emake_cmd.file_name_list)
		{
			/* <Unit filename="emake-dmd.d" /> */
			auto unit = new Element("Unit");
			this.project ~= unit;
			unit.tag.attr["filename"] = file_name;
		}
		/* <Build> */
		this.build = new Element("Build");
		this.project ~= this.build;
	}

	~this()
	{
	}

	void add_build_target(string target_title, string output,
			string object_output, string[] compiler_options)
	{
		this.build.put_build_target(this.emake_cmd, target_title, output,
				object_output, compiler_options);
	}

	void save_to_file(string file_path)
	{
		File file1 = File(emake_cmd.project_file_name ~ ".cbp", "w");
		file1.writeln(`<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>`);
		file1.write(join(this.doc.pretty(4), "\n"));
		file1.close();
	}

	void exec_edit(string cbp_path)
	{
		string[] cb_command = ["codeblocks", cbp_path];
		writeln(cb_command);
		execute(cb_command);
	}

	int exec_build(string cbp_path, string[] command_type)
	{
		string[] cb_command = [
			"codeblocks", "--build", format!"--target=%s"(command_type[1] == "release"
				? "Release" : "Debug"), cbp_path
		];
		writeln(cb_command);
		auto ret = execute(cb_command);
		writeln(ret.output);
		if (ret.status != 0)
		{
			writeln("Build Failed!");
			exec_edit(cbp_path);
			//cb_command = ["codeblocks", emake_cmd.project_file_name ~ ".cbp"];
			//writeln(cb_command);
			//execute(cb_command);
			return ret.status;
		}
		writeln("Build Successful!");
		return 0;
	}
}

int main(string[] args)
{
	import std.format : format;

	auto emake_cmd = new EmakeCommand("dmd", args);
	if (!emake_cmd.isValid())
		return 1;

	writefln("Command type: %s", emake_cmd.command_type);

	auto cbp = new CodeblocksProject(emake_cmd);

	cbp.add_build_target("Debug", emake_cmd.exe_base_name ~ "_d",
			emake_cmd.project_file_name ~ ".bin/dmd-obj/Debug/", ["-g", "-debug"]);

	cbp.add_build_target("Release", emake_cmd.exe_base_name,
			emake_cmd.project_file_name ~ ".bin/dmd-obj/Release/", ["-O"]);

	cbp.save_to_file(emake_cmd.project_file_name ~ ".cbp");

	switch (emake_cmd.command_type[0])
	{
	case "generate":
		break;
	case "edit":
		cbp.exec_edit(emake_cmd.project_file_name ~ ".cbp");
		break;
	case "build", "run":
		return cbp.exec_build(emake_cmd.project_file_name ~ ".cbp",
				emake_cmd.command_type);
		break;
	default:
		break;
	}
	return 0;
}
