module main;
import std.algorithm : canFind, startsWith, endsWith;
import std.array : split, replace;
import std.file : chdir, copy, exists, getcwd, mkdirRecurse, read, rename,
	remove, setTimes, write, FileException, PreserveAttributes;
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
		: 5, "license" : 6, "targetType" : 7, "targetName" : 8, "targetPath" : 9,
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

private void handle_exe_output(string[] args)
{
	string pop(ref string[] list)
	{
		if (list.length == 0)
			return "[eoi]";
		string result = list[0];
		list = list[1 .. $];
		return result;
	}

	writeln(`handle_exe_output:`, args);
	string command = pop(args);
	writefln(`handle_exe_output: %s %s %s`, g_context.fileName, command, args);
	switch (command)
	{
	case `build`:
		break;
	default:
		writefln(`Invalid command "%s".`, command);
		exit(1);
	}
	string dub_json_path = format!`%s.json`(g_context.fullPath);
	writefln(`dub_json_path="%s"`, dub_json_path);
	int[string] dummyAlist;
	JSONValue jsonObj = dummyAlist;
	jsonObj["name"] = g_context.baseName.toLower;
	jsonObj["targetName"] = g_context.baseName;
	jsonObj["targetType"] = "executable";
	string[] source_files;
	string[] include_dirs;
	string[] datadir_dirs;
	string[] libs;
	while(args.length)
	{
		string arg = pop(args).strip;
		writefln(`arg="%s"`, arg);
		auto re = regex(`^\[([^:]+)(:[^:]+)?(:[^:]+)?\]$`);
		auto m = matchFirst(arg, re);
		if (m) 
		{
			writeln(`match!`);
			writefln(`match="%s" "%s" "%s"`, m[1], m[2], m[3]);
		}
		else if (arg.startsWith(`datadir=`))
		{
			datadir_dirs ~= arg[8..$];
		}
		else if (arg.startsWith(`include=`))
		{
			include_dirs ~= arg[8..$];
		}
		else if (arg.startsWith(`libs=`))
		{
			libs ~= arg[5..$].split(`:`);
		}
		else
		{
			source_files ~= arg;
		}
	}
	if (source_files) jsonObj["sourceFiles"] = source_files;
	if (include_dirs) jsonObj["importPaths"] = include_dirs;
	if (datadir_dirs) jsonObj["stringImportPaths"] = datadir_dirs;
	if (libs) jsonObj["libs"] = libs;
	//stringImportPaths
	string json = my_json_pprint(jsonObj);
	writeln(json);
	exit(0);
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
		handle_exe_output(args[2 .. $]);
		return 0;
		break;
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
		dub_cmdline ~= args[i];
	}
	if (dub_cmdline.length >= 2 && dub_cmdline[1] == "generate")
	{
		chdir(folder_name);
		writeln(dub_cmdline);
		int rc = emake_run_command(dub_cmdline);
		return rc;
	}
	dub_cmdline ~= format!`--root=%s`(folder_name);
	writeln(dub_cmdline);
	int rc = emake_run_command(dub_cmdline);
	return rc;
}
