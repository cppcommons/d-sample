// https://code.dlang.org/package-format?lang=json
module main;
import std.algorithm : canFind, startsWith, endsWith;
import std.array : empty, split, replace;
import std.file : chdir, copy, exists, getcwd, mkdirRecurse, read, rename,
	remove, rmdirRecurse, setTimes, write, FileException, PreserveAttributes;
import std.format : format;
import std.json;
import std.path : absolutePath, baseName, dirName, extension, isAbsolute;
import std.process : execute, executeShell;
import std.regex : regex, matchAll, matchFirst, replaceAll;
import std.stdio : writefln, writeln, File;
import std.typecons : Yes, No;
import std.datetime.systime : Clock;
import std.process : pipeProcess, wait, Redirect;
import std.string : strip;
import std.uni : toLower;
import std.uuid : sha1UUID, UUID;

//import emake_common : emake_run_command;

private void exit(int code)
{
	import std.c.stdlib;

	//writeln("before exit()");
	std.c.stdlib.exit(code);
	//writeln("after exit()");
}

class EDubContext
{
	string fullPath;
	string dirName;
	string fileName;
	string extension;
	string baseName;
	string basePath;
	string[] path_keyword_list = [
		"targetPath", "sourceFiles", "sourcePaths", "excludedSourceFiles",
		"mainSourceFile", "copyFiles", "importPaths", "stringImportPaths"
	];
	bool opt_cleanup;
	this()
	{
	}
}

private __gshared EDubContext g_context = new EDubContext();

private string make_abs_path(string path)
{
	switch (path)
	{
	case `.`, `./`, `.\`:
		return g_context.dirName;
	default:
		return absolutePath(path, g_context.dirName).replace(`\`, `/`);
	}
}

private int emake_run_command(string[] dub_cmdline)
{
	auto pipes = pipeProcess(dub_cmdline, Redirect.stdout | Redirect.stderrToStdout);
	foreach (line; pipes.stdout.byLine)
		writeln(line);
	int rc = wait(pipes.pid);
	return rc;
}

void rewite_dub_json(JSONValue* jsonObj, ref JSONValue*[] path_array_list, string prop_name)
{
	JSONValue* get_object_array_member(JSONValue* jsonObj, string key)
	{
		JSONValue* member = cast(JSONValue*)(key in (*jsonObj));
		if (member.type() != JSON_TYPE.ARRAY && member.type() != JSON_TYPE.STRING)
			return null;
		return member;
	}

	if (jsonObj.type == JSON_TYPE.ARRAY)
	{
		for (int i = 0; i < jsonObj.array.length; i++)
		{
			rewite_dub_json(&jsonObj.array[i], path_array_list, prop_name);
		}

	}
	else if (jsonObj.type == JSON_TYPE.OBJECT)
	{
		static string[] list = ["[root]", "configurations", "subPackages"];
		if (list.canFind(prop_name)) //(("name" in jsonObj.object) || ("targetType" in jsonObj.object))
		{
			if (!("targetPath" in jsonObj.object))
			{
				jsonObj.object["targetPath"] = `.`;
			}
		}
		JSONValue*[] result;
		foreach (key; jsonObj.object.keys())
		{
			JSONValue* member = key in jsonObj.object;
			rewite_dub_json(member, path_array_list, key);
			if (g_context.path_keyword_list.canFind(key.split("-")[0]))
			{
				JSONValue* array = get_object_array_member(jsonObj, key);
				if (array)
					path_array_list ~= array;
			}
		}
	}
	else
	{
	}
}

private string my_json_pprint(ref JSONValue jsonObj)
{
	int[string] dict = [
		"name" : 1, "description " : 2, "homepage" : 3, "authors" : 4, "copyright"
		: 5, "license" : 6, "targetName" : 7, "targetType" : 8, "targetPath" : 9,
		"workingDirectory" : 10, "dependencies" : 11, "subConfigurations" : 12, "versions" : 13, "debugVersions" : 14,
		"importPaths" : 15, "stringImportPaths" : 16, "sourcePaths" : 17, "mainSourceFile" : 18, "sourceFiles" : 19,
		"excludedSourceFiles" : 20, "libs" : 21, "subPackages" : 0, "configurations" : 0, "buildTypes" : 0,
		"ddoxFilterArgs" : 0, "systemDependencies" : 0, "buildRequirements" : 0,
		"buildOptions" : 0, "copyFiles" : 0, "preGenerateCommands"
		: 0, "postGenerateCommands" : 0, "preBuildCommands" : 0,
		"postBuildCommands" : 0, "dflags" : 0, "lflags" : 0
	];
	void my_json_pprint_helper(JSONValue* jsonObj, string uuid)
	{
		// https://code.dlang.org/package-format?lang=json
		JSON_TYPE type = jsonObj.type;
		if (type == JSON_TYPE.ARRAY)
		{
			for (int i = 0; i < jsonObj.array.length; i++)
				my_json_pprint_helper(&jsonObj.array[i], uuid);
		}
		else if (type == JSON_TYPE.OBJECT)
		{
			string[] keys = jsonObj.object.keys;
			foreach (key; keys)
			{
				my_json_pprint_helper(&jsonObj.object[key], uuid);
				int* found = key.split("-")[0] in dict;
				if (found && (*found) != 0)
				{
					jsonObj.object[format!`<%05d-%s>`(*found, uuid) ~ key] = jsonObj.object[key];
					jsonObj.object.remove(key);
				}
			}
		}
	}

	JSONValue jsonCopy = jsonObj;
	string uuid = sha1UUID("edub").toString;
	my_json_pprint_helper(&jsonCopy, uuid);
	string result = jsonCopy.toPrettyString(JSONOptions.doNotEscapeSlashes);
	auto re = regex(format!`<(\d)+-%s>`(uuid), "g");
	result = replaceAll(result, re, "");
	return result;
}

private int handle_exe_output(string[] args)
{
	string pop(ref string[] list)
	{
		if (list.length == 0)
			return "";
		string result = list[0];
		list = list[1 .. $];
		return result;
	}

	string normalize_path(string path)
	{
		return path.replace(`\`, `/`);
	}

	string arg_strip_prefix(string arg)
	{
		int arg_prefix_len(string arg)
		{
			auto re = regex(`^[^=]+=`);
			auto m = matchFirst(arg, re);
			if (!m)
				return 0;
			return m[0].length;
		}

		return arg[arg_prefix_len(arg) .. $];
	}

	writeln(`handle_exe_output:`, args);
	string command = pop(args);
	writefln(`handle_exe_output: %s %s %s`, g_context.fileName, command, args);
	switch (command)
	{
	case `build`:
	case `init`:
		break;
	default:
		writefln(`Invalid command "%s".`, command);
		exit(1);
	}
	//int[string] dummyAlist;
	JSONValue jsonObj = parseJSON("{}"); //dummyAlist;
	jsonObj["name"] = g_context.baseName.toLower;
	jsonObj["targetName"] = g_context.baseName;
	jsonObj["targetType"] = "executable";
	string[] dub_opts;
	string main_source;
	string[] source_files;
	string[] source_dirs;
	string[] include_dirs;
	string[] resource_dirs;
	string[] libs;
	string[] defines;
	string[] debug_defines;
	struct _PackageSpec
	{
		string _name;
		string _version;
		string _sub_config;
	}

	_PackageSpec[] packages;
	string uuid = sha1UUID(":").toString;
	uuid = format!`{%s}`(uuid);
	while (args.length)
	{
		string arg = pop(args).strip;
		writefln(`arg="%s"`, arg);
		if (arg.startsWith(`[`))
		{
			arg = arg.replace("{:}", uuid);
			auto re = regex(`^\[([^:]+)(:[^:]+)?(:[^:]+)?\]$`);
			auto m = matchFirst(arg, re);
			if (m)
			{
				writeln(`match!`);
				writefln(`match="%s" "%s" "%s"`, m[1], m[2], m[3]);
				_PackageSpec spec;
				spec._name = m[1].replace(uuid, `:`);
				spec._version = m[2].empty ? "~master" : m[2][1 .. $].replace(uuid, `:`);
				spec._sub_config = m[3].empty ? "" : m[3][1 .. $].replace(uuid, `:`);
				packages ~= spec;
				writeln("match end!");
			}
		}
		else if (arg.startsWith("-"))
		{
			if (arg == "--cleanup")
			{
				g_context.opt_cleanup = true;
			}
			else
			{
				dub_opts ~= arg;
			}
		}
		else if (arg.startsWith(`main=`))
		{
			main_source = arg_strip_prefix(arg);
		}
		else if (arg.startsWith(`source=`) || arg.startsWith(`src=`))
		{
			source_dirs ~= normalize_path(arg_strip_prefix(arg));
		}
		else if (arg.startsWith(`resource=`) || arg.startsWith(`res=`))
		{
			resource_dirs ~= normalize_path(arg_strip_prefix(arg));
		}
		else if (arg.startsWith(`include=`) || arg.startsWith(`inc=`))
		{
			include_dirs ~= normalize_path(arg_strip_prefix(arg));
		}
		else if (arg.startsWith(`libs=`) || arg.startsWith(`lib=`))
		{
			libs ~= arg_strip_prefix(arg).split(`:`);
		}
		else if (arg.startsWith(`defines=`) || arg.startsWith(`defs=`)
				|| arg.startsWith(`define=`) || arg.startsWith(`def=`))
		{
			foreach (def; arg_strip_prefix(arg).split(`:`))
			{
				if (def.startsWith(`@`))
					debug_defines ~= def[1 .. $];
				else
					defines ~= def;
			}
		}
		else
		{
			source_files ~= arg;
		}
	}
	if (main_source)
		jsonObj["mainSourceFile"] = main_source;
	if (source_files)
		jsonObj["sourceFiles"] = source_files;
	if (source_dirs)
		jsonObj["sourcePaths"] = resource_dirs;
	if (include_dirs)
		jsonObj["importPaths"] = include_dirs;
	if (resource_dirs)
		jsonObj["stringImportPaths"] = resource_dirs;
	if (libs)
		jsonObj["libs"] = libs;
	if (defines)
		jsonObj["versions"] = defines;
	if (debug_defines)
		jsonObj["debugVersions"] = debug_defines;
	int sub_config_count = 0;
	if (packages.length > 0)
	{
		//string[string] dependencies_init;
		jsonObj["dependencies"] = parseJSON("{}"); //dependencies_init;
		foreach (ref pkg; packages)
		{
			jsonObj["dependencies"][pkg._name] = pkg._version;
			if (!pkg._sub_config.empty)
				sub_config_count++;
		}
		if (sub_config_count > 0)
		{
			//string[string] sub_config_init;
			jsonObj["subConfigurations"] = parseJSON("{}"); //sub_config_init;
			foreach (ref pkg; packages)
			{
				if (pkg._sub_config.empty)
					continue;
				jsonObj["subConfigurations"][pkg._name] = pkg._sub_config;
			}
		}
	}
	//stringImportPaths
	string json = my_json_pprint(jsonObj);
	writeln(json);
	//writeln(packages);
	string dub_json_path = format!`%s.json`(g_context.fullPath);
	writefln(`dub_json_path="%s"`, dub_json_path);
	File file1 = File(dub_json_path, "w");
	file1.write(json);
	file1.close();
	if (command == "init")
		return 0;
	string[] new_args = ["edub.exe", dub_json_path, command];
	new_args ~= dub_opts;
	return main(new_args);
}

int main(string[] args)
{
	//writeln(args.length);
	writeln(`args=`, args);
	if (args.length < 2)
	{
		writefln("Usage: edub2 PROJECT.json [build/run]");
		return 1;
	}
	//string project_file_name = args[1];
	g_context.fullPath = absolutePath(args[1], getcwd()).replace(`\`, `/`);
	writefln(`g_context.fullPath=%s`, g_context.fullPath);
	g_context.dirName = dirName(g_context.fullPath);
	writefln(`g_context.dirName=%s`, g_context.dirName);
	g_context.fileName = baseName(g_context.fullPath);
	writefln(`g_context.fileName=%s`, g_context.fileName);
	g_context.extension = extension(g_context.fileName); //.toLower;
	writefln(`g_context.extension=%s`, g_context.extension);
	g_context.baseName = baseName(g_context.fileName, g_context.extension);
	g_context.basePath = g_context.dirName ~ `/` ~ g_context.baseName;
	writefln(`g_context.basePath=%s`, g_context.basePath);
	switch (g_context.extension.toLower)
	{
	case ".exe":
		return handle_exe_output(args[2 .. $]);
	case ".json":
		break;
	default:
		assert(0);
		break;
	}
	auto jsonText = cast(char[]) read(g_context.fullPath);
	writeln(jsonText);
	auto jsonObj = parseJSON(jsonText);

	//JSONValue*[] path_array_list = get_path_array_list(&jsonObj);
	JSONValue*[] path_array_list;
	rewite_dub_json(&jsonObj, path_array_list, `[root]`);
	writeln(path_array_list.length);
	foreach (JSONValue* path_array; path_array_list)
	{
		if (path_array.type == JSON_TYPE.STRING)
		{
			path_array.str = make_abs_path(path_array.str);
			continue;
		}
		assert(path_array.type == JSON_TYPE.ARRAY);
		writeln(path_array.array.length);
		for (int i = 0; i < path_array.array.length; i++)
		{
			auto val = path_array.array[i];
			if (val.type() != JSON_TYPE.STRING)
				continue;
			path_array.array[i] = make_abs_path(val.str);
		}
	}

	auto jsonText2 = my_json_pprint(jsonObj);
	writeln(jsonText2);
	string folder_name = format!"%s.bin"(g_context.basePath);
	writeln(folder_name);
	mkdirRecurse(folder_name);
	try
	{
		auto currentTime = Clock.currTime();
		setTimes(folder_name, currentTime, currentTime);
	}
	catch (Exception ex)
	{
	}
	string dub_json_path = folder_name ~ "/dub.json";
	writeln(dub_json_path);
	File file1 = File(dub_json_path, "w");
	file1.write(jsonText2);
	file1.close();
	string[] dub_cmdline;
	dub_cmdline ~= "dub";
	for (int i = 2; i < args.length; i++)
	{
		if (args[i] == "--cleanup")
		{
			g_context.opt_cleanup = true;
		}
		else
		{
			dub_cmdline ~= args[i];
		}
	}
	/+
	if (dub_cmdline.length >= 2 && dub_cmdline[1] == "generate")
	{
		chdir(folder_name);
		writeln(dub_cmdline);
		int rc = emake_run_command(dub_cmdline);
		return rc;
	}
	+/
	dub_cmdline ~= format!`--root=%s`(folder_name);
	writeln(dub_cmdline);
	int rc = emake_run_command(dub_cmdline);
	if (rc == 0)
	{
		if (g_context.opt_cleanup)
		{
			try
			{
				rmdirRecurse(folder_name);
			}
			catch (Exception ex)
			{
			}
		}
	}
	return rc;
}
