/* Converted to D from vc6.cpp by htod */
module vc6;
import os2;
extern (C):
alias int  function(int argc, char **argv)proc_main;
int  main(int argc, char **argv);
os_int32  vc6_add2(os_int32 a, os_int32 b);

//#include "svn_types.h"

struct easy_svn_context
{
}

/** The various types of nodes in the Subversion filesystem. */
  /** absent */

  /** regular file */

  /** directory */

  /** something's here, but we don't know what */

  /**
   * symbolic link
   * @note This value is not currently used by the public API.
   * @since New in 1.8.
   */
enum svn_node_kind_t
{
    svn_node_none,
    svn_node_file,
    svn_node_dir,
    svn_node_unknown,
    svn_node_symlink,
}

alias long apr_int64_t;
alias apr_int64_t svn_filesize_t;
alias int svn_boolean_t;
alias int svn_revnum_t;
alias apr_int64_t apr_time_t;

  /** node kind */

  /** length of file text, or 0 for directories */

  /** does the node have props? */

  /** last rev in which this node changed */

  /** time of created_rev (mod-time) */

  /** author of created_rev */

  /* IMPORTANT: If you extend this struct, check svn_dirent_dup(). */
struct svn_dirent_t
{
    int kind;
    svn_filesize_t size;
    svn_boolean_t has_props;
    svn_revnum_t created_rev;
    apr_time_t time;
    char *last_author;
}

easy_svn_context * easy_svn_create(char *progname);



//#include <string>
//#include <vector>
//#include <map>
//#include <mutex>
	//::MessageBoxA(NULL, "aaa", "bbb", MB_OK);

	//DWORD const infoBoxOptions = MB_ICONINFORMATION | MB_SETFOREGROUND;
	//MessageBoxW(0, L"Before call...", L"DLL message:", infoBoxOptions);
	//std::vector<char *> args;
	//args.push_back("dummy.exe");
	//args.push_back("https://github.com/cppcommons/d-sample/trunk");
	//myCode::sayHello();
	//MessageBoxW(0, L"After call...", L"DLL message:", infoBoxOptions);

	/* Initialize the app.  Send all error messages to 'stderr'.  */


	/* Initialize the FS library. */

	/* Initialize and allocate the client_ctx object. */

	/* Load the run-time config file into a hash */

	//svn_auth_baton_t *ab;




	//apr_pool_t *pool;
	//svn_client_ctx_t *ctx;
	//svn_auth_baton_t *ab;



	//std::mutex v_mutex;
	//v_mutex.lock();
	//v_mutex.unlock();





		//HMODULE hmod = LoadLibraryA("vc6-dll.dll");
		/*FARPROC*/
		//return proc(1, argv);
		//printf("Usage:  %s URL\n", argv[0]);
		//return EXIT_FAILURE;



	/* Make sure the ~/.subversion run-time config files exist */

/* Now do the real work. */

	/* Set revision to always be the HEAD revision.  It could, however,
     be set to a specific revision number, date, or other values. */

	/* Main call into libsvn_client does all the work. */

	/* Print the dir entries in the hash. */


		/* 'val' is actually an svn_dirent_t structure; a more complex
          program would mine it for extra printable information. */

int  dummy();
