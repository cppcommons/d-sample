extern "C" {
#include "os2.h"
#define EXPORT_FUNCTION extern "C" __declspec(dllexport)
typedef int (*proc_main)(int argc, const char **argv);
EXPORT_FUNCTION int main(int argc, const char **argv);
EXPORT_FUNCTION os_int32 vc6_add2(os_int32 a, os_int32 b);

#ifdef __HTOD__
struct easy_svn_context
{
};
#endif /* __HTOD__ */

#ifdef __HTOD__
/** The various types of nodes in the Subversion filesystem. */
typedef enum svn_node_kind_t {
	/** absent */
	svn_node_none,

	/** regular file */
	svn_node_file,

	/** directory */
	svn_node_dir,

	/** something's here, but we don't know what */
	svn_node_unknown,

	/**
   * symbolic link
   * @note This value is not currently used by the public API.
   * @since New in 1.8.
   */
	svn_node_symlink
} svn_node_kind_t;

typedef __int64 apr_int64_t;
typedef apr_int64_t svn_filesize_t;
typedef int svn_boolean_t;
typedef long int svn_revnum_t;
typedef apr_int64_t apr_time_t;

typedef struct svn_dirent_t
{
	/** node kind */
	svn_node_kind_t kind;

	/** length of file text, or 0 for directories */
	svn_filesize_t size;

	/** does the node have props? */
	svn_boolean_t has_props;

	/** last rev in which this node changed */
	svn_revnum_t created_rev;

	/** time of created_rev (mod-time) */
	apr_time_t time;

	/** author of created_rev */
	const char *last_author;

	/* IMPORTANT: If you extend this struct, check svn_dirent_dup(). */
} svn_dirent_t;
#else
#include "svn_client.h"
#include "svn_cmdline.h"
#include "svn_pools.h"
#include "svn_config.h"
#include "svn_fs.h"
#include "svn_auth.h"
#endif /* __HTOD__ */

typedef struct easy_svn_dirent
{
	const char *entryname;
	svn_dirent_t entry;
} easy_svn_dirent;

EXPORT_FUNCTION struct easy_svn_context *easy_svn_create();
typedef struct easy_svn_context *(*proc_easy_svn_create)();
EXPORT_FUNCTION void easy_svn_destroy(struct easy_svn_context *context);
typedef void (*proc_easy_svn_destroy)(struct easy_svn_context *context);
EXPORT_FUNCTION struct easy_svn_dirent *easy_svn_ls(easy_svn_context *context, const char *url, bool recursive);
typedef struct easy_svn_dirent *(*proc_easy_svn_ls)(easy_svn_context *context, const char *url, bool recursive);
} // extern "C"

static proc_easy_svn_create _proc_easy_svn_create = easy_svn_create;
static proc_easy_svn_destroy _proc_easy_svn_destroy = easy_svn_destroy;
static proc_easy_svn_ls _proc_easy_svn_ls = easy_svn_ls;


#ifndef __HTOD__

EXPORT_FUNCTION os_int32 vc6_add2(os_int32 a, os_int32 b)
{
	return a + b;
}

//#include "svn_types.h"
#include <vector>

typedef std::vector<easy_svn_dirent> easy_snv_ls_result;

struct easy_svn_context
{
	apr_pool_t *pool;
	svn_client_ctx_t *ctx;
	svn_auth_baton_t *ab;
	explicit easy_svn_context()
	{
		this->pool = NULL;
		this->ctx = NULL;
		this->ab = NULL;
	}
	virtual ~easy_svn_context()
	{
		for (size_t i = 0; i < this->ls_results.size(); i++)
		{
			delete this->ls_results[i];
		}
		if (this->pool)
			svn_pool_destroy(this->pool);
	}
	std::vector<easy_snv_ls_result *> ls_results;
};

#include <windows.h>
//#include <string>
//#include <vector>
//#include <map>
//#include <mutex>
#if 0x1
extern "C" __declspec(dllexport) void CALLBACK sayHello(HWND, HINSTANCE, wchar_t const *, int)
{
	//::MessageBoxA(NULL, "aaa", "bbb", MB_OK);
	AllocConsole();
	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);

	//DWORD const infoBoxOptions = MB_ICONINFORMATION | MB_SETFOREGROUND;
	//MessageBoxW(0, L"Before call...", L"DLL message:", infoBoxOptions);
	//std::vector<char *> args;
	//args.push_back("dummy.exe");
	//args.push_back("https://github.com/cppcommons/d-sample/trunk");
	const char *args[2] = {"dummy.exe", "https://github.com/cppcommons/d-sample/trunk"};
	//myCode::sayHello();
	main(2, args);
	//MessageBoxW(0, L"After call...", L"DLL message:", infoBoxOptions);
	return;
}
#endif
typedef int (*proc_svn_cmdline_init)(const char *progname,
									 FILE *error_stream);

EXPORT_FUNCTION struct easy_svn_context *easy_svn_create()
{
	/* Initialize the app.  Send all error messages to 'stderr'.  */
	if (svn_cmdline_init("easy_svn", stderr) != EXIT_SUCCESS)
	{
		return NULL;
	}

	easy_svn_context *context = new easy_svn_context();
	context->pool = svn_pool_create(NULL);

	svn_error_t *err;
	/* Initialize the FS library. */
	err = svn_fs_initialize(context->pool);
	if (err)
	{
		svn_handle_error(err, stderr, FALSE);
		goto label_error;
	}

	/* Initialize and allocate the client_ctx object. */
	if ((err = svn_client_create_context(&context->ctx, context->pool)))
	{
		svn_handle_error(err, stderr, FALSE);
		goto label_error;
	}

	/* Load the run-time config file into a hash */
	if ((err = svn_config_get_config(&(context->ctx->config), NULL, context->pool)))
	{
		svn_handle_error(err, stderr, FALSE);
		goto label_error;
	}

	//svn_auth_baton_t *ab;

	if ((err = svn_cmdline_create_auth_baton(&context->ab,
											 1,	//opt_state.non_interactive,
											 NULL, //opt_state.auth_username,
											 NULL, //opt_state.auth_password,
											 NULL, //opt_state.config_dir,
											 1,	//opt_state.no_auth_cache,
											 1,	//opt_state.trust_server_cert,
											 NULL, //cfg_config,
											 context->ctx->cancel_func,
											 context->ctx->cancel_baton,
											 context->pool)))
	{
		svn_handle_error(err, stderr, FALSE);
		goto label_error;
	}

	context->ctx->auth_baton = context->ab;

	return context;
label_error:
	delete context;
	return NULL;
}

EXPORT_FUNCTION void easy_svn_destroy(struct easy_svn_context *context)
{
	if (!context)
		return;
	delete context;
}

EXPORT_FUNCTION struct easy_svn_dirent *easy_svn_ls(easy_svn_context *context, const char *url, bool recursive)
{
	if (!context)
		return NULL;
	svn_error_t *err;
	svn_opt_revision_t revision;
	apr_hash_t *dirents;
	apr_hash_index_t *hi;
	//typedef std::vector<easy_svn_dirent> easy_snv_ls_result;
	//std::vector<easy_snv_ls_result *> ls_results;
	easy_snv_ls_result *result = new easy_snv_ls_result();
	context->ls_results.push_back(result);
	/* Set revision to always be the HEAD revision.  It could, however,
     be set to a specific revision number, date, or other values. */
	revision.kind = svn_opt_revision_head;

	/* Main call into libsvn_client does all the work. */
	err = svn_client_ls(&dirents,
						url, &revision,
						(svn_boolean_t)recursive,
						context->ctx, context->pool);
	if (err)
	{
		svn_handle_error(err, stderr, FALSE);
		return NULL;
	}
	/* Print the dir entries in the hash. */
	for (hi = apr_hash_first(context->pool, dirents); hi; hi = apr_hash_next(hi))
	{
		const char *entryname;
		svn_dirent_t *val;

		apr_hash_this(hi, (const void **)&entryname, NULL, (void **)&val);
		//printf("   %s %ld %s %u\n", entryname, val->created_rev, val->last_author, val->size);

		easy_svn_dirent entry;
		entry.entryname = entryname;
		entry.entry = *val;
		(*result).push_back(entry);

		/* 'val' is actually an svn_dirent_t structure; a more complex
          program would mine it for extra printable information. */
	}
	easy_svn_dirent entry;
	entry.entryname = NULL;
	(*result).push_back(entry);
	return &(*result)[0];
}

EXPORT_FUNCTION int main(int argc, const char **argv)
{
	//apr_pool_t *pool;
	//svn_error_t *err;
	//svn_opt_revision_t revision;
	//apr_hash_t *dirents;
	//apr_hash_index_t *hi;
	//svn_client_ctx_t *ctx;
	const char *URL;
	//svn_auth_baton_t *ab;
	proc_svn_cmdline_init func_p;

	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);
	if (1)
	{
		os_int32 test_int = vc6_add2(111, 222);
		printf("test_int=%d\n", test_int);
	}
	func_p = svn_cmdline_init;

	printf("argc=%d\n", argc);

	//std::mutex v_mutex;
	//v_mutex.lock();
	//v_mutex.unlock();

	os_int64 ll = 1234;
	os_uint64 ll2 = 1234;
	os_size_t ll3 = 1234;

	os_int32 answer = add(11, 22);
	printf("answer=%d\n", answer);

	os_object o = os_new_integer(12345);
	os_new_integer(6789);
	os_int64 o2 = os_get_integer(o);
	printf("o2=%lld\n", o2);
	os_new_string("xyz");

	os_dump_heap();

	printf("0.1\n");
	if (argc <= 1)
	{
		//printf("Usage:  %s URL\n", argv[0]);
		//return EXIT_FAILURE;
		URL = "https://github.com/cppcommons/d-sample/trunk";
	}
	else
		URL = argv[1];

	printf("xURL=%s\n", URL);

	easy_svn_context *context = easy_svn_create();
	if (!context)
	{
		printf("0.2\n");
		return EXIT_FAILURE;
	}

	/* Now do the real work. */

	printf("7\n");
#if 0x0
	/* Set revision to always be the HEAD revision.  It could, however,
     be set to a specific revision number, date, or other values. */
	revision.kind = svn_opt_revision_head;

	/* Main call into libsvn_client does all the work. */
	err = svn_client_ls(&dirents,
						URL, &revision,
						FALSE, /* no recursion */
						context->ctx, context->pool);
	if (err)
	{
		svn_handle_error2(err, stderr, FALSE, "minimal_client: ");
		return EXIT_FAILURE;
	}

	printf("8\n");
	/* Print the dir entries in the hash. */
	for (hi = apr_hash_first(context->pool, dirents); hi; hi = apr_hash_next(hi))
	{
		const char *entryname;
		svn_dirent_t *val;

		apr_hash_this(hi, (const void **)&entryname, NULL, (void **)&val);
		printf("   %s %ld %s %u\n", entryname, val->created_rev, val->last_author, val->size);

		/* 'val' is actually an svn_dirent_t structure; a more complex
          program would mine it for extra printable information. */
	}
#endif
	easy_svn_dirent *entries = easy_svn_ls(context, URL, false);

	if (entries)
	{
		for (; entries->entryname; entries++)
		{
			//printf("entiries=0x%p %s\n", entries, entries->entryname);
			printf("   %s %ld %s %u\n",
				   entries->entryname,
				   entries->entry.created_rev,
				   entries->entry.last_author,
				   entries->entry.size);
		}
	}

	easy_svn_destroy(context);

	printf("9\n");
	return EXIT_SUCCESS;
}
#endif //if !defined(__HTOD__)
