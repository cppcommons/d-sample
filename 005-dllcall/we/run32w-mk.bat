del run32.exe
::cl -MD -GX run32w.cpp /link /out:run.exe /subsystem:windows shell32.lib user32.lib
cl -MT -GX run32w.cpp /link /out:run32.exe /subsystem:windows shell32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
run.exe np bb cc > ___tmp.txt
cat ___tmp.txt
run32.exe -c np,RunMain bb cc
run32.exe -c np,NotMain bb cc
