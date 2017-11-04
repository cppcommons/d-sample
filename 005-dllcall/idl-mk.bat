edub idl.exe build inc=../../d-lib idl.d ../../d-lib/pegged-dm32.lib --build=release --cleanup
if %errorlevel% neq 0 ( exit /b )
chcp 65001
idl.exe idl-test.txt
