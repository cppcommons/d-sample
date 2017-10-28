setlocal
start /w codeblocks --target=Release --build emake-qt.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    start codeblocks emake-qt.cbp
    exit /b )
emake-qt.exe
set BASENAME=emake-gcc___
emake-qt.exe %BASENAME%.pro emake.cpp common.h
::qmake -o %BASENAME%.mk %BASENAME%.pro
::mingw32-make -f %BASENAME%.mk.Release
::copy release\%BASENAME%.exe .
endlocal