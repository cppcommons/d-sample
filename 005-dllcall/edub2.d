module main;
import std.algorithm : startsWith, endsWith;
import std.array : split, replace;
import std.file : copy, exists, read, rename, remove, setTimes, write,
	FileException, PreserveAttributes;
import std.format : format;
import std.json;
import std.path : absolutePath, baseName, extension, isAbsolute;
import std.process : execute, executeShell;
import std.regex : regex, replaceAll;
import std.stdio : writefln, writeln, File;
import std.typecons : Yes, No;
import std.datetime.systime : Clock;
import std.process : pipeProcess, wait, Redirect;
import std.uuid : sha1UUID, UUID;

import emake_common : emake_run_command;

private void exit(int code)
{
	import std.c.stdlib;

	writeln("before exit()");
	std.c.stdlib.exit(0);
	writeln("after exit()");
}

private JSONValue* get_object_array_member(JSONValue* jsonObj, string key)
{
	JSONValue* member = cast(JSONValue*)(key in (*jsonObj));
	if (member.type() != JSON_TYPE.ARRAY)
		return null;
	return member;
}

private JSONValue*[] get_path_array_list(JSONValue* jsonObj)
{
	import std.regex;

	assert(jsonObj.type() == JSON_TYPE.OBJECT);
	JSONValue*[] result;
	auto re = regex(`^sourceFiles(-.+)?$`, "g");
	foreach (key; jsonObj.object.keys())
	{
		writeln("key=", key);
		if (key.matchAll(re))
		{
			////writeln("calling...");
			JSONValue* array = get_object_array_member(jsonObj, key);
			////writefln("array=0x%08x", array);
			if (array)
				result ~= array;
		}
	}
	string s = jsonObj.toString();
	//exit(0);
	return result;
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

int main(string[] args)
{
	//writeln(args.length);
	if (args.length < 2)
	{
		writefln("Usage: edub2 PROJECT.json [build/run]");
		return 1;
	}
	string project_file_name = args[1];
	writefln("project_file_name=%s", project_file_name);
	auto jsonText = cast(char[]) read(project_file_name);
	writeln(jsonText);
	auto jsonObj = parseJSON(jsonText);

	JSONValue*[] path_array_list = get_path_array_list(&jsonObj);
	writeln(path_array_list.length);
	foreach (JSONValue* path_array; path_array_list)
	{
		writeln(path_array.array.length);
		for (int i = 0; i < path_array.array.length; i++)
		{
			auto val = path_array.array[i];
			if (val.type() != JSON_TYPE.STRING)
				continue;
			string abs_path = val.str;
			if (!isAbsolute(abs_path))
				abs_path = absolutePath(abs_path);
			abs_path = abs_path.replace("\\", "/");
			writefln("%d: %s", i, abs_path);
			path_array.array[i] = JSONValue(abs_path);
		}
	}
	//exit(0);

	version (none)
	{
		jsonObj["name"] = "dummy-name";
		jsonObj["testArray"] = JSONValue(["A", "B", "C"]);
		jsonObj["subConfigurations"]["d2sqlite3"] = JSONValue(["A", "B", "C"]);
	}
	auto jsonText2 = my_json_pprint(jsonObj);
	writeln(jsonText2);
	File file1 = File(project_file_name ~ ".json", "w");
	file1.write(jsonText2);
	file1.close();
	return 0;
	try
	{
		copy(project_file_name, "dub.json", Yes.preserveAttributes);
		auto currentTime = Clock.currTime();
		setTimes("dub.json", currentTime, currentTime);
		writefln("Copy successful: %s ==> dub.json", project_file_name);
	}
	catch (FileException ex)
	{
		writefln("Copy failure: %s", project_file_name);
		return 1;
	}
	try
	{
		if (exists("dub.selections.json"))
			remove("dub.selections.json");
	}
	catch (FileException ex)
	{
		//writefln("Remove failure: dub.selections.json", project_file_name);
	}
	if (args.length == 2)
	{
		return 0;
	}
	string[] dub_cmdline;
	dub_cmdline ~= "dub";
	for (int i = 2; i < args.length; i++)
	{
		dub_cmdline ~= args[i];
	}
	writeln(dub_cmdline);
	int rc = emake_run_command(dub_cmdline);
	//auto pipes = pipeProcess(dub_cmdline, Redirect.stdout | Redirect.stderr);
	//foreach (line; pipes.stdout.byLine)
	//    writeln(line);
	//int rc = wait(pipes.pid);
	try
	{
		if (exists("dub.selections.json"))
			rename("dub.selections.json", project_file_name ~ ".selections");
	}
	catch (FileException ex)
	{
	}
	return rc;
}
