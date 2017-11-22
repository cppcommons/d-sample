del run32.exe
::cl -MT -GX run32w.cpp /link /out:run32-vc6.exe /subsystem:windows shell32.lib user32.lib
::if %errorlevel% neq 0 ( exit /b )
::cl -MT -GX -DCONSOLE_VERSION run32w.cpp /link /out:cmd32-vc6.exe /subsystem:console shell32.lib user32.lib
::if %errorlevel% neq 0 ( exit /b )

cl -MT -EHsc run32w.cpp /link /out:run32.exe /subsystem:windows shell32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
cl -MT -EHsc -DCONSOLE_VERSION run32w.cpp /link /out:cmd32.exe /subsystem:console shell32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )

g++ -o run32g.exe -Os run32w.cpp -static -mwindows
if %errorlevel% neq 0 ( exit /b )
g++ -o cmd32g.exe -Os -DCONSOLE_VERSION run32w.cpp -static
if %errorlevel% neq 0 ( exit /b )

run32.exe -nc np bb cc > ___tmp.txt
cat ___tmp.txt
run32.exe np@:RunMain bb cc
run32.exe np@:NotMain bb cc
cmd32.exe np@:RunMain bb cc
run32.exe -ac np@:RunMain bb cc
run32.exe -w 2000 np@:RunMain bb cc
