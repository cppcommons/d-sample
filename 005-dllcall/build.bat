qmake.exe dlltest.pro -spec win32-g++ "CONFIG+=release"
mingw32-make -f Makefile.Release
::C:\D\dm\bin\dmc -HP81920 -c dll_data.c
::C:\D\dm\bin\dmc main.cpp MemoryModule.c dll_data.c
C:\D\dm\bin\dmc main.cpp MemoryModule.c
main.exe
