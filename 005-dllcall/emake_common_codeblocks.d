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

void add_option(ref Element elem, string opt_name, string opt_value)
{
    auto opt = new Element("Option");
    elem ~= opt;
    opt.tag.attr[opt_name] = opt_value;
}

void put_build_target(ref Element elem, Target record)
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
    target.add_option("object_output", record.object_output);
    /+
    opt = new Element("Option");
    target ~= opt;
    opt.tag.attr["object_output"] = record.object_output;
    +/
    target.add_option("type", record.type);
    /+
    opt = new Element("Option");
    target ~= opt;
    opt.tag.attr["type"] = record.type;
    +/
    target.add_option("compiler", record.compiler);
    /+
    opt = new Element("Option");
    target ~= opt;
    opt.tag.attr["compiler"] = record.compiler;
    +/
    if (record.debug_arguments.length > 0)
    {
        target.add_option("parameters", record.debug_arguments.join(" "));
        /+
        opt = new Element("Option");
        target ~= opt;
        opt.tag.attr["parameters"] = record.debug_arguments.join(" ");
        +/
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
