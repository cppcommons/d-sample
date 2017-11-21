cl -MD -GX run32w.cpp /link /out:run.exe /subsystem:windows shell32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
run.exe a b c > ___tmp.txt
cat ___tmp.txt
run.exe -c a b c
