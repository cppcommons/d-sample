qmake.exe dlltest.pro -spec win32-g++ "CONFIG+=release"
mingw32-make -f Makefile.Release
::C:\D\dm\bin\dmc main.cpp MemoryModule.c dll_data.c
C:\D\dm\bin\dmc main.cpp MemoryModule.c dll_data_1.c dll_data_2.c dll_data_3.c dll_data_4.c dll_data_5.c dll_data_6.c
main.exe
