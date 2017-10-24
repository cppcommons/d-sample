#include <windows.h>
#include <stdio.h>

extern "C" void *sqlite_get_proc(const char *proc_name);

class ExportedFunction
{
  public:
	unsigned char opcodes[16];
	explicit ExportedFunction(const char *name)
	{
		printf("ExportedFunction(const char *name): %s\n", name);
		void *jmpdest = sqlite_get_proc(name);
		opcodes[0] = 0xFF;
		opcodes[1] = 0x25;
		*reinterpret_cast<DWORD *>(opcodes + 2) = reinterpret_cast<DWORD>(opcodes + 6);
		*reinterpret_cast<DWORD *>(opcodes + 6) = reinterpret_cast<DWORD>(jmpdest);
	}
};

#define export_fun(X) extern "C" ExportedFunction X(#X)

export_fun(sqlite3_bind_double);
export_fun(sqlite3_bind_int64);
export_fun(sqlite3_bind_null);
export_fun(sqlite3_bind_parameter_count);
export_fun(sqlite3_bind_parameter_index);
export_fun(sqlite3_bind_parameter_name);
export_fun(sqlite3_bind_text64);
export_fun(sqlite3_changes);
export_fun(sqlite3_clear_bindings);
export_fun(sqlite3_close);
export_fun(sqlite3_column_blob);
export_fun(sqlite3_column_bytes);
export_fun(sqlite3_column_count);
export_fun(sqlite3_column_decltype);
export_fun(sqlite3_column_double);
export_fun(sqlite3_column_int64);
export_fun(sqlite3_column_name);
export_fun(sqlite3_column_text);
export_fun(sqlite3_column_type);
export_fun(sqlite3_commit_hook);
export_fun(sqlite3_complete);
export_fun(sqlite3_db_filename);
export_fun(sqlite3_db_handle);
export_fun(sqlite3_db_readonly);
export_fun(sqlite3_enable_load_extension);
export_fun(sqlite3_errcode);
export_fun(sqlite3_errmsg);
export_fun(sqlite3_finalize);
export_fun(sqlite3_interrupt);
export_fun(sqlite3_last_insert_rowid);
export_fun(sqlite3_load_extension);
export_fun(sqlite3_open_v2);
export_fun(sqlite3_prepare_v2);
export_fun(sqlite3_profile);
export_fun(sqlite3_progress_handler);
export_fun(sqlite3_reset);
export_fun(sqlite3_rollback_hook);
export_fun(sqlite3_step);
export_fun(sqlite3_table_column_metadata);
export_fun(sqlite3_total_changes);
export_fun(sqlite3_trace);
export_fun(sqlite3_update_hook);
