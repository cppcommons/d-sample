setlocal
call my-prepare.bat
dub test --coverage
endlocal
