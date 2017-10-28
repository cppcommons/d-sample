setlocal
start /w codeblocks --target=Release --build emake-qt.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    exit /b )
emake-qt.exe
set BASENAME=___emake-gcc
emake-qt.exe %BASENAME%.pro emake.cpp common.h
qmake -o %BASENAME%.mk %BASENAME%.pro
mingw32-make -f %BASENAME%.mk.Release
endlocal