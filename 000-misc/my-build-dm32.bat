setlocal
call my-prepare.bat
dub build --arch=x86 --build=release
endlocal
