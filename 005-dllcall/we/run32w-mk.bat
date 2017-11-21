del run32.exe
::cl -MD -GX run32w.cpp /link /out:run.exe /subsystem:windows shell32.lib user32.lib
::cl -MT -GX run32w.cpp /link /out:run32-vc6.exe /subsystem:windows shell32.lib user32.lib
::if %errorlevel% neq 0 ( exit /b )
::cl -MT -GX -DCONSOLE_VERSION run32w.cpp /link /out:cmd32-vc6.exe /subsystem:console shell32.lib user32.lib
::if %errorlevel% neq 0 ( exit /b )
g++ -o run32.exe run32w.cpp -static -mwindows
if %errorlevel% neq 0 ( exit /b )
g++ -o cmd32.exe -DCONSOLE_VERSION run32w.cpp -static
if %errorlevel% neq 0 ( exit /b )
run32.exe np bb cc > ___tmp.txt
cat ___tmp.txt
run32.exe -c np,RunMain bb cc
run32.exe -c np,NotMain bb cc
cmd32.exe -c np,RunMain bb cc
