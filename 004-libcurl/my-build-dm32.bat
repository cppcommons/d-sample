setlocal
call my-prepare.bat
dub run --arch=x86 --build=release
endlocal
