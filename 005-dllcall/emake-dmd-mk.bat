setlocal
emake-dmd emake-dmd.exe emake-dmd.d emake_common.d
start /w codeblocks --target=Release --build emake-dmd.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    start codeblocks emake-dmd.cbp
    exit /b )
echo Build Successful!
::emake-dmd.exe
::set BASENAME=emake-dmd-test___
::emake-dmd.exe %BASENAME%.exe emake-dmd.d emake_common.d
endlocal