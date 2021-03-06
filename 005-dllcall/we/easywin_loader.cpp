extern "C" {

typedef void *HMEMORYMODULE;
typedef void *HMEMORYRSRC;
typedef void *HCUSTOMMODULE;
typedef void *EASYWIN_PROC;
typedef HCUSTOMMODULE (*CustomLoadLibraryFunc)(/*LPCSTR*/ const char *a_filename, void *a_userdata);
//static HCUSTOMMODULE _LoadLibrary(LPCSTR filename, void *userdata)
typedef /*FARPROC*/ EASYWIN_PROC (*CustomGetProcAddressFunc)(
	HCUSTOMMODULE a_module, /*LPCSTR*/ const char *a_name, void *a_userdata);
//static /*FARPROC*/ EASYWIN_PROC _GetProcAddress(HCUSTOMMODULE module, /*LPCSTR*/ const char *name, void *userdata)
typedef void (*CustomFreeLibraryFunc)(HCUSTOMMODULE a_module, void *a_userdata);
//static void _FreeLibrary(HCUSTOMMODULE module, void *userdata)

/**
 * Load DLL from memory location.
 *
 * All dependencies are resolved using default LoadLibrary/GetProcAddress
 * calls through the Windows API.
 */
extern "C" HMEMORYMODULE MemoryLoadLibrary(const void *);
/**
 * Load DLL from memory location using custom dependency resolvers.
 *
 * Dependencies will be resolved using passed callback methods.
 */
extern "C" HMEMORYMODULE MemoryLoadLibraryEx(const void *,
											 CustomLoadLibraryFunc,
											 CustomGetProcAddressFunc,
											 CustomFreeLibraryFunc,
											 void *);
/**
 * Get address of exported method.
 */
extern "C" /*FARPROC*/ EASYWIN_PROC MemoryGetProcAddress(HMEMORYMODULE, /*LPCSTR*/ const char *);
/**
 * Free previously loaded DLL.
 */
extern "C" void MemoryFreeLibrary(HMEMORYMODULE);

#if !defined(__HTOD__)
/* Definitions for Digital Mars Compiler & VC++6 */
#ifndef ULONG_PTR
typedef unsigned long ULONG_PTR;
#endif /* __DMC__ */
#ifndef IS_INTRESOURCE
#define IS_INTRESOURCE(_r) ((((ULONG_PTR)(_r)) >> 16) == 0)
#endif

#ifndef __GNUC__
// disable warnings about pointer <-> DWORD conversions
#pragma warning(disable : 4311 4312)
#endif

#ifdef _WIN64
#define POINTER_TYPE ULONGLONG
#else
#define POINTER_TYPE DWORD
#endif

#include <windows.h>
#include <winnt.h>
#ifdef DEBUG_OUTPUT
#include <stdio.h>
#endif

#ifndef IMAGE_SIZEOF_BASE_RELOCATION
// Vista SDKs no longer define IMAGE_SIZEOF_BASE_RELOCATION!?
#define IMAGE_SIZEOF_BASE_RELOCATION (sizeof(IMAGE_BASE_RELOCATION))
#endif

#include <windows.h>

typedef struct
{
	PIMAGE_NT_HEADERS headers;
	unsigned char *codeBase;
	HCUSTOMMODULE *modules;
	int numModules;
	int initialized;
	CustomLoadLibraryFunc loadLibrary;
	CustomGetProcAddressFunc getProcAddress;
	CustomFreeLibraryFunc freeLibrary;
	void *userdata;
} MEMORYMODULE, *PMEMORYMODULE;

typedef BOOL(WINAPI *DllEntryProc)(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved);

#define GET_HEADER_DICTIONARY(module, idx) &(module)->headers->OptionalHeader.DataDirectory[idx]

#ifdef DEBUG_OUTPUT
static void
OutputLastError(const char *msg)
{
	LPVOID tmp;
	char *tmpmsg;
	FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
				  NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR)&tmp, 0, NULL);
	tmpmsg = (char *)LocalAlloc(LPTR, strlen(msg) + strlen((const char *)tmp) + 3);
	sprintf(tmpmsg, "%s: %s", msg, tmp);
	OutputDebugString(tmpmsg);
	LocalFree(tmpmsg);
	LocalFree(tmp);
}
#endif

static void
CopySections(const unsigned char *data, PIMAGE_NT_HEADERS old_headers, PMEMORYMODULE module)
{
	int i, size;
	unsigned char *codeBase = module->codeBase;
	unsigned char *dest;
	PIMAGE_SECTION_HEADER section = IMAGE_FIRST_SECTION(module->headers);
	for (i = 0; i < module->headers->FileHeader.NumberOfSections; i++, section++)
	{
		if (section->SizeOfRawData == 0)
		{
			// section doesn't contain data in the dll itself, but may define
			// uninitialized data
			size = old_headers->OptionalHeader.SectionAlignment;
			if (size > 0)
			{
				dest = (unsigned char *)VirtualAlloc(codeBase + section->VirtualAddress,
													 size,
													 MEM_COMMIT,
													 PAGE_READWRITE);

				section->Misc.PhysicalAddress = (DWORD)(POINTER_TYPE)dest;
				memset(dest, 0, size);
			}

			// section is empty
			continue;
		}

		// commit memory block and copy data from dll
		dest = (unsigned char *)VirtualAlloc(codeBase + section->VirtualAddress,
											 section->SizeOfRawData,
											 MEM_COMMIT,
											 PAGE_READWRITE);
		memcpy(dest, data + section->PointerToRawData, section->SizeOfRawData);
		section->Misc.PhysicalAddress = (DWORD)(POINTER_TYPE)dest;
	}
}

// Protection flags for memory pages (Executable, Readable, Writeable)
static int ProtectionFlags[2][2][2] = {
	{
		// not executable
		{PAGE_NOACCESS, PAGE_WRITECOPY},
		{PAGE_READONLY, PAGE_READWRITE},
	},
	{
		// executable
		{PAGE_EXECUTE, PAGE_EXECUTE_WRITECOPY},
		{PAGE_EXECUTE_READ, PAGE_EXECUTE_READWRITE},
	},
};

static void
FinalizeSections(PMEMORYMODULE module)
{
	int i;
	PIMAGE_SECTION_HEADER section = IMAGE_FIRST_SECTION(module->headers);
#ifdef _WIN64
	POINTER_TYPE imageOffset = (module->headers->OptionalHeader.ImageBase & 0xffffffff00000000);
#else
#define imageOffset 0
#endif

	// loop through all sections and change access flags
	for (i = 0; i < module->headers->FileHeader.NumberOfSections; i++, section++)
	{
		DWORD protect, oldProtect, size;
		int executable = (section->Characteristics & IMAGE_SCN_MEM_EXECUTE) != 0;
		int readable = (section->Characteristics & IMAGE_SCN_MEM_READ) != 0;
		int writeable = (section->Characteristics & IMAGE_SCN_MEM_WRITE) != 0;

		if (section->Characteristics & IMAGE_SCN_MEM_DISCARDABLE)
		{
			// section is not needed any more and can safely be freed
			VirtualFree((LPVOID)((POINTER_TYPE)section->Misc.PhysicalAddress | imageOffset), section->SizeOfRawData, MEM_DECOMMIT);
			continue;
		}

		// determine protection flags based on characteristics
		protect = ProtectionFlags[executable][readable][writeable];
		if (section->Characteristics & IMAGE_SCN_MEM_NOT_CACHED)
		{
			protect |= PAGE_NOCACHE;
		}

		// determine size of region
		size = section->SizeOfRawData;
		if (size == 0)
		{
			if (section->Characteristics & IMAGE_SCN_CNT_INITIALIZED_DATA)
			{
				size = module->headers->OptionalHeader.SizeOfInitializedData;
			}
			else if (section->Characteristics & IMAGE_SCN_CNT_UNINITIALIZED_DATA)
			{
				size = module->headers->OptionalHeader.SizeOfUninitializedData;
			}
		}

		if (size > 0)
		{
			// change memory access flags
			if (VirtualProtect((LPVOID)((POINTER_TYPE)section->Misc.PhysicalAddress | imageOffset), size, protect, &oldProtect) == 0)
#ifdef DEBUG_OUTPUT
				OutputLastError("Error protecting memory page")
#endif
					;
		}
	}
#ifndef _WIN64
#undef imageOffset
#endif
}

static void
PerformBaseRelocation(PMEMORYMODULE module, size_t delta)
{
	DWORD i;
	unsigned char *codeBase = module->codeBase;

	PIMAGE_DATA_DIRECTORY directory = GET_HEADER_DICTIONARY(module, IMAGE_DIRECTORY_ENTRY_BASERELOC);
	if (directory->Size > 0)
	{
		PIMAGE_BASE_RELOCATION relocation = (PIMAGE_BASE_RELOCATION)(codeBase + directory->VirtualAddress);
		for (; relocation->VirtualAddress > 0;)
		{
			unsigned char *dest = codeBase + relocation->VirtualAddress;
			unsigned short *relInfo = (unsigned short *)((unsigned char *)relocation + IMAGE_SIZEOF_BASE_RELOCATION);
			for (i = 0; i < ((relocation->SizeOfBlock - IMAGE_SIZEOF_BASE_RELOCATION) / 2); i++, relInfo++)
			{
				DWORD *patchAddrHL;
#ifdef _WIN64
				ULONGLONG *patchAddr64;
#endif
				int type, offset;

				// the upper 4 bits define the type of relocation
				type = *relInfo >> 12;
				// the lower 12 bits define the offset
				offset = *relInfo & 0xfff;

				switch (type)
				{
				case IMAGE_REL_BASED_ABSOLUTE:
					// skip relocation
					break;

				case IMAGE_REL_BASED_HIGHLOW:
					// change complete 32 bit address
					patchAddrHL = (DWORD *)(dest + offset);
					*patchAddrHL += (DWORD)delta;
					break;

#ifdef _WIN64
				case IMAGE_REL_BASED_DIR64:
					patchAddr64 = (ULONGLONG *)(dest + offset);
					*patchAddr64 += (ULONGLONG)delta;
					break;
#endif

				default:
					//printf("Unknown relocation: %d\n", type);
					break;
				}
			}

			// advance to next relocation block
			relocation = (PIMAGE_BASE_RELOCATION)(((char *)relocation) + relocation->SizeOfBlock);
		}
	}
}

static int
BuildImportTable(PMEMORYMODULE module)
{
	int result = 1;
	unsigned char *codeBase = module->codeBase;
	HCUSTOMMODULE *tmp;

	PIMAGE_DATA_DIRECTORY directory = GET_HEADER_DICTIONARY(module, IMAGE_DIRECTORY_ENTRY_IMPORT);
	if (directory->Size > 0)
	{
		PIMAGE_IMPORT_DESCRIPTOR importDesc = (PIMAGE_IMPORT_DESCRIPTOR)(codeBase + directory->VirtualAddress);
		for (; !IsBadReadPtr(importDesc, sizeof(IMAGE_IMPORT_DESCRIPTOR)) && importDesc->Name; importDesc++)
		{
			POINTER_TYPE *thunkRef;
			FARPROC *funcRef;
			HCUSTOMMODULE handle = module->loadLibrary((LPCSTR)(codeBase + importDesc->Name), module->userdata);
			if (handle == NULL)
			{
				SetLastError(ERROR_MOD_NOT_FOUND);
				result = 0;
				break;
			}

			tmp = (HCUSTOMMODULE *)realloc(module->modules, (module->numModules + 1) * (sizeof(HCUSTOMMODULE)));
			if (tmp == NULL)
			{
				module->freeLibrary(handle, module->userdata);
				SetLastError(ERROR_OUTOFMEMORY);
				result = 0;
				break;
			}
			module->modules = tmp;

			module->modules[module->numModules++] = handle;
			if (importDesc->OriginalFirstThunk)
			{
				thunkRef = (POINTER_TYPE *)(codeBase + (DWORD)importDesc->OriginalFirstThunk);
				funcRef = (FARPROC *)(codeBase + (DWORD)importDesc->FirstThunk);
			}
			else
			{
				// no hint table
				thunkRef = (POINTER_TYPE *)(codeBase + (DWORD)importDesc->FirstThunk);
				funcRef = (FARPROC *)(codeBase + (DWORD)importDesc->FirstThunk);
			}
			for (; *thunkRef; thunkRef++, funcRef++)
			{
				if (IMAGE_SNAP_BY_ORDINAL(*thunkRef))
				{
					*funcRef = (FARPROC)module->getProcAddress(handle, (LPCSTR)IMAGE_ORDINAL(*thunkRef), module->userdata);
				}
				else
				{
					PIMAGE_IMPORT_BY_NAME thunkData = (PIMAGE_IMPORT_BY_NAME)(codeBase + (*thunkRef));
					*funcRef = (FARPROC)module->getProcAddress(handle, (LPCSTR)&thunkData->Name, module->userdata);
				}
				if (*funcRef == 0)
				{
					result = 0;
					break;
				}
			}

			if (!result)
			{
				module->freeLibrary(handle, module->userdata);
				SetLastError(ERROR_PROC_NOT_FOUND);
				break;
			}
		}
	}

	return result;
}

static HCUSTOMMODULE _LoadLibrary(LPCSTR filename, void *userdata)
{
	HMODULE result = LoadLibraryA(filename);
	if (result == NULL)
	{
		return NULL;
	}

	return (HCUSTOMMODULE)result;
}

//static FARPROC _GetProcAddress(HCUSTOMMODULE module, LPCSTR name, void *userdata)
static /*FARPROC*/ EASYWIN_PROC _GetProcAddress(HCUSTOMMODULE module, /*LPCSTR*/ const char *name, void *userdata)
{
	return (/*FARPROC*/ EASYWIN_PROC)GetProcAddress((HMODULE)module, name);
}

static void _FreeLibrary(HCUSTOMMODULE module, void *userdata)
{
	FreeLibrary((HMODULE)module);
}

HMEMORYMODULE MemoryLoadLibrary(const void *data)
{
	return MemoryLoadLibraryEx(data, _LoadLibrary, _GetProcAddress, _FreeLibrary, NULL);
}

HMEMORYMODULE MemoryLoadLibraryEx(const void *data,
								  CustomLoadLibraryFunc loadLibrary,
								  CustomGetProcAddressFunc getProcAddress,
								  CustomFreeLibraryFunc freeLibrary,
								  void *userdata)
{
	PMEMORYMODULE result;
	PIMAGE_DOS_HEADER dos_header;
	PIMAGE_NT_HEADERS old_header;
	unsigned char *code, *headers;
	size_t locationDelta;
	DllEntryProc DllEntry;
	BOOL successfull;

	dos_header = (PIMAGE_DOS_HEADER)data;
	if (dos_header->e_magic != IMAGE_DOS_SIGNATURE)
	{
		SetLastError(ERROR_BAD_EXE_FORMAT);
		return NULL;
	}

	old_header = (PIMAGE_NT_HEADERS) & ((const unsigned char *)(data))[dos_header->e_lfanew];
	if (old_header->Signature != IMAGE_NT_SIGNATURE)
	{
		SetLastError(ERROR_BAD_EXE_FORMAT);
		return NULL;
	}

	// reserve memory for image of library
	// XXX: is it correct to commit the complete memory region at once?
	//      calling DllEntry raises an exception if we don't...
	code = (unsigned char *)VirtualAlloc((LPVOID)(old_header->OptionalHeader.ImageBase),
										 old_header->OptionalHeader.SizeOfImage,
										 MEM_RESERVE | MEM_COMMIT,
										 PAGE_READWRITE);

	if (code == NULL)
	{
		// try to allocate memory at arbitrary position
		code = (unsigned char *)VirtualAlloc(NULL,
											 old_header->OptionalHeader.SizeOfImage,
											 MEM_RESERVE | MEM_COMMIT,
											 PAGE_READWRITE);
		if (code == NULL)
		{
			SetLastError(ERROR_OUTOFMEMORY);
			return NULL;
		}
	}

	result = (PMEMORYMODULE)HeapAlloc(GetProcessHeap(), 0, sizeof(MEMORYMODULE));
	if (result == NULL)
	{
		SetLastError(ERROR_OUTOFMEMORY);
		VirtualFree(code, 0, MEM_RELEASE);
		return NULL;
	}

	result->codeBase = code;
	result->numModules = 0;
	result->modules = NULL;
	result->initialized = 0;
	result->loadLibrary = loadLibrary;
	result->getProcAddress = getProcAddress;
	result->freeLibrary = freeLibrary;
	result->userdata = userdata;

	// commit memory for headers
	headers = (unsigned char *)VirtualAlloc(code,
											old_header->OptionalHeader.SizeOfHeaders,
											MEM_COMMIT,
											PAGE_READWRITE);

	// copy PE header to code
	memcpy(headers, dos_header, dos_header->e_lfanew + old_header->OptionalHeader.SizeOfHeaders);
	result->headers = (PIMAGE_NT_HEADERS) & ((const unsigned char *)(headers))[dos_header->e_lfanew];

	// update position
	result->headers->OptionalHeader.ImageBase = (POINTER_TYPE)code;

	// copy sections from DLL file block to new memory location
	CopySections((const unsigned char *)data, old_header, result);

	// adjust base address of imported data
	locationDelta = (size_t)(code - old_header->OptionalHeader.ImageBase);
	if (locationDelta != 0)
	{
		PerformBaseRelocation(result, locationDelta);
	}

	// load required dlls and adjust function table of imports
	if (!BuildImportTable(result))
	{
		goto error;
	}

	// mark memory pages depending on section headers and release
	// sections that are marked as "discardable"
	FinalizeSections(result);

	// get entry point of loaded library
	if (result->headers->OptionalHeader.AddressOfEntryPoint != 0)
	{
		DllEntry = (DllEntryProc)(code + result->headers->OptionalHeader.AddressOfEntryPoint);
		// notify library about attaching to process
		successfull = (*DllEntry)((HINSTANCE)code, DLL_PROCESS_ATTACH, 0);
		if (!successfull)
		{
			SetLastError(ERROR_DLL_INIT_FAILED);
			goto error;
		}
		result->initialized = 1;
	}

	return (HMEMORYMODULE)result;

error:
	// cleanup
	MemoryFreeLibrary(result);
	return NULL;
}

/*FARPROC*/ EASYWIN_PROC MemoryGetProcAddress(HMEMORYMODULE module, /*LPCSTR*/ const char *name)
{
	unsigned char *codeBase = ((PMEMORYMODULE)module)->codeBase;
	int idx = -1;
	DWORD i, *nameRef;
	WORD *ordinal;
	PIMAGE_EXPORT_DIRECTORY exports;
	PIMAGE_DATA_DIRECTORY directory = GET_HEADER_DICTIONARY((PMEMORYMODULE)module, IMAGE_DIRECTORY_ENTRY_EXPORT);
	if (directory->Size == 0)
	{
		// no export table found
		SetLastError(ERROR_PROC_NOT_FOUND);
		return NULL;
	}

	exports = (PIMAGE_EXPORT_DIRECTORY)(codeBase + directory->VirtualAddress);
	if (exports->NumberOfNames == 0 || exports->NumberOfFunctions == 0)
	{
		// DLL doesn't export anything
		SetLastError(ERROR_PROC_NOT_FOUND);
		return NULL;
	}

	if (!IS_INTRESOURCE(name))
	{
		// search function name in list of exported names
		nameRef = (DWORD *)(codeBase + (DWORD)exports->AddressOfNames);
		ordinal = (WORD *)(codeBase + (DWORD)exports->AddressOfNameOrdinals);
		for (i = 0; i < exports->NumberOfNames; i++, nameRef++, ordinal++)
		{
			if (_stricmp(name, (const char *)(codeBase + (*nameRef))) == 0)
			{
				idx = *ordinal;
				break;
			}
		}
	}
	else
		idx = (int)name;

	if (idx == -1)
	{
		// exported symbol not found
		SetLastError(ERROR_PROC_NOT_FOUND);
		return NULL;
	}

	if ((DWORD)idx > exports->NumberOfFunctions)
	{
		// name <-> ordinal number don't match
		SetLastError(ERROR_PROC_NOT_FOUND);
		return NULL;
	}

	// AddressOfFunctions contains the RVAs to the "real" functions
	return (FARPROC)(codeBase + (*(DWORD *)(codeBase + (DWORD)exports->AddressOfFunctions + (idx * 4))));
}

void MemoryFreeLibrary(HMEMORYMODULE mod)
{
	int i;
	PMEMORYMODULE module = (PMEMORYMODULE)mod;

	if (module != NULL)
	{
		if (module->initialized != 0)
		{
			// notify library about detaching from process
			DllEntryProc DllEntry = (DllEntryProc)(module->codeBase + module->headers->OptionalHeader.AddressOfEntryPoint);
			(*DllEntry)((HINSTANCE)module->codeBase, DLL_PROCESS_DETACH, 0);
			module->initialized = 0;
		}

		if (module->modules != NULL)
		{
			// free previously opened libraries
			for (i = 0; i < module->numModules; i++)
			{
				if (module->modules[i] != NULL)
				{
					module->freeLibrary(module->modules[i], module->userdata);
				}
			}

			free(module->modules);
		}

		if (module->codeBase != NULL)
		{
			// release memory of library
			VirtualFree(module->codeBase, 0, MEM_RELEASE);
		}

		HeapFree(GetProcessHeap(), 0, module);
	}
}
#endif //#if !defined(__HTOD__)
} // extern "C"
