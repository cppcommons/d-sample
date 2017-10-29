setlocal
emake-dmd build=release emake-dmd.exe emake-dmd.d emake_common.d
if %errorlevel% neq 0 ( exit /b )
copy emake-dmd.exe E:\opt\bin32\
endlocal