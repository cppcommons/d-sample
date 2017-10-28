start /w codeblocks --target=Release --build emake-qt.cbp
if %errorlevel% neq 0 (
    echo Build Failed!
    exit /b )
emake-qt.exe
emake-qt.exe _emake-gcc.pro emake.cpp common.h
