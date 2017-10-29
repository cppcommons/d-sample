setlocal
emake-dmd build=release idl.exe -I../../d-lib idl.d ../../d-lib/pegged-dm32.lib -- idl-test.txt A B C
::start /w codeblocks --target=Release --build idl.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    start codeblocks idl.cbp
    exit /b )
echo Build Successful!
chcp 65001 &::utf-8
idl.exe idl-test.txt
endlocal