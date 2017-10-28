setlocal
start /w codeblocks --target=Release --build edub.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    start codeblocks edub.cbp
    exit /b )
edub.exe
set BASENAME=apps
edub.exe %BASENAME%.json build
endlocal