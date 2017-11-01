module main;
import std.algorithm : startsWith, endsWith;
import std.array : replace;
import std.file : copy, exists, read, rename, remove, setTimes, write,
	FileException, PreserveAttributes;
import std.json;
import std.path : absolutePath, baseName, extension, isAbsolute;
import std.process : execute, executeShell;
import std.stdio : writefln, writeln, File;
import std.typecons : Yes, No;
import std.datetime.systime : Clock;
import std.process : pipeProcess, wait, Redirect;

import emake_common : emake_run_command;

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
	if (const(JSONValue)* name = "name" in jsonObj)
	{
		//if (code.type() == JSON_TYPE.INTEGER)
		//	x = code.integer;
		//else
		//	x = to!int(code.str);
		writeln(`jsonObj["name"]=`, jsonObj["name"]);

	}
	if (const(JSONValue)* nameX = "nameX" in jsonObj)
	{
		//if (code.type() == JSON_TYPE.INTEGER)
		//	x = code.integer;
		//else
		//	x = to!int(code.str);
		writeln(`jsonObj["nameX"]=`, jsonObj["nameX"]);
	}
	//if (const(JSONValue)* sourceFiles = "sourceFiles" in jsonObj)
	if (JSONValue* sourceFiles = cast(JSONValue*)("sourceFiles" in jsonObj))
	{
		if (sourceFiles.type() == JSON_TYPE.ARRAY)
		{
			//JSONValue[] *sourceFilesArray = &(sourceFiles.array);
			for (int i = 0; i < sourceFiles.array.length; i++)
			{
				auto val = sourceFiles.array[i];
				if (val.type() != JSON_TYPE.STRING)
					continue;
				string abs_path = val.str;
				if (!isAbsolute(abs_path))
					abs_path = absolutePath(abs_path);
				abs_path = abs_path.replace("\\", "/");
				writefln("%d: %s", i, abs_path);
				sourceFiles.array[i] = JSONValue(abs_path);
				//JSONValue[] x;
				//sourceFiles.array = x;
				//sourceFiles.array ~= JSONValue(abs_path);
			}
		}
		//if (code.type() == JSON_TYPE.INTEGER)
		//	x = code.integer;
		//else
		//	x = to!int(code.str);
		writeln(`jsonObj["sourceFiles"]=`, jsonObj["sourceFiles"]);

	}
	writeln(jsonObj.object.keys);
	//writeln(jsonObj["name"]);
	//writeln(jsonObj["nameX"]);
	jsonObj["name"] = "dummy-name";
	jsonObj["testArray"] = JSONValue(["A", "B", "C"]);
	jsonObj["subConfigurations"]["d2sqlite3"] = JSONValue(["A", "B", "C"]);
	jsonObj["000-name"] = jsonObj["name"];
	jsonObj.object.remove("name");
	//auto jsonText2 = toJSON(jsonObj);
	auto jsonText2 = jsonObj.toPrettyString();
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
