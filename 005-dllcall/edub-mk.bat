setlocal
emake-dmd build=release edub.exe edub.d emake_common.d
if %errorlevel% neq 0 ( exit /b )
endlocal