module emake_common_codeblocks;
import emake_common;

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
