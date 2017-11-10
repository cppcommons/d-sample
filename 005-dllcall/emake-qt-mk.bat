setlocal
emake-dmd build=release emake-qt.exe emake-qt.d emake_common.d
if %errorlevel% neq 0 ( exit /b )
set BASENAME=emake-gcc___
copy emake-qt.exe E:\opt\bin32\
copy emake-qt.exe C:\Users\Public\dev1\bin32
emake-qt.exe %BASENAME%.pro emake.cpp common.h
::qmake -o %BASENAME%.mk %BASENAME%.pro
::mingw32-make -f %BASENAME%.mk.Release
::copy release\%BASENAME%.exe .
endlocal