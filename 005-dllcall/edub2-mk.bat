emake-dmd build=release edub2.exe edub2.d emake_common.d
if %errorlevel% neq 0 ( exit /b )
edub2 app1.dub.json