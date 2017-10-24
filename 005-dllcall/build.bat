qmake.exe dlltest.pro -spec win32-g++ "CONFIG+=release"
mingw32-make -f Makefile.Release
::main.exe
::@echo off

del lib_entry.lib
del *_codedata.obj
del *_entry.obj

setlocal enabledelayedexpansion enableextensions
set LIST=
::for %%x in (easy_win_*.c) do set LIST=!LIST! %%x
for %%x in (easy_win_*.c) do set LIST=!LIST! %%x
for %%x in (easy_win_*.cpp) do set LIST=!LIST! %%x
::for %%x in (entry_*.cpp) do set LIST=!LIST! %%x
C:\D\dm\bin\dmc -c %LIST%

setlocal enabledelayedexpansion enableextensions
set LIST=
for %%x in (easy_win_*.obj) do set LIST=!LIST! %%x
::for %%x in (entry_*.obj) do set LIST=!LIST! %%x
C:\D\dm\bin\lib -c -n -p512 lib_entry.lib %LIST%

del main.exe
C:\D\dm\bin\dmc main.cpp lib_entry.lib