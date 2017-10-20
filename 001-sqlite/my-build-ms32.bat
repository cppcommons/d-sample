setlocal
call my-prepare.bat
call "C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/vcvarsall.bat" x86
@echo on
dub build --arch=x86_mscoff --config=x86_mscoff --build=release
endlocal
