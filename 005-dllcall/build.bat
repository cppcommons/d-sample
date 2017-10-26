if "%1" equ "clean" goto clean

::qmake.exe dlltest.pro -spec win32-g++ "CONFIG+=release"
::mingw32-make -f Makefile.Release
qmake -o dlltest.mk dlltest.pro
mingw32-make -f dlltest.mk.Release
if %errorlevel% neq 0 ( exit /b )

call easy.bat

del lib_entry.lib
del easy_win_*.obj

setlocal enabledelayedexpansion enableextensions
set LIST=
for %%x in (easy_win_*.c) do set LIST=!LIST! %%x
for %%x in (easy_win_*.cpp) do set LIST=!LIST! %%x
C:\dm\bin\dmc -c myclass.cpp %LIST%
if %errorlevel% neq 0 ( exit /b )

setlocal enabledelayedexpansion enableextensions
set LIST=
for %%x in (easy_win_*.obj) do set LIST=!LIST! %%x
C:\dm\bin\lib -c -n -p512 lib_entry.lib myclass.obj %LIST%
if %errorlevel% neq 0 ( exit /b )

del main.exe
C:\dm\bin\dmc -IC:/dm/stlport/stlport main.cpp lib_entry.lib
if %errorlevel% neq 0 ( exit /b )

:clean

if "%1" neq "keep" (
  del easy_win_*
  del *.obj
  del Makefile.*
)
if "%1" equ "clean" (
  rmdir /s /q .dub
  rmdir /s /q debug
  rmdir /s /q release
)