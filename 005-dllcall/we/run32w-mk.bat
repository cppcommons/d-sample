cl -MD -GX run32w.cpp /link /out:run32w.exe /subsystem:windows shell32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
run32w.exe -nc a b c > ___tmp.txt
cat ___tmp.txt
run32w.exe a b c
