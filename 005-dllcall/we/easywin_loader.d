/* Converted to D from easywin_loader.cpp by htod */
module easywin_loader;

extern (C):
alias void *HMEMORYMODULE;
alias void *HMEMORYRSRC;
alias void *HCUSTOMMODULE;
alias void *EASYWIN_PROC;
alias HCUSTOMMODULE  function(char *, void *)CustomLoadLibraryFunc;
alias EASYWIN_PROC  function(HCUSTOMMODULE , char *, void *)CustomGetProcAddressFunc;
alias void  function(HCUSTOMMODULE , void *)CustomFreeLibraryFunc;
/**
 * Load DLL from memory location.
 *
 * All dependencies are resolved using default LoadLibrary/GetProcAddress
 * calls through the Windows API.
 */
HMEMORYMODULE  MemoryLoadLibrary(void *);
/**
 * Load DLL from memory location using custom dependency resolvers.
 *
 * Dependencies will be resolved using passed callback methods.
 */
HMEMORYMODULE  MemoryLoadLibraryEx(void *, CustomLoadLibraryFunc , CustomGetProcAddressFunc , CustomFreeLibraryFunc , void *);
/**
 * Get address of exported method.
 */
EASYWIN_PROC  MemoryGetProcAddress(HMEMORYMODULE , char *);
/**
 * Free previously loaded DLL.
 */
void  MemoryFreeLibrary(HMEMORYMODULE );

/* Definitions for Digital Mars Compiler & VC++6 */

// disable warnings about pointer <-> DWORD conversions



// Vista SDKs no longer define IMAGE_SIZEOF_BASE_RELOCATION!?






			// section doesn't contain data in the dll itself, but may define
			// uninitialized data


			// section is empty

		// commit memory block and copy data from dll

// Protection flags for memory pages (Executable, Readable, Writeable)
		// not executable
		// executable


	// loop through all sections and change access flags

			// section is not needed any more and can safely be freed

		// determine protection flags based on characteristics

		// determine size of region

			// change memory access flags



				// the upper 4 bits define the type of relocation
				// the lower 12 bits define the offset

					// skip relocation

					// change complete 32 bit address


					//printf("Unknown relocation: %d\n", type);

			// advance to next relocation block




				// no hint table





//static FARPROC _GetProcAddress(HCUSTOMMODULE module, LPCSTR name, void *userdata)






	// reserve memory for image of library
	// XXX: is it correct to commit the complete memory region at once?
	//      calling DllEntry raises an exception if we don't...

		// try to allocate memory at arbitrary position



	// commit memory for headers

	// copy PE header to code

	// update position

	// copy sections from DLL file block to new memory location

	// adjust base address of imported data

	// load required dlls and adjust function table of imports

	// mark memory pages depending on section headers and release
	// sections that are marked as "discardable"

	// get entry point of loaded library
		// notify library about attaching to process


	// cleanup

/*FARPROC*/
		// no export table found

		// DLL doesn't export anything

		// search function name in list of exported names

		// exported symbol not found

		// name <-> ordinal number don't match

	// AddressOfFunctions contains the RVAs to the "real" functions


			// notify library about detaching from process

			// free previously opened libraries


			// release memory of library

