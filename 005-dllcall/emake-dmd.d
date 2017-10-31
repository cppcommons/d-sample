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

    this(EmakeCommand emake_cmd)
    {
        this.emake_cmd = emake_cmd;
        this.doc = new Document(new Tag("CodeBlocks_project_file"));
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
    ////writeln(args.length);
    auto emake_cmd = new EmakeCommand("dmd", args);
    if (!emake_cmd.isValid())
        return 1;

    writefln("Command type: %s", emake_cmd.command_type);

    //File file1 = File(emake_cmd.project_file_name ~ ".cbp", "w");
    //file1.writeln(`<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>`);

    auto cbp = new CodeblocksProject(emake_cmd);
    //auto doc = new Document(new Tag("CodeBlocks_project_file"));
    /* 	<FileVersion major="1" minor="6" /> */
    auto fileVersion = new Element("FileVersion");
    cbp.doc ~= fileVersion;
    fileVersion.tag.attr["major"] = "1";
    fileVersion.tag.attr["minor"] = "6";
    /* <Project> */
    auto project = new Element("Project");
    cbp.doc ~= project;
    /* <Option title="emake-dmd" /> */
    void add_option(ref Element elem, string opt_name, string opt_value)
    {
        auto opt = new Element("Option");
        elem ~= opt;
        opt.tag.attr[opt_name] = opt_value;
    }

    //add_option(project, "title", exe_base_name);
    writeln("emake_cmd.project_file_name=", emake_cmd.project_file_name);
    add_option(project, "title", emake_cmd.project_file_name);
    /* <Option compiler="dmd" /> */
    add_option(project, "compiler", emake_cmd.compiler_type);

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
    //targetDebug.output = emake_cmd.project_file_name ~ ".bin/" ~ emake_cmd.exe_base_name ~ "_d";
    targetDebug.output = emake_cmd.exe_base_name ~ "_d";
    targetDebug.object_output = emake_cmd.project_file_name ~ ".bin/dmd-obj/Debug/";
    targetDebug.type = get_build_type_number(emake_cmd.project_file_ext); //"1";
    targetDebug.compiler = emake_cmd.compiler_type;
    targetDebug.compiler_options = ["-g", "-debug"];
    targetDebug.import_dir_list = emake_cmd.import_dir_list;
    targetDebug.lib_file_list = emake_cmd.lib_file_list;
    targetDebug.debug_arguments = emake_cmd.debug_arguments;
    put_build_target(build, targetDebug);

    Target targetRelease;
    targetRelease.title = "Release";
    //targetRelease.output = emake_cmd.project_file_name ~ ".bin/" ~ emake_cmd.exe_base_name ~ "_r";
    targetRelease.output = emake_cmd.exe_base_name;
    targetRelease.object_output = emake_cmd.project_file_name ~ ".bin/dmd-obj/Release/";
    targetRelease.type = get_build_type_number(emake_cmd.project_file_ext); //"1";
    targetRelease.compiler = emake_cmd.compiler_type;
    targetRelease.compiler_options = ["-O"];
    targetRelease.import_dir_list = emake_cmd.import_dir_list;
    targetRelease.lib_file_list = emake_cmd.lib_file_list;
    targetRelease.debug_arguments = emake_cmd.debug_arguments;
    put_build_target(build, targetRelease);

    foreach (file_name; emake_cmd.file_name_list)
    {
        /* <Unit filename="emake-dmd.d" /> */
        auto unit = new Element("Unit");
        project ~= unit;
        unit.tag.attr["filename"] = file_name;
    }

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
        string[] cb_command = ["codeblocks", //"/na", "/nd",
            emake_cmd.project_file_name ~ ".cbp"];
        writeln(cb_command);
        execute(cb_command);
        break;
    case "build", "run":
        string[] cb_command = [
            "codeblocks", //"/na", "/nd",
            "--target=Release", "--build", emake_cmd.project_file_name ~ ".cbp"
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
