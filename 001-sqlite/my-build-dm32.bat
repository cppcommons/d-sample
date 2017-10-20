setlocal
call my-prepare.bat
dub --arch=x86 --build=release
endlocal
