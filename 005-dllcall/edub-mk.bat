setlocal
emake-dmd edub.exe edub.d emake_common.d
start /w codeblocks --target=Release --build edub.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    start codeblocks edub.cbp
    exit /b )
echo Build Successful!
::edub.exe
::edub.exe apps.json build :app1
endlocal