emake-dmd build app01.exe app01.d -I=dlangui.src/src -I=dlangui.src/3rdparty
if %errorlevel% neq 0 ( exit /b )
app01.exe