module emake_common_codeblocks;
import emake_common;

import std.array : join;
import std.xml;

struct Target
{
	string title;
	string output;
	string object_output;
	string type;
	string compiler;
	string[] compiler_options;
	string[] import_dir_list;
	string[] lib_file_list;
	string[] debug_arguments;
}

void put_option(Element elem, string opt_name, string opt_value)
{
	auto opt = new Element("Option");
	elem ~= opt;
	opt.tag.attr[opt_name] = opt_value;
}

void register_build_target(Element elem, Target record)
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
	target.put_option("object_output", record.object_output);
	target.put_option("type", record.type);
	target.put_option("compiler", record.compiler);
	if (record.debug_arguments.length > 0)
	{
		target.put_option("parameters", record.debug_arguments.join(" "));
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
		}
		foreach (import_dir; record.import_dir_list)
		{
			auto add = new Element("Add");
			compiler ~= add;
			// <Add directory="../../d-lib" />
			add.tag.attr["directory"] = import_dir;
		}
	}
	if (record.lib_file_list.length > 0)
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

void put_build_target(Element elem, EmakeCommand emake_cmd, string target_title,
		string output, string object_output, string[] compiler_options)
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

private string get_build_type_number(string ext)
{
	import std.stdio : writefln;
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
