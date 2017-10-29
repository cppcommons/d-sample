setlocal
emake-dmd build=release emake-dmd.exe emake-dmd.d emake_common.d
::start /w codeblocks --target=Release --build emake-dmd.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    start codeblocks emake-dmd.cbp
    exit /b )
echo Build Successful!
endlocal