#include <windows.h>
#include <stdio.h>

extern "C" void *libcurl_get_proc(const char *proc_name);

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
	void *proc = libcurl_get_proc(name);
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

export_fun2(curl_easy_cleanup);
export_fun2(curl_easy_duphandle);
export_fun2(curl_easy_escape);
export_fun2(curl_easy_getinfo);
export_fun2(curl_easy_init);
export_fun2(curl_easy_pause);
export_fun2(curl_easy_perform);
export_fun2(curl_easy_recv);
export_fun2(curl_easy_reset);
export_fun2(curl_easy_send);
export_fun2(curl_easy_setopt);
export_fun2(curl_easy_strerror);
export_fun2(curl_easy_unescape);
export_fun2(curl_escape);
export_fun2(curl_formadd);
export_fun2(curl_formfree);
export_fun2(curl_formget);
export_fun2(curl_free);
export_fun2(curl_getdate);
export_fun2(curl_getenv);
export_fun2(curl_global_cleanup);
export_fun2(curl_global_init);
export_fun2(curl_global_init_mem);
export_fun2(curl_maprintf);
export_fun2(curl_mfprintf);
export_fun2(curl_mprintf);
export_fun2(curl_msnprintf);
export_fun2(curl_msprintf);
export_fun2(curl_multi_add_handle);
export_fun2(curl_multi_assign);
export_fun2(curl_multi_cleanup);
export_fun2(curl_multi_fdset);
export_fun2(curl_multi_info_read);
export_fun2(curl_multi_init);
export_fun2(curl_multi_perform);
export_fun2(curl_multi_remove_handle);
export_fun2(curl_multi_setopt);
export_fun2(curl_multi_socket);
export_fun2(curl_multi_socket_action);
export_fun2(curl_multi_socket_all);
export_fun2(curl_multi_strerror);
export_fun2(curl_multi_timeout);
export_fun2(curl_multi_wait);
export_fun2(curl_mvaprintf);
export_fun2(curl_mvfprintf);
export_fun2(curl_mvprintf);
export_fun2(curl_mvsnprintf);
export_fun2(curl_mvsprintf);
export_fun2(curl_pushheader_byname);
export_fun2(curl_pushheader_bynum);
export_fun2(curl_share_cleanup);
export_fun2(curl_share_init);
export_fun2(curl_share_setopt);
export_fun2(curl_share_strerror);
export_fun2(curl_slist_append);
export_fun2(curl_slist_free_all);
export_fun2(curl_strequal);
export_fun2(curl_strnequal);
export_fun2(curl_unescape);
export_fun2(curl_version);
export_fun2(curl_version_info);
