qmake.exe dlltest.pro -spec win32-g++ "CONFIG+=release"
mingw32-make -f Makefile.Release
del main.exe
C:\D\dm\bin\dmc main.cpp lib_entry.cpp dll_data.c dll_data_1.c dll_data_2.c dll_data_3.c dll_data_4.c dll_data_5.c dll_data_6.c
del lib_entry.lib
C:\D\dm\bin\lib -c -p32 lib_entry.lib lib_entry.obj dll_data.obj dll_data_1.obj dll_data_2.obj dll_data_3.obj dll_data_4.obj dll_data_5.obj dll_data_6.obj

::main.exe
