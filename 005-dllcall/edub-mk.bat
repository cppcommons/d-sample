setlocal
start /w codeblocks --target=Release --build edub.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    start codeblocks edub.cbp
    exit /b )
edub.exe
edub.exe apps.json build :app1
endlocal