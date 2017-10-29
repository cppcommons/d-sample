setlocal
::emake-dmd build=release libidl.dll -I../../d-lib idl.d ../../d-lib/pegged-dm32.lib
::if %errorlevel% neq 0 ( exit /b )
emake-dmd build=release idl.exe -I../../d-lib idl.d ../../d-lib/pegged-dm32.lib -- idl-test.txt A B C
if %errorlevel% neq 0 ( exit /b )
chcp 65001 &::utf-8
idl.exe idl-test.txt
endlocal