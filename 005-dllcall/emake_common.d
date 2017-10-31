module emake_common;
import std.algorithm : startsWith, endsWith;
import std.array : split;
import std.path : baseName, extension;
import std.process : pipeProcess, wait, Redirect;
import std.stdio;

string remove_surrounding_underscore(string s)
{
	while (s.startsWith("_"))
	{
		s = s[1 .. $];
	}
	while (s.endsWith("_"))
	{
		s = s[0 .. $ - 1];
	}
	return s;
}

int emake_run_command(string[] dub_cmdline)
{
	auto pipes = pipeProcess(dub_cmdline, Redirect.stdout | Redirect.stderr);
	foreach (line; pipes.stdout.byLine)
		writeln(line);
	int rc = wait(pipes.pid);
	foreach (line; pipes.stderr.byLine)
		writeln(line);
	return rc;
}

class EmakeCommand
{
	bool valid;
	string compiler_type;
	string[] args;

	this(string compiler_type, string[] args)
	{
		this.compiler_type = compiler_type;
		this.args = args;
		this.parse_arguments();
	}

	~this()
	{
	}

	bool isValid()
	{
		return this.valid;
	}

	string[] command_type;
	string project_file_name;
	string project_file_ext;
	string project_base_name;
	string exe_base_name;
	string[] file_name_list;
	string[] import_dir_list;
	string[] lib_file_list;
	string[] linker_flags;
	string[] debug_arguments;

	bool check_command_type()
	{
		import std.uni: toLower;
		string header = this.args[0];
		string[] header_parse = header.split("=");
		for (int i=0; i<header_parse.length; i++)
		{
			header_parse[i] = toLower(header_parse[i]);
		}
		if (header_parse.length<2)
		{
			header_parse ~= "release";
		}
		switch (header_parse[0])
		{
		case "generate", "-":
			header_parse[0] = "generate";
			this.command_type = header_parse;
			args = args[1 .. $];
			break;
		case "edit":
			this.command_type = header_parse;
			args = args[1 .. $];
			break;
		case "build":
			this.command_type = header_parse;
			args = args[1 .. $];
			break;
		case "run":
			this.command_type = header_parse;
			args = args[1 .. $];
			break;
		default:
			this.command_type = ["generate", "release"];
			return false;
			break;
		}
		return true;
	}

	void parse_arguments()
	{
		this.valid = true;
		string prog_name = args[0];
		args = args[1 .. $];
		if (args.length < 3)
		{
			writefln("Usage: %s COMMAND PROJECT.exe source1 source2 ...", prog_name);
			this.valid = false;
			return;
		}

		if (!check_command_type())
		{
			writefln("Invalid command!");
			this.valid = false;
			return;
		}

		this.project_file_name = args[0];
		args = args[1 .. $];

		//writefln("project_file_name=%s", project_file_name);
		this.project_file_ext = extension(this.project_file_name);
		//writefln("project_file_ext=%s", project_file_ext);
		/+
        if (this.project_file_ext != ".exe")
        {
            writefln("Project file name is invalid: %s", project_file_name);
            this.valid = false;
            return;
        }
        +/
		this.project_base_name = baseName(this.project_file_name, this.project_file_ext);
		this.exe_base_name = remove_surrounding_underscore(project_base_name);
		for (int i = 0; i < args.length; i++)
		{
			if (args[i] == "--")
			{
				debug_arguments = args[i + 1 .. $];
				break;
			}
			if (args[i].startsWith("-LINK="))
			{
				//import_dir_list ~= args[i][2..$];
				linker_flags ~= args[i][6 .. $];
				continue;
			}
			if (args[i].startsWith("-L="))
			{
				//import_dir_list ~= args[i][2..$];
				linker_flags ~= args[i][3 .. $];
				continue;
			}
			// <Add directory="../../d-lib" />
			if (args[i].startsWith("-I"))
			{
				import_dir_list ~= args[i][2 .. $];
				//import_dir_list ~= args[i];
				continue;
			}
			string file_name_ext = extension(args[i]);
			if (file_name_ext == ".lib")
			{
				lib_file_list ~= args[i];
				continue;
			}
			file_name_list ~= args[i];
		}
	}
}
