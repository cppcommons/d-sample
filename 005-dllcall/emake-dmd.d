module main;
import std.algorithm : startsWith, endsWith;
import std.file : copy, setTimes, FileException, PreserveAttributes;
import std.path : baseName, extension;
import std.process : execute, executeShell;
import std.stdio;
import std.typecons : Yes, No;
import std.datetime.systime : Clock;
import std.xml;
import std.string;

import emake_common;

private struct Target
{
    string title;
    string output;
    string object_output;
    string type;
    string compiler;
    string[] compiler_options;
    string[] lib_file_list;
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
    if (record.compiler_options.length > 0)
    {
        auto compiler = new Element("Compiler");
        target ~= compiler;
        foreach (compiler_option; record.compiler_options)
        {
            auto add = new Element("Add");
            compiler ~= add;
            if (compiler_option.startsWith("-I"))
            {
                // <Add directory="../../d-lib" />
                add.tag.attr["directory"] = compiler_option[2 .. $];
            }
            else
            {
                add.tag.attr["option"] = compiler_option;
            }
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

int main(string[] args)
{
    writeln(args.length);
    if (args.length < 3)
    {
        writefln("Usage: emake-dmd PROJECT.exe source1.d source2.d ...");
        return 1;
    }
    string project_file_name = args[1];
    //writefln("project_file_name=%s", project_file_name);
    string project_file_ext = extension(project_file_name);
    //writefln("project_file_ext=%s", project_file_ext);
    if (project_file_ext != ".exe")
    {
        writefln("Project file name is invalid: %s", project_file_name);
        return 1;
    }
    string project_base_name = baseName(project_file_name, project_file_ext);
    writefln("project_base_name=%s", project_base_name);
    string[] file_name_list;
    string[] import_dir_list;
    string[] lib_file_list;
    for (int i = 2; i < args.length; i++)
    {
        // <Add directory="../../d-lib" />
        if (args[i].startsWith("-I"))
        {
            //import_dir_list ~= args[i][2..$];
            import_dir_list ~= args[i];
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

    string exe_base_name = remove_surrounding_underscore(project_base_name);
    File file1 = File(project_base_name ~ ".cbp", "w");
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
    add_option(project, "title", project_base_name);
    /* <Option compiler="dmd" /> */
    add_option(project, "compiler", "dmd");

    /* <Build> */
    auto build = new Element("Build");
    project ~= build;

    Target targetDebug;
    targetDebug.title = "Debug";
    targetDebug.output = exe_base_name ~ "_d";
    targetDebug.object_output = project_base_name ~ ".bin/dmd-obj/Debug/";
    targetDebug.type = "1";
    targetDebug.compiler = "dmd";
    targetDebug.compiler_options = ["-g", "-debug"];
    foreach (import_dir; import_dir_list)
    {
        targetDebug.compiler_options ~= import_dir;
    }
    targetDebug.lib_file_list = lib_file_list;
    put_build_target(build, targetDebug);

    Target targetRelease;
    targetRelease.title = "Release";
    targetRelease.output = exe_base_name;
    targetRelease.object_output = project_base_name ~ ".bin/dmd-obj/Release/";
    targetRelease.type = "1";
    targetRelease.compiler = "dmd";
    targetRelease.compiler_options = ["-O"];
    foreach (import_dir; import_dir_list)
    {
        targetRelease.compiler_options ~= import_dir;
    }
    targetRelease.lib_file_list = lib_file_list;
    put_build_target(build, targetRelease);

    foreach (file_name; file_name_list)
    {
        /* <Unit filename="emake-dmd.d" /> */
        auto unit = new Element("Unit");
        project ~= unit;
        unit.tag.attr["filename"] = file_name;
    }

    // Pretty-print
    writefln(join(doc.pretty(4), "\n"));

    file1.write(join(doc.pretty(4), "\n"));
    file1.close();
    return 0;
}
