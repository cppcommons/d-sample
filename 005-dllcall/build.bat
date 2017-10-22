qmake.exe dlltest.pro -spec win32-g++ "CONFIG+=release"
mingw32-make -f Makefile.Release
C:\D\dm\bin\dmc main.cpp MemoryModule.c
main.exe
pause
