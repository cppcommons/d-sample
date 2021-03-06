//private const uint unit_size = 400 * 1024; /* 400KB */

version (unittest)
{
}
else
    int main(string[] args)
{
    import core.stdc.stdio : printf;
    import std.conv : to;
    import std.file : read;
    import std.format : format;
    import std.stdio : File;
    import std.process : execute, executeShell;

    //printf("args.length=%d\n", args.length);
    if (args.length < 3 || args.length > 4)
    {
        printf("easy <identifier> <dll-path> [<unit-size>]");
        return 1;
    }

    immutable string identifier = args[1];
    //File f = File("release/dlltest.dll");
    File f = File(args[2]);

    immutable ulong unit_size = (args.length == 4) ? to!ulong(args[3]) : f.size;

    ulong[] chunk_size_list;

    int index = 0;
    foreach (chunk; f.byChunk(cast(uint) unit_size))
    {
        chunk_size_list ~= chunk.length;
        //printf("chunk\n");
        write_unit(identifier, index, chunk, unit_size);
        index++;
    }

    auto fname1 = format!"easy_win_%s_0_codedata.c"(identifier);
    File file1 = File(fname1, "w");
    file1.writef(`#include "MemoryModule-micro.cpp"
`);
    //file1.writef("extern \"C\" {\n");
    for (int i = 0; i < index; i++)
    {
        file1.writef("extern const unsigned char easy_win_%s_%d[];\n", identifier, i + 1);
    }
    //file1.writef("}\n");

    file1.write(`struct dll_unit
{
	const unsigned char *ptr;
	unsigned long size;
};
`);

    file1.writef("static struct dll_unit dll_data_array[] = {\n");
    for (int i = 0; i < index; i++)
    {
        file1.writef("	{ easy_win_%s_%d, %u },\n", identifier, i + 1, chunk_size_list[i]);
    }
    file1.writef("	{ 0, 0 }\n");
    file1.writef("};\n");

    //file1.writef("static const unsigned long dll_data_unit = %u;\n", unit_size);
    file1.writef("static const int dll_data_count = %d;\n", index);

    file1.writef(`extern void *easy_win_%s_get_proc_address(const char *proc_name)
{
	static HMEMORYMODULE hModule = NULL;
	if (!hModule)
	{
		unsigned long dll_data_size = 0;
		for (int i = 0; i < dll_data_count; i++)
		{
			dll_data_size += dll_data_array[i].size;
		}
		unsigned char *dll_data = (unsigned char *)HeapAlloc(GetProcessHeap(), 0, dll_data_size);
		unsigned char *dll_ptr = dll_data;
		for (int i = 0; i < dll_data_count; i++)
		{
			const unsigned char *unit = dll_data_array[i].ptr;
			RtlMoveMemory(dll_ptr, unit, dll_data_array[i].size);
			dll_ptr += dll_data_array[i].size;
		}
		hModule = MemoryLoadLibrary(dll_data);
		HeapFree(GetProcessHeap(), 0, dll_data);
	}
	return MemoryGetProcAddress(hModule, proc_name);
}
`, identifier);
    file1.close();

    auto fname2 = format!"easy_win_%s_funclist.cpp"(identifier);
    File file2 = File(fname2, "w");
    file2.writef(`#include <windows.h>
#ifdef EASY_WIN_DEBUG
#include <stdio.h>
#endif /* EASY_WIN_DEBUG */

extern "C" void *easy_win_%s_get_proc_address(const char *proc_name);

#ifdef __MINGW32__
#define EXPORT_OPCODES
#else
#define EXPORT_OPCODES extern "C"
#endif

`, identifier, identifier);
    auto dmd = execute(["pexports", args[2]]);
    //if (dmd.status != 0) writeln("Compilation failed:\n", dmd.output);
    {
        import std.algorithm : startsWith, endsWith;
        import std.conv : to;
        import std.stdio : writeln, stdout;
        import std.string : splitLines;

        //writeln(dmd.output);
        //writeln(dmd.output.startsWith("LIBRARY "));
        string[] lines = dmd.output.splitLines;
        //writeln(lines);
        foreach (line; lines)
        {
            if (line.startsWith("LIBRARY ") || line == "EXPORTS" || line.endsWith(" DATA"))
                continue;
            //file2.writef("extern \"C\" unsigned char %s[16] = {0};\n", line);
            file2.writef("EXPORT_OPCODES unsigned char %s[16] = {0};\n", line);
        }
        file2.writef(`
class ExportedFunctions
{
  public:
    void export_fun(const char *name, unsigned char opcodes[])
    {
		void *jmpdest = easy_win_%s_get_proc_address(name);
		opcodes[0] = 0xFF;
		opcodes[1] = 0x25;
		*reinterpret_cast<DWORD *>(opcodes + 2) = reinterpret_cast<DWORD>(opcodes + 6);
		*reinterpret_cast<DWORD *>(opcodes + 6) = reinterpret_cast<DWORD>(jmpdest);
    }
	explicit ExportedFunctions()
	{
`, identifier);
        foreach (line; lines)
        {
            if (line.startsWith("LIBRARY ") || line == "EXPORTS" || line.endsWith(" DATA"))
                continue;
            file2.writef("        export_fun(\"%s\", %s);\n", line, line);
            //file2.writef("        export_fun(\"%s\", _%s);\n", line, line);
        }
        file2.write(`    }
};
static ExportedFunctions _initializer_;
        `);
    }
    file2.close();
    write_memory_module();
    return 0;
}

private void write_unit(string identifier, int index, ubyte[] bytes, ulong unit_size)
{
    import core.stdc.stdio : fprintf;
    import std.format : format;
    import std.stdio : File;

    /+
    bytes.reserve(cast(uint) unit_size);
    while (bytes.length < unit_size)
    {
        bytes ~= 0;
    }
    +/
    auto fname = format!"easy_win_%s_%d_codedata.c"(identifier, index + 1);
    auto f = File(fname, "w");
    f.write(`#ifdef __MINGW32__
#define EXPORT_UNIT
#else
#define EXPORT_UNIT extern
#endif
`);
    f.writef("EXPORT_UNIT const unsigned char easy_win_%s_%d[] = {\n", identifier, index + 1);
    int first = true;
    int count = 0;
    foreach (ub; bytes)
    {
        if (count >= 20)
        {
            f.writef("\n");
            count = 0;
        }
        if (first)
            f.writef("  ");
        else
            f.writef(", ");
        first = false;
        f.writef("0x%02x", ub);
        count++;
    }
    f.writef("\n};\n");
    f.close();
}

private void write_memory_module()
{
    import std.stdio : File;

    File file1 = File("MemoryModule-micro.cpp", "w");
    file1.write(`/* Definitions for Digital Mars Compiler */
#ifdef __DMC__
typedef unsigned long ULONG_PTR;
#define IS_INTRESOURCE(_r) ((((ULONG_PTR)(_r)) >> 16) == 0)
#endif /* __DMC__ */
/*
 * Memory DLL loading code
 * Version 0.0.3
 *
 * Copyright (c) 2004-2013 by Joachim Bauch / mail@joachim-bauch.de
 * http://www.joachim-bauch.de
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is MemoryModule.c
 *
 * The Initial Developer of the Original Code is Joachim Bauch.
 *
 * Portions created by Joachim Bauch are Copyright (C) 2004-2013
 * Joachim Bauch. All Rights Reserved.
 */

#ifndef __GNUC__
// disable warnings about pointer <-> DWORD conversions
#pragma warning( disable : 4311 4312 )
#endif

#ifdef _WIN64
#define POINTER_TYPE ULONGLONG
#else
#define POINTER_TYPE DWORD
#endif

#include <windows.h>
#include <winnt.h>
#include <tchar.h>
#ifdef DEBUG_OUTPUT
#include <stdio.h>
#endif

#ifndef IMAGE_SIZEOF_BASE_RELOCATION
// Vista SDKs no longer define IMAGE_SIZEOF_BASE_RELOCATION!?
#define IMAGE_SIZEOF_BASE_RELOCATION (sizeof(IMAGE_BASE_RELOCATION))
#endif

//#include "MemoryModule.h"
#include <windows.h>
typedef void *HMEMORYMODULE;
typedef void *HMEMORYRSRC;
typedef void *HCUSTOMMODULE;
typedef HCUSTOMMODULE (*CustomLoadLibraryFunc)(LPCSTR, void *);
typedef FARPROC (*CustomGetProcAddressFunc)(HCUSTOMMODULE, LPCSTR, void *);
typedef void (*CustomFreeLibraryFunc)(HCUSTOMMODULE, void *);
/**
 * Load DLL from memory location.
 *
 * All dependencies are resolved using default LoadLibrary/GetProcAddress
 * calls through the Windows API.
 */
static HMEMORYMODULE MemoryLoadLibrary(const void *);
/**
 * Load DLL from memory location using custom dependency resolvers.
 *
 * Dependencies will be resolved using passed callback methods.
 */
static HMEMORYMODULE MemoryLoadLibraryEx(const void *,
    CustomLoadLibraryFunc,
    CustomGetProcAddressFunc,
    CustomFreeLibraryFunc,
    void *);
/**
 * Get address of exported method.
 */
static FARPROC MemoryGetProcAddress(HMEMORYMODULE, LPCSTR);
/**
 * Free previously loaded DLL.
 */
static void MemoryFreeLibrary(HMEMORYMODULE);


typedef struct {
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

typedef BOOL (WINAPI *DllEntryProc)(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved);

#define GET_HEADER_DICTIONARY(module, idx)	&(module)->headers->OptionalHeader.DataDirectory[idx]

#ifdef DEBUG_OUTPUT
static void
OutputLastError(const char *msg)
{
    LPVOID tmp;
    char *tmpmsg;
    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR)&tmp, 0, NULL);
    tmpmsg = (char *)LocalAlloc(LPTR, strlen(msg) + strlen(tmp) + 3);
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
    for (i=0; i<module->headers->FileHeader.NumberOfSections; i++, section++) {
        if (section->SizeOfRawData == 0) {
            // section doesn't contain data in the dll itself, but may define
            // uninitialized data
            size = old_headers->OptionalHeader.SectionAlignment;
            if (size > 0) {
                dest = (unsigned char *)VirtualAlloc(codeBase + section->VirtualAddress,
                    size,
                    MEM_COMMIT,
                    PAGE_READWRITE);

                section->Misc.PhysicalAddress = (DWORD) (POINTER_TYPE) dest;
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
        section->Misc.PhysicalAddress = (DWORD) (POINTER_TYPE) dest;
    }
}

// Protection flags for memory pages (Executable, Readable, Writeable)
static int ProtectionFlags[2][2][2] = {
    {
        // not executable
        {PAGE_NOACCESS, PAGE_WRITECOPY},
        {PAGE_READONLY, PAGE_READWRITE},
    }, {
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
    for (i=0; i<module->headers->FileHeader.NumberOfSections; i++, section++) {
        DWORD protect, oldProtect, size;
        int executable = (section->Characteristics & IMAGE_SCN_MEM_EXECUTE) != 0;
        int readable =   (section->Characteristics & IMAGE_SCN_MEM_READ) != 0;
        int writeable =  (section->Characteristics & IMAGE_SCN_MEM_WRITE) != 0;

        if (section->Characteristics & IMAGE_SCN_MEM_DISCARDABLE) {
            // section is not needed any more and can safely be freed
            VirtualFree((LPVOID)((POINTER_TYPE)section->Misc.PhysicalAddress | imageOffset), section->SizeOfRawData, MEM_DECOMMIT);
            continue;
        }

        // determine protection flags based on characteristics
        protect = ProtectionFlags[executable][readable][writeable];
        if (section->Characteristics & IMAGE_SCN_MEM_NOT_CACHED) {
            protect |= PAGE_NOCACHE;
        }

        // determine size of region
        size = section->SizeOfRawData;
        if (size == 0) {
            if (section->Characteristics & IMAGE_SCN_CNT_INITIALIZED_DATA) {
                size = module->headers->OptionalHeader.SizeOfInitializedData;
            } else if (section->Characteristics & IMAGE_SCN_CNT_UNINITIALIZED_DATA) {
                size = module->headers->OptionalHeader.SizeOfUninitializedData;
            }
        }

        if (size > 0) {
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
    if (directory->Size > 0) {
        PIMAGE_BASE_RELOCATION relocation = (PIMAGE_BASE_RELOCATION) (codeBase + directory->VirtualAddress);
        for (; relocation->VirtualAddress > 0; ) {
            unsigned char *dest = codeBase + relocation->VirtualAddress;
            unsigned short *relInfo = (unsigned short *)((unsigned char *)relocation + IMAGE_SIZEOF_BASE_RELOCATION);
            for (i=0; i<((relocation->SizeOfBlock-IMAGE_SIZEOF_BASE_RELOCATION) / 2); i++, relInfo++) {
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
                    patchAddrHL = (DWORD *) (dest + offset);
                    *patchAddrHL += (DWORD) delta;
                    break;
                
#ifdef _WIN64
                case IMAGE_REL_BASED_DIR64:
                    patchAddr64 = (ULONGLONG *) (dest + offset);
                    *patchAddr64 += (ULONGLONG) delta;
                    break;
#endif

                default:
                    //printf("Unknown relocation: %d\n", type);
                    break;
                }
            }

            // advance to next relocation block
            relocation = (PIMAGE_BASE_RELOCATION) (((char *) relocation) + relocation->SizeOfBlock);
        }
    }
}

static int
BuildImportTable(PMEMORYMODULE module)
{
    int result=1;
    unsigned char *codeBase = module->codeBase;
    HCUSTOMMODULE *tmp;

    PIMAGE_DATA_DIRECTORY directory = GET_HEADER_DICTIONARY(module, IMAGE_DIRECTORY_ENTRY_IMPORT);
    if (directory->Size > 0) {
        PIMAGE_IMPORT_DESCRIPTOR importDesc = (PIMAGE_IMPORT_DESCRIPTOR) (codeBase + directory->VirtualAddress);
        for (; !IsBadReadPtr(importDesc, sizeof(IMAGE_IMPORT_DESCRIPTOR)) && importDesc->Name; importDesc++) {
            POINTER_TYPE *thunkRef;
            FARPROC *funcRef;
            HCUSTOMMODULE handle = module->loadLibrary((LPCSTR) (codeBase + importDesc->Name), module->userdata);
            if (handle == NULL) {
                SetLastError(ERROR_MOD_NOT_FOUND);
                result = 0;
                break;
            }

            tmp = (HCUSTOMMODULE *) realloc(module->modules, (module->numModules+1)*(sizeof(HCUSTOMMODULE)));
            if (tmp == NULL) {
                module->freeLibrary(handle, module->userdata);
                SetLastError(ERROR_OUTOFMEMORY);
                result = 0;
                break;
            }
            module->modules = tmp;

            module->modules[module->numModules++] = handle;
            if (importDesc->OriginalFirstThunk) {
                thunkRef = (POINTER_TYPE *) (codeBase + (DWORD)importDesc->OriginalFirstThunk);
                funcRef = (FARPROC *) (codeBase + (DWORD)importDesc->FirstThunk);
            } else {
                // no hint table
                thunkRef = (POINTER_TYPE *) (codeBase + (DWORD)importDesc->FirstThunk);
                funcRef = (FARPROC *) (codeBase + (DWORD)importDesc->FirstThunk);
            }
            for (; *thunkRef; thunkRef++, funcRef++) {
                if (IMAGE_SNAP_BY_ORDINAL(*thunkRef)) {
                    *funcRef = module->getProcAddress(handle, (LPCSTR)IMAGE_ORDINAL(*thunkRef), module->userdata);
                } else {
                    PIMAGE_IMPORT_BY_NAME thunkData = (PIMAGE_IMPORT_BY_NAME) (codeBase + (*thunkRef));
                    *funcRef = module->getProcAddress(handle, (LPCSTR)&thunkData->Name, module->userdata);
                }
                if (*funcRef == 0) {
                    result = 0;
                    break;
                }
            }

            if (!result) {
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
    if (result == NULL) {
        return NULL;
    }
    
    return (HCUSTOMMODULE) result;
}

static FARPROC _GetProcAddress(HCUSTOMMODULE module, LPCSTR name, void *userdata)
{
    return (FARPROC) GetProcAddress((HMODULE) module, name);
}

static void _FreeLibrary(HCUSTOMMODULE module, void *userdata)
{
    FreeLibrary((HMODULE) module);
}

static HMEMORYMODULE MemoryLoadLibrary(const void *data)
{
    return MemoryLoadLibraryEx(data, _LoadLibrary, _GetProcAddress, _FreeLibrary, NULL);
}

static HMEMORYMODULE MemoryLoadLibraryEx(const void *data,
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
    if (dos_header->e_magic != IMAGE_DOS_SIGNATURE) {
        SetLastError(ERROR_BAD_EXE_FORMAT);
        return NULL;
    }

    old_header = (PIMAGE_NT_HEADERS)&((const unsigned char *)(data))[dos_header->e_lfanew];
    if (old_header->Signature != IMAGE_NT_SIGNATURE) {
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

    if (code == NULL) {
        // try to allocate memory at arbitrary position
        code = (unsigned char *)VirtualAlloc(NULL,
            old_header->OptionalHeader.SizeOfImage,
            MEM_RESERVE | MEM_COMMIT,
            PAGE_READWRITE);
        if (code == NULL) {
            SetLastError(ERROR_OUTOFMEMORY);
            return NULL;
        }
    }
    
    result = (PMEMORYMODULE)HeapAlloc(GetProcessHeap(), 0, sizeof(MEMORYMODULE));
    if (result == NULL) {
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
    result->headers = (PIMAGE_NT_HEADERS)&((const unsigned char *)(headers))[dos_header->e_lfanew];

    // update position
    result->headers->OptionalHeader.ImageBase = (POINTER_TYPE)code;

    // copy sections from DLL file block to new memory location
    CopySections((const unsigned char *)data, old_header, result);

    // adjust base address of imported data
    locationDelta = (size_t)(code - old_header->OptionalHeader.ImageBase);
    if (locationDelta != 0) {
        PerformBaseRelocation(result, locationDelta);
    }

    // load required dlls and adjust function table of imports
    if (!BuildImportTable(result)) {
        goto error;
    }

    // mark memory pages depending on section headers and release
    // sections that are marked as "discardable"
    FinalizeSections(result);

    // get entry point of loaded library
    if (result->headers->OptionalHeader.AddressOfEntryPoint != 0) {
        DllEntry = (DllEntryProc) (code + result->headers->OptionalHeader.AddressOfEntryPoint);
        // notify library about attaching to process
        successfull = (*DllEntry)((HINSTANCE)code, DLL_PROCESS_ATTACH, 0);
        if (!successfull) {
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

static FARPROC MemoryGetProcAddress(HMEMORYMODULE module, LPCSTR name)
{
    unsigned char *codeBase = ((PMEMORYMODULE)module)->codeBase;
    int idx=-1;
    DWORD i, *nameRef;
    WORD *ordinal;
    PIMAGE_EXPORT_DIRECTORY exports;
    PIMAGE_DATA_DIRECTORY directory = GET_HEADER_DICTIONARY((PMEMORYMODULE)module, IMAGE_DIRECTORY_ENTRY_EXPORT);
    if (directory->Size == 0) {
        // no export table found
        SetLastError(ERROR_PROC_NOT_FOUND);
        return NULL;
    }

    exports = (PIMAGE_EXPORT_DIRECTORY) (codeBase + directory->VirtualAddress);
    if (exports->NumberOfNames == 0 || exports->NumberOfFunctions == 0) {
        // DLL doesn't export anything
        SetLastError(ERROR_PROC_NOT_FOUND);
        return NULL;
    }

    if (!IS_INTRESOURCE(name)) {
	// search function name in list of exported names
	nameRef = (DWORD *) (codeBase + (DWORD)exports->AddressOfNames);
	ordinal = (WORD *) (codeBase + (DWORD)exports->AddressOfNameOrdinals);
	for (i=0; i<exports->NumberOfNames; i++, nameRef++, ordinal++) {
	    if (_stricmp(name, (const char *) (codeBase + (*nameRef))) == 0) {
		idx = *ordinal;
		break;
	    }
	}
    } else
	idx = (int)name;

    if (idx == -1) {
        // exported symbol not found
        SetLastError(ERROR_PROC_NOT_FOUND);
        return NULL;
    }

    if ((DWORD)idx > exports->NumberOfFunctions) {
        // name <-> ordinal number don't match
        SetLastError(ERROR_PROC_NOT_FOUND);
        return NULL;
    }

    // AddressOfFunctions contains the RVAs to the "real" functions
    return (FARPROC) (codeBase + (*(DWORD *) (codeBase + (DWORD)exports->AddressOfFunctions + (idx*4))));
}

static void MemoryFreeLibrary(HMEMORYMODULE mod)
{
    int i;
    PMEMORYMODULE module = (PMEMORYMODULE)mod;

    if (module != NULL) {
        if (module->initialized != 0) {
            // notify library about detaching from process
            DllEntryProc DllEntry = (DllEntryProc) (module->codeBase + module->headers->OptionalHeader.AddressOfEntryPoint);
            (*DllEntry)((HINSTANCE)module->codeBase, DLL_PROCESS_DETACH, 0);
            module->initialized = 0;
        }

        if (module->modules != NULL) {
            // free previously opened libraries
            for (i=0; i<module->numModules; i++) {
                if (module->modules[i] != NULL) {
                    module->freeLibrary(module->modules[i], module->userdata);
                }
            }

            free(module->modules);
        }

        if (module->codeBase != NULL) {
            // release memory of library
            VirtualFree(module->codeBase, 0, MEM_RELEASE);
        }

        HeapFree(GetProcessHeap(), 0, module);
    }
}
`);
    file1.close;
}
