/* Converted to D from vc6.cpp by htod */
module vc6;
import os2;
extern (C):
alias int  function(int argc, char **argv)proc_main;
int  main(int argc, char **argv);
os_int32  vc6_add2(os_int32 a, os_int32 b);



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







	//std::mutex v_mutex;
	//v_mutex.lock();
	//v_mutex.unlock();





		//HMODULE hmod = LoadLibraryA("vc6-dll.dll");
		/*FARPROC*/
		//return proc(1, argv);
		//printf("Usage:  %s URL\n", argv[0]);
		//return EXIT_FAILURE;


	/* Initialize the app.  Send all error messages to 'stderr'.  */

	/* Create top-level memory pool. Be sure to read the HACKING file to
     understand how to properly use/free subpools. */

	/* Initialize the FS library. */
		/* For functions deeper in the stack, we usually use the
         SVN_ERR() exception-throwing macro (see svn_error.h).  At the
         top level, we catch & print the error with svn_handle_error2(). */

	/* Make sure the ~/.subversion run-time config files exist */

	/* All clients need to fill out a client_ctx object. */
		/* Initialize and allocate the client_ctx object. */

		/* Load the run-time config file into a hash */

		/* Set the working copy administrative directory name. */

		/* Depending on what your client does, you'll want to read about
       (and implement) the various callback function types below.  */

		/* A func (& context) which receives event signals during
       checkouts, updates, commits, etc.  */
		/* ctx->notify_func = my_notification_func;
       ctx->notify_baton = NULL; */

		/* A func (& context) which can receive log messages */
		/* ctx->log_msg_func = my_log_msg_receiver_func;
       ctx->log_msg_baton = NULL; */

		/* A func (& context) which checks whether the user cancelled */
		/* ctx->cancel_func = my_cancel_checking_func;
       ctx->cancel_baton = NULL; */

		/* Make the client_ctx capable of authenticating users */
			/* There are many different kinds of authentication back-end
         "providers".  See svn_auth.h for a full overview.

         If you want to get the auth behavior of the 'svn' program,
         you can use svn_cmdline_setup_auth_baton, which will give
         you the exact set of auth providers it uses.  This program
         doesn't use it because it's only appropriate for a command
         line program, and this is supposed to be a general purpose
         example. */




			/* Register the auth-providers into the context's auth_baton. */

	/* Now do the real work. */
	//svn_auth_baton_t *ab;


	/* Set revision to always be the HEAD revision.  It could, however,
     be set to a specific revision number, date, or other values. */

	/* Main call into libsvn_client does all the work. */

	/* Print the dir entries in the hash. */


		/* 'val' is actually an svn_dirent_t structure; a more complex
          program would mine it for extra printable information. */

int  dummy();
