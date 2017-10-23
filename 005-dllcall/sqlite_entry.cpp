#include <windows.h>
#include <stdio.h>

extern "C" void *sqlite_get_proc(const char *proc_name);

static void write_abs_jump(unsigned char *opcodes, const void *jmpdest)
{
	// Taken from: https://www.gamedev.net/forums/topic/566233-x86-asm-help-understanding-jmp-opcodes/
	opcodes[0] = 0xFF;
	opcodes[1] = 0x25;
	*reinterpret_cast<DWORD *>(opcodes + 2) = reinterpret_cast<DWORD>(opcodes + 6);
	*reinterpret_cast<DWORD *>(opcodes + 6) = reinterpret_cast<DWORD>(jmpdest);
}

static void register_proc(const char *name, unsigned char *opcode)
{
	void *proc = sqlite_get_proc(name);
	write_abs_jump(opcode, proc);
}

class ExportedFunction {
public:
	unsigned char opcode[16];
	explicit ExportedFunction(const char *name)
	{
		printf("ExportedFunction(const char *name): %s\n", name);
		register_proc(name, opcode);
	}
};

#define export_fun2(X) extern "C" ExportedFunction X(#X)

export_fun2(sqlite3_bind_double);
export_fun2(sqlite3_bind_int64);
export_fun2(sqlite3_bind_null);
export_fun2(sqlite3_bind_parameter_count);
export_fun2(sqlite3_bind_parameter_index);
export_fun2(sqlite3_bind_parameter_name);
export_fun2(sqlite3_bind_text64);
export_fun2(sqlite3_changes);
export_fun2(sqlite3_clear_bindings);
export_fun2(sqlite3_close);
export_fun2(sqlite3_column_blob);
export_fun2(sqlite3_column_bytes);
export_fun2(sqlite3_column_count);
export_fun2(sqlite3_column_decltype);
export_fun2(sqlite3_column_double);
export_fun2(sqlite3_column_int64);
export_fun2(sqlite3_column_name);
export_fun2(sqlite3_column_text);
export_fun2(sqlite3_column_type);
export_fun2(sqlite3_commit_hook);
export_fun2(sqlite3_complete);
export_fun2(sqlite3_db_filename);
export_fun2(sqlite3_db_handle);
export_fun2(sqlite3_db_readonly);
export_fun2(sqlite3_enable_load_extension);
export_fun2(sqlite3_errcode);
export_fun2(sqlite3_errmsg);
export_fun2(sqlite3_finalize);
export_fun2(sqlite3_interrupt);
export_fun2(sqlite3_last_insert_rowid);
export_fun2(sqlite3_load_extension);
export_fun2(sqlite3_open_v2);
export_fun2(sqlite3_prepare_v2);
export_fun2(sqlite3_profile);
export_fun2(sqlite3_progress_handler);
export_fun2(sqlite3_reset);
export_fun2(sqlite3_rollback_hook);
export_fun2(sqlite3_step);
export_fun2(sqlite3_table_column_metadata);
export_fun2(sqlite3_total_changes);
export_fun2(sqlite3_trace);
export_fun2(sqlite3_update_hook);
