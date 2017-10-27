setlocal
set PATH=
set PATH=%PATH%;%SystemRoot%\System32
path
call "C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/vcvarsall.bat" x86
echo on
cl /MT jscript.cpp
"C:\Qt\Qt5.9.2\5.9.2\msvc2015\bin\qmake.exe" E:\d-dev\d-sample\005-dllcall\main.pro -o main.mk -spec win32-msvc
nmake -f main.mk.Release
endlocal
