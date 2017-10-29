setlocal
emake-dmd build=release emake-qt.exe emake-qt.d emake_common.d
::start /w codeblocks --target=Release --build emake-qt.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    start codeblocks emake-qt.cbp
    exit /b )
set BASENAME=emake-gcc___
emake-qt.exe %BASENAME%.pro emake.cpp common.h
::qmake -o %BASENAME%.mk %BASENAME%.pro
::mingw32-make -f %BASENAME%.mk.Release
::copy release\%BASENAME%.exe .
endlocal